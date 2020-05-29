#!/usr/bin/env bash

for node in "$@"; do
#  status="$( ssh $node docker info --format '{{.Swarm.LocalNodeState}}' )"
  if ssh "$node" docker info --format '{{.Swarm.LocalNodeState}}' | grep "^active" > /dev/null 2>&1; then
    if ssh "$node" docker info | grep "Is Manager" | grep "true" > /dev/null 2>&1; then
      echo "$node"
      exit 0
    fi
  fi
done
exit 1