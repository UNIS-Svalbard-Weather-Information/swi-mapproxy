#!/bin/bash
HEALTHY=true

# Query stats
STATS=$(curl -s http://127.0.0.1:9191/)

# Check if stats are accessible
if [ -z "$STATS" ]; then
  echo "Stats server unreachable"
  exit 1
fi

# Check worker count (adjust as needed)
WORKERS=$(echo "$STATS" | jq '.workers[] | length')
if [ "$WORKERS" -lt 1 ]; then
  echo "No workers running"
  HEALTHY=false
fi

# Check listen queue (adjust threshold as needed)
LISTEN_QUEUE=$(echo "$STATS" | jq '.listen_queue')
if [ "$LISTEN_QUEUE" -gt 100 ]; then
  echo "High listen queue: $LISTEN_QUEUE"
  HEALTHY=false
fi

if [ "$HEALTHY" = true ]; then
  echo "uWSGI is healthy"
  exit 0
else
  echo "uWSGI is unhealthy"
  exit 1
fi
