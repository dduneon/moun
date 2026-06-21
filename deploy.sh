#!/bin/bash
docker pull ghcr.io/dduneon/moun/backend:latest
docker stop moun-backend 2>/dev/null || true
docker rm moun-backend 2>/dev/null || true

# 혹시 4020 포트 점유 중인 컨테이너 강제 제거
docker ps -q --filter "publish=4020" | xargs -r docker stop
docker ps -aq --filter "publish=4020" | xargs -r docker rm

docker run -d \
  --name moun-backend \
  --network service-net \
  -p 4020:4020 \
  --env-file .env \
  ghcr.io/dduneon/moun/backend:latest
