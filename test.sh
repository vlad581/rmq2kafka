#!/bin/sh
docker compose stop rmq2kafka
sleep 5
docker compose run --rm generator -c ./pipeline/generator.yml
sleep 5
docker compose start rmq2kafka
