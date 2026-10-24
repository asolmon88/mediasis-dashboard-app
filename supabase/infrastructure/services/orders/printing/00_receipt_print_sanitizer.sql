create or replace function mediasis.sanitize_receipt_print_json(p_value jsonb)
returns jsonb
language plpgsql
immutable
strict
set search_path = ''
as $$
declare
  v_text text;
  v_result jsonb;
begin
  case jsonb_typeof(p_value)
    when 'object' then
      select coalesce(
        jsonb_object_agg(entry.key, mediasis.sanitize_receipt_print_json(entry.value)),
        '{}'::jsonb
      )
      into v_result
      from jsonb_each(p_value) as entry;
      return v_result;
    when 'array' then
      select coalesce(
        jsonb_agg(mediasis.sanitize_receipt_print_json(item.value) order by item.ordinality),
        '[]'::jsonb
      )
      into v_result
      from jsonb_array_elements(p_value) with ordinality as item(value, ordinality);
      return v_result;
    when 'string' then
      v_text := p_value #>> '{}';
      v_text := translate(
        v_text,
        'áéíóúÁÉÍÓÚñÑüÜ“”–—…',
        'aeiouAEIOUnNuU""--.'
      );
      v_text := replace(replace(v_text, '‘', chr(39)), '’', chr(39));
      v_text := regexp_replace(v_text, '[^ -~]', ' ', 'g');
      return to_jsonb(v_text);
    else
      return p_value;
  end case;
end;
$$;

revoke all on function mediasis.sanitize_receipt_print_json(jsonb)
  from public, anon, authenticated;
grant execute on function mediasis.sanitize_receipt_print_json(jsonb)
  to service_role;
