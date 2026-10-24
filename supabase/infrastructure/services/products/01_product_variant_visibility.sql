-- Used by SupabaseProductsService and the dashboard product API routes.

alter table mediasis.product_variant
  add column if not exists visibility boolean not null default true;

create or replace function mediasis.get_product_variants_for_app(
  p_product_id uuid,
  p_business_location_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = mediasis, public
as $$
declare
  v_business_id uuid;
begin
  select bl.business_uid
  into v_business_id
  from mediasis.business_location bl
  where bl.business_location_id = p_business_location_id;

  if v_business_id is null or v_business_id <> auth.uid() then
    return jsonb_build_object(
      'success', false,
      'message', 'Not allowed for this business location'
    );
  end if;

  if not exists (
    select 1
    from mediasis.product p
    where p.product_id = p_product_id
      and p.business = auth.uid()
  ) then
    return jsonb_build_object(
      'success', false,
      'message', 'Product not found or not allowed'
    );
  end if;

  return jsonb_build_object(
    'success', true,
    'data', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'product_variant_id', pv.product_variant_id,
            'name', pv.name,
            'price', pv.price,
            'visible_at_location',
              coalesce(pv.visibility, true)
              and (
                not exists (
                  select 1
                  from mediasis.product_variant_location pvl_any
                  where pvl_any.product_variant_id = pv.product_variant_id
                )
                or exists (
                  select 1
                  from mediasis.product_variant_location pvl_match
                  where pvl_match.product_variant_id = pv.product_variant_id
                    and pvl_match.business_location_id = p_business_location_id
                )
              )
          )
          order by pv.created_at, pv.product_variant_id
        )
        from mediasis.product_variant pv
        where pv.product_id = p_product_id
          and coalesce(pv.is_default, false) = false
      ),
      '[]'::jsonb
    )
  );

exception when others then
  return jsonb_build_object(
    'success', false,
    'message', sqlerrm
  );
end;
$$;

create or replace function mediasis.set_product_variant_visibility_at_location(
  p_product_variant_id uuid,
  p_business_location_id uuid,
  p_visible boolean
)
returns jsonb
language plpgsql
security definer
set search_path = mediasis, public
as $$
declare
  v_business_id uuid;
  v_product_id uuid;
  v_variant_visible boolean;
  v_currently_visible boolean;
  v_has_scope_rows boolean;
  v_total_business_locations integer;
  v_scope_rows_count integer;
  v_visible_variants_count integer;
  v_product_result jsonb;
