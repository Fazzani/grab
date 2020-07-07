#!/usr/bin/env python3

from jinja2 import Template
import csv
import os

data: str = '''
# Daily EPG
[![Build Status](https://travis-ci.org/Fazzani/grab.svg?branch=master)](https://travis-ci.org/Fazzani/grab)

![CI](https://github.com/Fazzani/grab/workflows/CI/badge.svg)

## channels list

Channel count: **{{channel_count}}**
Completness: **{{completness}}**

[All channels link](https://github.com/Fazzani/grab/blob/master/merge.tar.gz?raw=true)



|Icon|Channel|Site|
|:----|:---:|:---:|
{% for ch in channels -%}
{% if ch.missed == 'True' -%}
|<img src="{{ch.icon}}" width="50" height="50">|~~{{ ch.id }}~~|{{ ch.site }}|
{% else -%}
|<img src="{{ch.icon}}" width="50" height="50">|{{ ch.id }}|{{ ch.site }}|
{% endif -%}
{% endfor %}
'''

tpl = Template(data)
with open(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "out", "epg.csv"))) as f:
    channels = list(csv.DictReader(f))
    missed_count = len(list(filter(lambda x: x['missed'] == 'True', channels)))
    completness = "{0:3.2f}%".format(100 - (missed_count / len(channels) * 100))
    output = tpl.render(channels=channels,
                        completness=completness, channel_count=len(channels))
    with open(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", 'readme.md')), 'w') as readme:
        readme.write(output)
