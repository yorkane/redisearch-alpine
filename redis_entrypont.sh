#!/bin/sh
set -e
export REDIS_BIND=${REDIS_BIND:-6379}
export REDIS_PORT=${REDIS_PORT:-6379}
export REDIS_MAXMEMORY=${REDIS_MAXMEMORY:-1000MB}
export REDIS_MAXMEMORY_POLICY=${REDIS_MAXMEMORY_POLICY:-allkeys-lru}
if [ ! -f "/redisdata/redis.conf" ]; then
 cp /etc/redis.conf /redisdata/
fi

if [ ! -n "$1" ] ;then
  cd /redisdata/
  sed -i "s/^requirepass .*/requirepass $REDIS_PASSWORD/" redis.conf
  sed -i "s/^bind .*/bind  $REDIS_BIND/" redis.conf
  sed -i "s/^port .*/port  $REDIS_PORT/" redis.conf
  sed -i "s/^maxmemory .*/maxmemory $REDIS_MAXMEMORY/" redis.conf
  sed -i "s/^maxmemory-policy .*/maxmemory-policy $REDIS_MAXMEMORY_POLICY/" redis.conf
  redis-server redis.conf
  exit 0
fi

exec redis-server --loadmodule /redis/redisearch.so --loadmodule /redis/rejson.so "$@"
exit 0
