FROM redislabs/rejson:latest as json
FROM alpine:3.14 as builder
WORKDIR /data
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    apk add curl make gcc git make cmake g++ gettext libarchive-tools libxxhash xxhash-dev && \
    cd /data/ &&curl -L https://github.com/RediSearch/RediSearch/archive/refs/heads/master.zip | bsdtar -xkf- -C ./ && \
    cd RediSearch-master && mkdir build && cd build && cmake .. -DRS_FORCE_NO_GITVERSION=ON && make && \
    echo "RediSearch build finished!" && \
# roaring
	echo 'ls -la "$@"' > /usr/bin/ll && chmod 755 /usr/bin/ll && \
	cd /data/ && curl -L https://github.com/yorkane/redis-roaring/archive/refs/heads/main.zip | bsdtar -xkf- -C ./ && \
    cd redis-roaring-main && sh deps.sh && make && \
    echo "croaring and redis-roaring build finished!"
#RUN cd /data/redis-roaring-main/croaring && make && ll /usr/local/lib/

FROM alpine:3.14
ENV LIBDIR /redis/
ENV DATADIR /redisdata/
ENV REDIS_PASSWORD pwd4Redis
ENV REDIS_BIND 127.0.0.1
ENV REDIS_PORT 6379
ENV REDIS_MAXMEMORY 1000MB
ENV REDIS_MAXMEMORY_POLICY allkeys-lru
WORKDIR /redisdata
COPY --from=builder /data/RediSearch-master/build/redisearch.so "$LIBDIR"
COPY --from=builder /usr/lib/libroaring.so.2 /usr/lib/
COPY --from=builder /data/redis-roaring-main/croaring/roaring.h* /usr/include/roaring/
COPY --from=builder /data/redis-roaring-main/redis-roaring.so "$LIBDIR"
COPY --from=builder  /usr/bin/envsubst /usr/local/bin/
COPY --from=json    /usr/lib/redis/modules/rejson.so* "$LIBDIR"
COPY redis_entrypont.sh  "$LIBDIR"
EXPOSE 6379
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk --no-cache add redis libxxhash && mkdir -p "$LIBDIR" \
    && sed -i "s/^bind .*$/bind $REDIS_BIND/g" /etc/redis.conf \
    && sed -i "s/^#*requirepass foobared/requirepass $REDIS_PASSWORD/" /etc/redis.conf \
    && sed -i "s/^dir .*$/dir \/redisdata/" /etc/redis.conf \
    && sed -i "s/^dbfilename .*$/dbfilename redisearch.rdb/" /etc/redis.conf \
    && sed -i "s/^logfile .*$/logfile \/redisdata\/redis.log/" /etc/redis.conf \
    && sed -i "s/^#* *maxmemory .*$/maxmemory $REDIS_MAXMEMORY/" /etc/redis.conf \
    && sed -i "s/^#* *maxmemory-policy .*$/maxmemory-policy $REDIS_MAXMEMORY_POLICY/" /etc/redis.conf \
    && sed -i "s/^# loadmodule \/path\/to\/my_module.so/loadmodule \/redis\/redisearch.so/" /etc/redis.conf \
    && sed -i "s/^# loadmodule \/path\/to\/other_module.so/loadmodule \/redis\/rejson.so/" /etc/redis.conf \
    && sed -i "s/^loadmodule \/redis\/rejson.so/loadmodule \/redis\/rejson.so\nloadmodule \/redis\/redis-roaring.so\n/" /etc/redis.conf \
    && cp /etc/redis.conf /redis/redis.conf \
    && chmod 755 /redis/redis_entrypont.sh \
    && echo "redis-server --loadmodule /redis/redisearch.so --loadmodule /redis/rejson.so --loadmodule /redis/redis-roaring.so --requirepass $REDIS_PASSWORD"

ENTRYPOINT ["/redis/redis_entrypont.sh"]
#CMD ["/redis/redis_entrypont.sh"]

# docker build ./ -f redis.Dockerfile -t redis:1
# docker run -d --network=host -v /data:/redisdata -e REDIS_BIND=0.0.0.0 -e REDIS_PASSWORD=redis --name=redis1 redis:1
