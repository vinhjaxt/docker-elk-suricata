#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

HOST_NAME="suricata"

if [[ "$(docker images -q "${HOST_NAME}:latest" 2> /dev/null)" == "" || "$1" != "" ]]; then
  docker build -t "${HOST_NAME}:latest" "${DIR}/"
  if [ $? -eq 0 ]; then
      echo 'Build done'
  else
      echo 'Build failed'
      exit 1
  fi
fi

docker container inspect "${HOST_NAME}" >/dev/null 2>&1
if [ $? -eq 0 ]; then
  docker stop "${HOST_NAME}"
  docker rm "${HOST_NAME}"
fi

# For ET Pro ruleset replace "OPEN" with your OINKCODE
docker run -d --restart=unless-stopped --name "${HOST_NAME}" --hostname "${HOST_NAME}" \
    -e PUID=$(id -u) -e PGID=$(id -u) \
    -e OINKCODE=OPEN \
    --network=host \
    --cap-add=NET_ADMIN --cap-add=SYS_NICE --cap-add=NET_RAW \
    -v "${DIR}/${HOST_NAME}/logs":/var/log/suricata \
    -v "${DIR}/${HOST_NAME}/lib":/var/lib/suricata \
    -v "${DIR}/entrypoint.sh":/entrypoint.sh \
    "${HOST_NAME}:latest" -i wlan0
