# Merge xmltv

The scheduled workflow downloads its sources from `EPG_URLS` (semicolon-separated
URLs). Downloads and gzip extraction must succeed before merging. If a source is
malformed or the XMLTV merge fails, the workflow stops without publishing new
archives; inspect the failing source and retry the workflow after it is fixed.

ENV GITHUB_API_TOKEN required

```bash
sudo docker run -it -v "${PWD}:/work" -e GITHUB_API_TOKEN=${GITHUB_API_TOKEN} synker/xmltv_merge:0.0.5 dos2unix docker/merge.sh && docker/merge.sh *.xmltv
# creating and pushing docker image
docker build -t synker/xmltv_merge:latest -t synker/xmltv_merge:0.0.5 .
docker push
```

Elasticsearch missing channel mapping index

```json
PUT missingepgchannels
{
  "mappings": {
    "_doc": {
      "properties": {
        "report": {
          "type": "nested",
          "properties": {
            "_id": {
              "type": "text"
            },
            "update_date": {
              "type": "date",
              "format": "yyyy/MM/dd HH:mm:ss"
            },
            "sources": {
              "type": "nested",
              "properties": {
                "filename": {
                  "type": "text"
                },
                "total": {
                  "type": "long"
                },
                "missed": {
                  "type": "long"
                },
                "missedlist": {
                  "type": "text"
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