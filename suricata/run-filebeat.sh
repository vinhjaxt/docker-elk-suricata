#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

HOST_NAME="filebeat-suricata"
SURICATA_HOST_NAME="suricata"
FILEBEAT_INDEX_NAME="suricata"
ELK_VERSION="$(docker exec -it docker-elk_elasticsearch_1 elasticsearch --version | cut -d ',' -f 1 | cut -d ' ' -f 2)"

docker container inspect "${HOST_NAME}" >/dev/null 2>&1
if [ $? -eq 0 ]; then
  docker stop "${HOST_NAME}"
  docker rm "${HOST_NAME}"
fi

# curl -X POST "localhost:9200/_ilm/stop?pretty"

docker run --rm --network=docker-elk_elk \
  -v "${DIR}/${SURICATA_HOST_NAME}/logs":/var/log/suricata:ro \
  -v "${DIR}/filebeat.suricata.yml":/usr/share/filebeat/modules.d/suricata.yml:ro \
  -v "${DIR}/filebeat.docker.yml:/usr/share/filebeat/filebeat.yml:ro" \
  \
  "docker.elastic.co/beats/filebeat:${ELK_VERSION}" \
  setup

# Create Index: http://127.0.0.1:5601/app/management/kibana/indexPatterns
# docker run --rm --network=docker-elk_elk alpine:latest sh -c 'apk add --no-cache curl && curl -X POST "http://kibana:5601/api/index_patterns/index_pattern" -H "kbn-xsrf: true" -H "Content-Type: application/json" -d'\''{"index_pattern": {"title": "filebeat-suricata-*","timeFieldName":"@timestamp"}}'\'

docker run -d --restart=unless-stopped --name "${HOST_NAME}" --hostname "${HOST_NAME}" \
  --network=docker-elk_elk \
  -v "${DIR}/${SURICATA_HOST_NAME}/logs":/var/log/suricata:ro \
  -v "${DIR}/filebeat.suricata.yml":/usr/share/filebeat/modules.d/suricata.yml:ro \
  -v "${DIR}/filebeat.docker.yml:/usr/share/filebeat/filebeat.yml:ro" \
  \
  "docker.elastic.co/beats/filebeat:${ELK_VERSION}" filebeat -e -strict.perms=false