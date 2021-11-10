#!/bin/sh
set -e
export REDIS_BIND=${REDIS_BIND:-0.0.0.0}
export REDIS_PORT=${REDIS_PORT:-6379}
export REDIS_MAXMEMORY=${REDIS_MAXMEMORY:-1000MB}
export REDIS_MAXMEMORY_POLICY=${REDIS_MAXMEMORY_POLICY:-allkeys-lru}
if [ ! -f "/redisdata/redis.conf" ]; then
 echo "inital redis.conf file not exist, create new in /redisdata/redis.conf"
 cp /redis/redis.conf /redisdata/
fi

cd /redisdata/
sed -i "s/^bind .*$/bind $REDIS_BIND/g" redis.conf
sed -i "s/^#* *requirepass .*$/requirepass $REDIS_PASSWORD/" redis.conf
sed -i "s/^dir .*$/dir \/redisdata/" redis.conf
sed -i "s/^dbfilename .*$/dbfilename redisearch.rdb/" redis.conf
sed -i "s/^logfile .*$/logfile \/redisdata\/redis.log/" redis.conf
sed -i "s/^#* *maxmemory .*$/maxmemory $REDIS_MAXMEMORY/" redis.conf
sed -i "s/^#* *maxmemory-policy .*$/maxmemory-policy $REDIS_MAXMEMORY_POLICY/" redis.conf
sed -i "s/^# *loadmodule \/path\/to\/my_module.so/loadmodule \/redis\/redisearch.so/" redis.conf
sed -i "s/^# *loadmodule \/path\/to\/other_module.so/loadmodule \/redis\/rejson.so/" redis.conf
sed -i "s/^loadmodule \/redis\/rejson.so/loadmodule \/redis\/rejson.so\nloadmodule \/redis\/redis-roaring.so\n/" /etc/redis.conf

if [ ! -n "$1" ] ;then
	echo "start: redis-server /redisdata/redis.conf"
  	redis-server /redisdata/redis.conf
  	exit 0
fi

exec "$@"
exit 0
