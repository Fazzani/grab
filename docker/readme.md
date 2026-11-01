# Merge xmltv

The scheduled workflow downloads its sources from `EPG_URLS` (URLs separated by
semicolons, spaces, or newlines) into a fresh temporary directory. Unavailable or invalid sources are
reported as warnings and skipped, so the published guide can be incomplete.
If no source is usable or the merged guide has no programmes, the workflow
fails without publishing new archives. For local runs, set `EPG_TMP_DIR` to
an empty directory before running `build.sh --download` and `--merge`.

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
