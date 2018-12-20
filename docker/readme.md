# Merge xmltv

ENV GITHUB_API_TOKEN required

```bash
sudo docker run -it -v "${PWD}:/work" -e GITHUB_API_TOKEN=${GITHUB_API_TOKEN} synker/xmltv_merge:0.0.3 dos2unix docker/merge.sh && docker/merge.sh *.xmltv
# creating and pushing docker image
docker build -t synker/xmltv_merge:latest -t synker/xmltv_merge:0.0.4 .
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