{#-
    Extract date based partition keys from a date string.

    Args:
      partition_dt_str(str): string containing the target date
      str_format (str): Format string for the date value.  (Defaults to 'YYYY-MM-DD'.)

    Returns:
        tuple: year(YYYY), month(MM) and day(DD) values from the date string with leading 0 padding.
-#}

{% macro partition_date_keys(partition_dt_str, str_format='%Y-%m-%d') %}
    -- batch_dt_str == {{ batch_dt_str }}
    
    {%- set partition_dt_obj = modules.datetime.datetime.strptime(partition_dt_str|string, str_format) -%}
    {%- set p_year = partition_dt_obj.strftime('%Y') -%}
    {%- set p_month = partition_dt_obj.strftime('%m') -%}
    {%- set p_day = partition_dt_obj.strftime('%d') -%}
    
    {{ return((p_year, p_month, p_day)) }}
{% endmacro %}