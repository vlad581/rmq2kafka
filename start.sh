#!/bin/sh
set -e
docker compose rm -f -s -v
#docker container prune -f 
docker-compose up -d 
