#!/bin/bash

set -ex

export NODE_NAME=${NODE_NAME:-${HOSTNAME}}
export MAX_BYTES=${RECOVERY_MAX_BYTES:-""}
export MODE_DRAIN_NODE=${MODE_DRAIN_NODE:-"true"}
export MODE_DISABLE_SHARDS_ALLOCATION=${MODE_DISABLE_SHARDS_ALLOCATION:-"false"}


# Set recovery max_bytes_per_sec
if [ "$MAX_BYTES" != "" ]; then
  echo "Setting index recovery max bytes to $MAX_BYTES"
  curl --retry 3 -s -XPUT -H 'Content-Type: application/json' 'localhost:9200/_cluster/settings' -d "{ \"transient\" :{ \"indices.recovery.max_bytes_per_sec\" : \"${MAX_BYTES}\" }}"
fi


# Perform maintenance based on MODE Selected
if [ "$MODE_DRAIN_NODE" == "true" ]; then
  echo "DRAIN_NODE mode selected"
  echo "Disabling Local Routing for this Node - Will move all shards to other nodes"
  curl --retry 3 -s -XPUT -H 'Content-Type: application/json' 'localhost:9200/_cluster/settings' -d "{ \"transient\" :{ \"cluster.routing.allocation.exclude._name\" : \"${NODE_NAME}\" }}"
  
  sleep 2
  while true ; do
    echo -e "Wait for node ${NODE_NAME} to become empty of shards"
    SHARDS_ALLOCATION=$(curl --retry 3 -s -XGET 'http://localhost:9200/_cat/shards')
    if ! echo "${SHARDS_ALLOCATION}" | grep -E "${NODE_NAME}"; then
      break
    fi
    sleep 2
  done

fi
