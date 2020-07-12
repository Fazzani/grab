#!/usr/bin/env python3

from jinja2 import Template
import csv
import os

data: str = '''
# Daily EPG
[![Build Status](https://travis-ci.org/Fazzani/grab.svg?branch=master)](https://travis-ci.org/Fazzani/grab)
![CI](https://github.com/Fazzani/grab/workflows/CI/badge.svg)

![Channel count](https://img.shields.io/static/v1?style=for-the-badge&label=channel%20count&message={{channel_count}}&color=9cf&cacheSeconds=3600)
![Completeness](https://img.shields.io/static/v1?style=for-the-badge&label=Completeness&message={{completeness}}&color=yellow&cacheSeconds=3600)

## channels list

- [All channels link](https://github.com/Fazzani/grab/blob/master/merge.tar.gz?raw=true)
- [Missed channels list](out/missed_channels.md)


|Icon|Channel|Site|
|:----|:---:|:---:|
{% for ch in channels -%}
{% if ch.missed == 'True' -%}
|<img src="{{ch.icon}}" width="100" height="50">|~~{{ ch.id }}~~|{{ ch.site }}|
{% else -%}
|<img src="{{ch.icon}}" width="100" height="50">|{{ ch.id }}|{{ ch.site }}|
{% endif -%}
{% endfor %}
'''

tpl = Template(data)
with open(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "out", "epg.csv"))) as f:
    channels = list(csv.DictReader(f))
    missed_count = len(list(filter(lambda x: x['missed'] == 'True', channels)))
    completeness = "{0:3.2f}%".format(100 - (missed_count / len(channels) * 100))
    output = tpl.render(channels=channels,
                        completeness=completeness, channel_count=len(channels))
    with open(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", 'readme.md')), 'w') as readme:
        readme.write(output)
