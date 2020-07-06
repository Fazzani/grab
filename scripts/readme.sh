#!/usr/bin/env python3

from jinja2 import Template
import csv
import os

data: str = '''
# Daily EPG
[![Build Status](https://travis-ci.org/Fazzani/grab.svg?branch=master)](https://travis-ci.org/Fazzani/grab)

![CI](https://github.com/Fazzani/grab/workflows/CI/badge.svg)

## channels list
[All channels link](https://github.com/Fazzani/grab/blob/master/merge.tar.gz?raw=true)



|Icon|Channel|Site|
|:----|:---:|:---:|
{% for ch in channels -%}
    |<img src="{{ch.icon}}" width="50" height="50">|{{ ch.id }}|{{ ch.site }}|
{% endfor %}
'''

tpl = Template(data)
with open(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "out", "epg.csv"))) as f:
    output = tpl.render(channels=list(csv.DictReader(f)))
    with open(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", 'readme.md')), 'w') as readme:
        readme.write(output)
