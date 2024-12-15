#!/usr/bin/env python3

from jinja2 import Template
import csv
import os

data: str = '''
# Daily EPG (Electronic Program Guide)

[![grab](https://github.com/Fazzani/grab/actions/workflows/grab.yml/badge.svg)](https://github.com/Fazzani/grab/actions/workflows/grab.yml)

![Channel count](https://img.shields.io/static/v1?style=for-the-badge&label=channel%20count&message={{channel_count}}&color=9cf&cacheSeconds=3600)
![Completeness](https://img.shields.io/static/v1?style=for-the-badge&label=Completeness&message={{completeness}}&color=yellow&cacheSeconds=3600)

## Available epg

- [EPG (gz archive)](https://github.com/Fazzani/grab/blob/master/merge.xml.gz?raw=true)
- [EPG (zip archive)](https://github.com/Fazzani/grab/blob/master/merge.zip?raw=true)

## Channels list

- [Missed channels list](out/missed_channels.md)

|Icon|Channel|Country|Site|
|:---|:-----:|:-----:|:--:|
{% for ch in channels -%}
{% if ch.missed == 'True' -%}
|<img src="{{ch.icon}}" width="100" height="50">|~~{{ ch.id }}~~|{{ ch.country }}|{{ ch.site }}|
{% else -%}
|<img src="{{ch.icon}}" width="100" height="50">|{{ ch.id }}|{{ ch.country }}|{{ ch.site }}|
{% endif -%}
{% endfor %}
'''

tpl = Template(data)
with open(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "out", "epg.csv")), encoding="utf8") as f:
    channels = list(csv.DictReader(f))
    missed_count = len(list(filter(lambda x: x['missed'] == 'True', channels)))
    completeness = "{0:3.2f}%".format(100 - (missed_count / len(channels) * 100))
    output = tpl.render(channels=channels,
                        completeness=completeness, channel_count=len(channels))
    with open(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", 'readme.md')), 'w', encoding="utf8") as readme:
        readme.write(output)
