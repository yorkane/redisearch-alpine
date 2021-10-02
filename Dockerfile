#FROM redislabs/redisearch:2.0.12
FROM redislabs/rejson:latest as json
FROM alpine:3.13 as builder
WORKDIR /data
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk add make gcc git make cmake g++ \
    && cd /data/ && git clone https://github.com/RediSearch/RediSearch.git \
    && cd RediSearch && mkdir build && cd build && cmake .. \
    && make

FROM alpine:3.13
ENV LIBDIR /redis/
ENV REDIS_PASSWORD pwd4Redis
ENV REDIS_BIND 0.0.0.0
ENV REDIS_PORT 6379
ENV REDIS_MAXMEMORY 1000MB
ENV REDIS_MAXMEMORY_POLICY allkeys-lru
WORKDIR /redisdata
COPY --from=builder  /data/RediSearch/build/redisearch.so "$LIBDIR"
COPY --from=json    /usr/lib/redis/modules/rejson.so* "$LIBDIR"
COPY redis_entrypont.sh    /usr/lib/redis/modules/rejson.so* "$LIBDIR"
EXPOSE 6379
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk --no-cache add redis && mkdir -p "$LIBDIR" \
    && sed -i "s/bind 127.0.0.1/bind $REDIS_BIND/g" /etc/redis.conf \
    && sed -i "s/^# requirepass foobared/requirepass $REDIS_PASSWORD/" /etc/redis.conf \
    && sed -i "s/^dir \/var\/lib\/redis/dir \/redisdata/" /etc/redis.conf \
    && sed -i "s/^dbfilename dump.rdb/dbfilename redisearch.rdb/" /etc/redis.conf \
    && sed -i "s/^# maxmemory <bytes>/maxmemory $REDIS_MAXMEMORY/" /etc/redis.conf \
    && sed -i "s/^# maxmemory-policy noeviction/maxmemory-policy $REDIS_MAXMEMORY_POLICY/" /etc/redis.conf \
    && sed -i "s/^# loadmodule \/path\/to\/my_module.so/loadmodule \/redis\/redisearch.so/" /etc/redis.conf \
    && sed -i "s/^# loadmodule \/path\/to\/other_module.so/loadmodule \/redis\/rejson.so/" /etc/redis.conf \
    && ln -sf /etc/redis.conf /redisdata/redis.conf \
    && chmod 755 /redis/redis_entrypont.sh \
    && echo "redis-server --loadmodule /redis/redisearch.so --loadmodule /redis/rejson.so --requirepass $REDIS_PASSWORD"

CMD ["/redis/redis_entrypont.sh"]
