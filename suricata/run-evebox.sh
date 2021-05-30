#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

HOST_NAME="evebox"
SURICATA_HOST_NAME="suricata"

docker container inspect "${HOST_NAME}" >/dev/null 2>&1
if [ $? -eq 0 ]; then
  docker stop "${HOST_NAME}"
  docker rm "${HOST_NAME}"
fi

docker run -d --restart=unless-stopped --name "${HOST_NAME}" --hostname "${HOST_NAME}" \
  -p 5636:5636 \
  --network=docker-elk_elk \
  -v "${DIR}/${SURICATA_HOST_NAME}/logs":/var/log/suricata:ro \
  jasonish/evebox:latest \
  -D . --datastore sqlite --input /var/log/suricata/eve.json
  # -e http://elastic:changeme@elasticsearch:9200 \
  # --no-index-suffix \
  # --index 'suricata-*'
