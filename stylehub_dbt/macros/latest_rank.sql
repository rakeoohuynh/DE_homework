{% macro latest_rank(key='id') %}
row_number() over (
    partition by {{ key }}
    order by updated_at desc, _airbyte_extracted_at desc
)
{% endmacro %}