begin
  select bl.business_uid
  into v_business_id
  from mediasis.business_location bl
  where bl.business_location_id = p_business_location_id;

  if v_business_id is null or v_business_id <> auth.uid() then
    return jsonb_build_object(
      'success', false,
      'message', 'Not allowed for this business location'
    );
  end if;

  select pv.product_id, coalesce(pv.visibility, true)
  into v_product_id, v_variant_visible
  from mediasis.product_variant pv
  join mediasis.product p on p.product_id = pv.product_id
  where pv.product_variant_id = p_product_variant_id
    and coalesce(pv.is_default, false) = false
    and p.business = auth.uid()
  for update of pv;

  if v_product_id is null then
    return jsonb_build_object(
      'success', false,
      'message', 'Variant not found or not allowed'
    );
  end if;

  -- Serialize visibility changes for every selectable variant in this product.
  perform 1
  from mediasis.product_variant pv
  where pv.product_id = v_product_id
    and coalesce(pv.is_default, false) = false
  order by pv.product_variant_id
  for update;

  select count(*)
  into v_total_business_locations
  from mediasis.business_location bl
  where bl.business_uid = auth.uid();

  select exists (
    select 1
    from mediasis.product_variant_location pvl
    where pvl.product_variant_id = p_product_variant_id
  )
  into v_has_scope_rows;

  v_currently_visible := v_variant_visible and (
    not v_has_scope_rows
    or exists (
      select 1
      from mediasis.product_variant_location pvl
      where pvl.product_variant_id = p_product_variant_id
        and pvl.business_location_id = p_business_location_id
    )
  );

  if v_currently_visible = p_visible then
    return jsonb_build_object(
      'success', true,
      'data', jsonb_build_object(
        'product_id', v_product_id,
        'product_variant_id', p_product_variant_id,
        'visible_at_location', v_currently_visible,
        'product_hidden', false
      )
    );
  end if;

  if p_visible = false then
    select count(*)
    into v_visible_variants_count
    from mediasis.product_variant pv
    where pv.product_id = v_product_id
      and coalesce(pv.is_default, false) = false
      and coalesce(pv.visibility, true)
      and (
        not exists (
          select 1
          from mediasis.product_variant_location pvl_any
          where pvl_any.product_variant_id = pv.product_variant_id
        )
        or exists (
          select 1
          from mediasis.product_variant_location pvl_match
          where pvl_match.product_variant_id = pv.product_variant_id
            and pvl_match.business_location_id = p_business_location_id
        )
      );

    if v_visible_variants_count <= 1 then
      v_product_result := mediasis.hide_product_at_location(
        p_business_location_id,
        v_product_id
      );

      if coalesce((v_product_result ->> 'success')::boolean, false) = false then
        return v_product_result;
      end if;

      return jsonb_build_object(
        'success', true,
        'message', 'Product hidden because it must keep one available variant',
        'data', jsonb_build_object(
          'product_id', v_product_id,
          'product_variant_id', p_product_variant_id,
          'visible_at_location', true,
          'product_hidden', true
        )
      );
    end if;

    if not v_has_scope_rows then
      if v_total_business_locations <= 1 then
        update mediasis.product_variant
        set visibility = false
        where product_variant_id = p_product_variant_id;
      else
        insert into mediasis.product_variant_location (
          business_location_id,
          product_variant_id
        )
        select
          bl.business_location_id,
          p_product_variant_id
        from mediasis.business_location bl
        where bl.business_uid = auth.uid()
          and bl.business_location_id <> p_business_location_id
        on conflict (product_variant_id, business_location_id) do nothing;
      end if;
    else
      delete from mediasis.product_variant_location pvl
      where pvl.product_variant_id = p_product_variant_id
        and pvl.business_location_id = p_business_location_id;

      select count(*)
      into v_scope_rows_count
      from mediasis.product_variant_location pvl
      where pvl.product_variant_id = p_product_variant_id;

      if v_scope_rows_count = 0 then
        update mediasis.product_variant
        set visibility = false
        where product_variant_id = p_product_variant_id;
      end if;
    end if;
  else
    if v_variant_visible = false then
      update mediasis.product_variant
      set visibility = true
      where product_variant_id = p_product_variant_id;

      delete from mediasis.product_variant_location pvl
      where pvl.product_variant_id = p_product_variant_id;

      if v_total_business_locations > 1 then
        insert into mediasis.product_variant_location (
          business_location_id,
          product_variant_id
        )
        values (p_business_location_id, p_product_variant_id)
        on conflict (product_variant_id, business_location_id) do nothing;
      end if;
    elsif v_has_scope_rows then
      insert into mediasis.product_variant_location (
        business_location_id,
        product_variant_id
      )
      values (p_business_location_id, p_product_variant_id)
      on conflict (product_variant_id, business_location_id) do nothing;

      select count(*)
      into v_scope_rows_count
      from mediasis.product_variant_location pvl
      join mediasis.business_location bl
        on bl.business_location_id = pvl.business_location_id
      where pvl.product_variant_id = p_product_variant_id
        and bl.business_uid = auth.uid();

      if v_scope_rows_count >= v_total_business_locations then
        delete from mediasis.product_variant_location pvl
        where pvl.product_variant_id = p_product_variant_id;
      end if;
    end if;
  end if;

  return jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'product_id', v_product_id,
      'product_variant_id', p_product_variant_id,
      'visible_at_location', p_visible,
      'product_hidden', false
    )
  );

exception when others then
  return jsonb_build_object(
    'success', false,
    'message', sqlerrm
  );
end;
$$;

revoke all on function mediasis.get_product_variants_for_app(uuid, uuid) from public, anon;
revoke all on function mediasis.set_product_variant_visibility_at_location(uuid, uuid, boolean) from public, anon;

grant execute on function mediasis.get_product_variants_for_app(uuid, uuid) to authenticated, service_role;
grant execute on function mediasis.set_product_variant_visibility_at_location(uuid, uuid, boolean) to authenticated, service_role;
