{% macro log_bytes_processed() %}
  {% if execute %}
    {% set names = {} %}
    {% for result in results %}
      {% set job_id = result.adapter_response.get('job_id') %}
      {% if job_id %}{% do names.update({job_id: result.node.name}) %}{% endif %}
    {% endfor %}

    {% if names | length > 0 %}
      {% set first = results[0].adapter_response %}
      {% set job_list = names.keys() | map('tojson') | join(', ') %}
      {% set sql %}
        select job_id, total_bytes_processed
        from `{{ first.get('project_id') or target.database }}`.`region-{{ first.get('location') or target.location }}`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
        where creation_time > timestamp_sub(current_timestamp(), interval 1 day)
          and job_id in ({{ job_list }})
      {% endset %}
      {% set rows = run_query(sql) %}

      {% set items = [] %}
      {% set ns = namespace(total=0, width=5) %}
      {% for row in rows.rows %}
        {% set name = names[row[0]] %}
        {% set b = row[1] or 0 %}
        {% do items.append({'name': name, 'bytes': b}) %}
        {% set ns.total = ns.total + b %}
        {% if name | length > ns.width %}{% set ns.width = name | length %}{% endif %}
      {% endfor %}

      {% set line = '-' * (ns.width + 12) %}
      {{ log(line, info=True) }}
      {{ log('Model' ~ ' ' * (ns.width - 5) ~ '  ' ~ ' ' * 8 ~ 'MB', info=True) }}
      {{ log(line, info=True) }}
      {% for item in items | sort(attribute='bytes', reverse=true) %}
        {% set mb = '%.2f' | format(item.bytes / 1024 / 1024) %}
        {{ log(item.name ~ ' ' * (ns.width - item.name | length) ~ '  ' ~ ' ' * (10 - mb | length) ~ mb, info=True) }}
      {% endfor %}
      {{ log(line, info=True) }}
      {% set total = '%.2f' | format(ns.total / 1024 / 1024) %}
      {{ log('TOTAL' ~ ' ' * (ns.width - 5) ~ '  ' ~ ' ' * (10 - total | length) ~ total, info=True) }}
    {% endif %}
  {% endif %}
{% endmacro %}