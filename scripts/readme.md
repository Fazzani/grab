# missing channels programs

```json
// epg index mapping

PUT epg
{
  "mappings": {
    "channels": {
      "properties": {
        "tv": {
          "type": "nested",
          "properties": {
            "channel": {
              "type": "nested",
              "properties": {
                "active": {
                  "type": "boolean"
                },
                "country": {
                  "type": "text",
                  "fields": {
                    "keyword": {
                      "type": "keyword",
                      "ignore_above": 256
                    }
                  }
                },
                "display-name": {
                  "type": "nested",
                  "properties": {
                    "$t": {
                      "type": "text",
                      "fields": {
                        "keyword": {
                          "type": "keyword",
                          "ignore_above": 256
                        }
                      }
                    },
                    "lang": {
                      "type": "text",
                      "fields": {
                        "keyword": {
                          "type": "keyword",
                          "ignore_above": 256
                        }
                      }
                    }
                  }
                },
                "icon": {
                  "properties": {
                    "src": {
                      "type": "text",
                      "fields": {
                        "keyword": {
                          "type": "keyword",
                          "ignore_above": 256
                        }
                      }
                    }
                  }
                },
                "id": {
                  "type": "text",
                  "fields": {
                    "keyword": {
                      "type": "keyword",
                      "ignore_above": 256
                    }
                  }
                },
                "url": {
                  "type": "text",
                  "fields": {
                    "keyword": {
                      "type": "keyword",
                      "ignore_above": 256
                    }
                  }
                }
              }
            },
            "generator-info-name": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            },
            "generator-info-url": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            }
          }
        }
      }
    }
  }
}


```

## Active EPG Channels Query

```json
GET epg/_search
{
  "query": {
    "nested": {
      "path": "tv.channel",
      "query": {
        "bool": {
          "must": [
            {
              "match": {
                "tv.channel.active": true
              }
            }
          ]
        }
      },
      "inner_hits": {
        "highlight": {
          "fields": {
            "tv.channel": {}
          }
        }
      }
    }
  }
}
```