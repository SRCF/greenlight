#! /bin/sh

docker-compose down
git pull
./scripts/image_build.sh dev release-v2
docker-compose up -d
