#!/bin/bash
HEALTHY=true

# Query stats
STATS=$(uwsgi --connect-and-read 127.0.0.1:1717)
if [ -z "$STATS" ]; then
  echo "Stats server unreachable"
  exit 1
fi

# Check worker count
WORKERS=$(echo "$STATS" | jq '[.workers[]] | length')
if [ "$WORKERS" -lt 1 ] || [ "$WORKERS" -gt 10 ]; then
  echo "Worker count abnormal: $WORKERS"
  HEALTHY=false
fi

# Check listen queue
LISTEN_QUEUE=$(echo "$STATS" | jq '.listen_queue')
if [ "$LISTEN_QUEUE" -gt 50 ]; then
  echo "High listen queue: $LISTEN_QUEUE"
  HEALTHY=false
fi

# Check harakiri events
HARAKIRI=$(echo "$STATS" | jq '.harakiri_count')
if [ "$HARAKIRI" -gt 5 ]; then
  echo "Harakiri events detected: $HARAKIRI"
  HEALTHY=false
fi

# Check exceptions
EXCEPTIONS=$(echo "$STATS" | jq '.exceptions')
if [ "$EXCEPTIONS" -gt 0 ]; then
  echo "Exceptions detected: $EXCEPTIONS"
  HEALTHY=false
fi

if [ "$HEALTHY" = true ]; then
  echo "uWSGI is healthy"
  exit 0
else
  echo "uWSGI is unhealthy"
  exit 1
fi
