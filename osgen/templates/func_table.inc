os_func_table:
{%- for call in os_calls %}
    .WORD {{ call.implementation }}
{%- endfor %}

