#!/bin/sh

# Endpoint to check
ENDPOINT="http://127.0.0.1:8080/service?REQUEST=GetCapabilities&SERVICE=WMS"

# Use curl to check the endpoint
response=$(curl -s -o /dev/null -w "%{http_code}" "$ENDPOINT")

# Check if the response is 200
if [ "$response" -eq 200 ]; then
  exit 0
else
  exit 1
fi
