#!/bin/sh
SURICATA_CAPTURE_FILTER=$(update.sh $OINKCODE)
suricatasc -c reload-rules
exec suricata -v -F $SURICATA_CAPTURE_FILTER "$@"
