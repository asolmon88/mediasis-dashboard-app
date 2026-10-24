-- Used by PushNotificationService, PushNotificationsCubit, and notify-new-order.

create table if not exists mediasis.new_order_push_subscriptions (
  subscription_id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  business_location_id uuid not null
    references mediasis.business_location(business_location_id) on delete cascade,
  platform text not null check (platform in ('android', 'ios')),
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists new_order_push_subscriptions_location_idx
  on mediasis.new_order_push_subscriptions (business_location_id)
  where enabled;

alter table mediasis.new_order_push_subscriptions enable row level security;
revoke all on table mediasis.new_order_push_subscriptions from anon, authenticated;
grant select, insert, update, delete
  on table mediasis.new_order_push_subscriptions to service_role;

create table if not exists mediasis.new_order_push_deliveries (
  order_id uuid primary key references mediasis.orders(order_id) on delete cascade,
  business_location_id uuid not null
    references mediasis.business_location(business_location_id) on delete cascade,
  status text not null check (status in ('claimed', 'sent', 'no_subscribers')),
  attempt_count integer not null default 1,
  onesignal_message_ids jsonb not null default '[]'::jsonb,
  claimed_at timestamptz not null default now(),
  completed_at timestamptz,
  last_error text
);

alter table mediasis.new_order_push_deliveries enable row level security;
revoke all on table mediasis.new_order_push_deliveries from anon, authenticated;
grant select, insert, update, delete
  on table mediasis.new_order_push_deliveries to service_role;

create or replace function mediasis.register_new_order_push_subscription(
  p_subscription_id text,
  p_business_location_id uuid,
  p_platform text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_subscription_id text := nullif(trim(p_subscription_id), '');
  v_platform text := lower(trim(p_platform));
  v_updated_count integer;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if v_subscription_id is null then
    raise exception 'Subscription ID is required' using errcode = '22023';
  end if;

  if v_platform not in ('android', 'ios') then
    raise exception 'Platform must be android or ios' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from mediasis.business_location bl
    where bl.business_location_id = p_business_location_id
      and bl.business_uid = v_user_id
  ) then
    raise exception 'Location is not available to this user'
      using errcode = '42501';
  end if;

  insert into mediasis.new_order_push_subscriptions (
    subscription_id,
    user_id,
    business_location_id,
    platform,
    enabled,
    updated_at
  )
  values (
    v_subscription_id,
    v_user_id,
    p_business_location_id,
    v_platform,
    true,
    now()
  )
  on conflict (subscription_id) do update
  set user_id = excluded.user_id,
      business_location_id = excluded.business_location_id,
      platform = excluded.platform,
      enabled = true,
      updated_at = now()
  where mediasis.new_order_push_subscriptions.user_id = v_user_id
    or not mediasis.new_order_push_subscriptions.enabled;

  get diagnostics v_updated_count = row_count;

  if v_updated_count = 0 then
    raise exception 'Subscription belongs to another active user'
      using errcode = '42501';
  end if;

  return jsonb_build_object('success', true);
end;
$$;

create or replace function mediasis.disable_new_order_push_subscription(
  p_subscription_id text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_updated_count integer;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  update mediasis.new_order_push_subscriptions
  set enabled = false,
      updated_at = now()
  where subscription_id = nullif(trim(p_subscription_id), '')
    and user_id = v_user_id;

  get diagnostics v_updated_count = row_count;

  return jsonb_build_object(
    'success', true,
    'disabled', v_updated_count > 0
  );
end;
$$;

create or replace function mediasis.claim_new_order_push_delivery(
  p_order_id uuid,
  p_business_location_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_claimed_order_id uuid;
begin
  insert into mediasis.new_order_push_deliveries (
    order_id,
    business_location_id,
    status,
    attempt_count,
    claimed_at,
    completed_at,
    last_error
  )
  values (
    p_order_id,
    p_business_location_id,
    'claimed',
    1,
    now(),
    null,
    null
  )
  on conflict (order_id) do update
  set business_location_id = excluded.business_location_id,
      status = 'claimed',
      attempt_count = mediasis.new_order_push_deliveries.attempt_count + 1,
      claimed_at = now(),
      completed_at = null,
      last_error = null
  where mediasis.new_order_push_deliveries.status = 'claimed'
    and mediasis.new_order_push_deliveries.claimed_at < now() - interval '10 minutes'
  returning order_id into v_claimed_order_id;

  return v_claimed_order_id is not null;
end;
$$;

create or replace function mediasis.complete_new_order_push_delivery(
  p_order_id uuid,
  p_status text,
  p_onesignal_message_ids jsonb default '[]'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_status not in ('sent', 'no_subscribers') then
    raise exception 'Invalid completion status' using errcode = '22023';
  end if;

  update mediasis.new_order_push_deliveries
  set status = p_status,
      onesignal_message_ids = coalesce(p_onesignal_message_ids, '[]'::jsonb),
      completed_at = now(),
      last_error = null
  where order_id = p_order_id
    and status = 'claimed';
end;
$$;

create or replace function mediasis.release_new_order_push_delivery(
  p_order_id uuid,
  p_error text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from mediasis.new_order_push_deliveries
  where order_id = p_order_id
    and status = 'claimed';

  raise log 'Released new-order push claim for order %, error: %',
    p_order_id,
    left(coalesce(p_error, 'Unknown error'), 500);
end;
$$;

revoke all on function mediasis.register_new_order_push_subscription(text, uuid, text)
  from public, anon;
revoke all on function mediasis.disable_new_order_push_subscription(text)
  from public, anon;
revoke all on function mediasis.claim_new_order_push_delivery(uuid, uuid)
  from public, anon, authenticated;
revoke all on function mediasis.complete_new_order_push_delivery(uuid, text, jsonb)
  from public, anon, authenticated;
revoke all on function mediasis.release_new_order_push_delivery(uuid, text)
  from public, anon, authenticated;

grant execute on function mediasis.register_new_order_push_subscription(text, uuid, text)
  to authenticated;
grant execute on function mediasis.disable_new_order_push_subscription(text)
  to authenticated;
grant execute on function mediasis.claim_new_order_push_delivery(uuid, uuid)
  to service_role;
grant execute on function mediasis.complete_new_order_push_delivery(uuid, text, jsonb)
  to service_role;
grant execute on function mediasis.release_new_order_push_delivery(uuid, text)
  to service_role;
