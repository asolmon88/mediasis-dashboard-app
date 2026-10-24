create or replace function mediasis.get_receipt_print_data_for_dashboard(
  p_order_id uuid,
  p_business_location_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_business_uid uuid;
  v_domain text;
  v_receipt jsonb;
  v_cashback jsonb;
  v_market jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('success', false, 'message', 'No autorizado');
  end if;

  select bl.business_uid
    into v_business_uid
  from mediasis.business_location bl
  where bl.business_location_id = p_business_location_id
    and bl.business_uid = auth.uid();

  if v_business_uid is null then
    return jsonb_build_object('success', false, 'message', 'Ubicacion no accesible');
  end if;

  if not exists (
    select 1
    from mediasis.orders o
    where o.order_id = p_order_id
      and o.business_location_id = p_business_location_id
      and o.deleted_at is null
  ) then
    return jsonb_build_object('success', false, 'message', 'Orden no encontrada');
  end if;

  select bd.domain
    into v_domain
  from mediasis.business_domain bd
  where bd.business_uid = v_business_uid
    and bd.type = 'order_app'
  order by bd.created_at desc, bd.business_domain_id desc
  limit 1;

  if nullif(trim(v_domain), '') is null then
    return jsonb_build_object('success', false, 'message', 'Dominio de pedidos no configurado');
  end if;

  select to_jsonb(m) into v_market
  from mediasis.business_market_settings m where m.business_id = v_business_uid;
  if v_market is null then
    return jsonb_build_object('success', false, 'code', 'MARKET_SETTINGS_MISSING',
      'message', 'Configuracion regional no disponible');
  end if;
  v_receipt := mediasis.get_receipt_data(v_domain, p_order_id);
  if coalesce((v_receipt ->> 'success')::boolean, false) then
    v_receipt := jsonb_set(v_receipt, '{data,market}', v_market);
  end if;
  if not coalesce((v_receipt ->> 'success')::boolean, false)
      or v_receipt -> 'data' is null then
    return coalesce(
      v_receipt,
      jsonb_build_object('success', false, 'message', 'No se pudo cargar el recibo')
    );
  end if;

  v_cashback := mediasis.get_order_cashback_summary_service(p_order_id, v_domain);
  if coalesce((v_cashback ->> 'success')::boolean, false) then
    v_receipt := jsonb_set(
      v_receipt,
      '{data,order}',
      (v_receipt #> '{data,order}') || jsonb_build_object(
        'cashback_percentage', v_cashback #> '{data,percentage}',
        'cashback_eligible_products_minor', v_cashback #> '{data,eligible_products_minor}',
        'cashback_earned_minor', v_cashback #> '{data,earned_minor}',
        'cashback_redeemed_minor', v_cashback #> '{data,redeemed_minor}',
        'cashback_earning_status', v_cashback #> '{data,earning_status}',
        'cashback_redemption_status', v_cashback #> '{data,redemption_status}'
      )
    );
  end if;

  return mediasis.sanitize_receipt_print_json(v_receipt);
exception when others then
  return jsonb_build_object('success', false, 'message', SQLERRM);
end;
$$;

revoke all on function mediasis.get_receipt_print_data_for_dashboard(uuid, uuid)
  from public, anon;
grant execute on function mediasis.get_receipt_print_data_for_dashboard(uuid, uuid)
  to authenticated;
