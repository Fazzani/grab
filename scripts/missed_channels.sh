#!/usr/bin/env python3

from jinja2 import Template
import csv
import os

data: str = '''
# Missed Channels

![Channel count](https://img.shields.io/static/v1?style=for-the-badge&label=channel%20count&message={{channel_count}}&color=red&cacheSeconds=3600)


|Icon|Channel|Site|
|:----|:---:|:---:|
{% for ch in channels -%}
|<img src="{{ch.icon}}" width="100" height="50">|{{ ch.id }}|{{ ch.site }}|
{% endfor %}
'''

tpl = Template(data)
with open(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "out", "epg_stats.csv"))) as f:
    channels = list(csv.DictReader(f))
    missed_channels = list(filter(lambda x: x['missed_percent'] == '100.0', channels))
    # completeness = "{0:3.2f}%".format(100 - (missed_count / len(channels) * 100))
    output = tpl.render(channels=missed_channels,
                        channel_count=len(missed_channels))
    with open(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "out", 'missed_channels.md')), 'w') as stream:
        stream.write(output)
