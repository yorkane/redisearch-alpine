FROM redislabs/rejson:latest as json
FROM alpine:3.13 as builder
WORKDIR /data
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk add make gcc git make cmake g++ \
    && cd /data/ && git clone https://github.com/RediSearch/RediSearch.git \
    && cd RediSearch && mkdir build && cd build && cmake .. \
    && make

#FROM redislabs/rejson:1.0.8 as jsondev
#FROM redislabs/redisearch:2.0.12

FROM alpine:3.13
ENV LIBDIR /redis/
ENV REDIS_PASSWORD pwd4Redis

WORKDIR /data
COPY --from=builder  /data/RediSearch/build/redisearch.so       "$LIBDIR"
COPY --from=json    /usr/lib/redis/modules/rejson.so* "$LIBDIR"

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk --no-cache add redis && mkdir -p "$LIBDIR" \
    && sed -i "s/bind 127.0.0.1/bind 0.0.0.0/g" /etc/redis.conf \
    && sed -i "s/# requirepass foobared/requirepass pwd4Redis/" /etc/redis.conf \
    && sed -i "s/# loadmodule \/path\/to\/my_module.so/loadmodule \/redis\/redisearch.so/" /etc/redis.conf \
    && sed -i "s/# loadmodule \/path\/to\/other_module.so/loadmodule \/redis\/rejson.so/" /etc/redis.conf \
    && ln -sf /etc/redis.conf /data/redis.conf \
	&& echo "redis-server --loadmodule /redis/redisearch.so --loadmodule /redis/rejson.so --requirepass $REDIS_PASSWORD"


CMD ["redis-server", "/data/redis.conf"]
