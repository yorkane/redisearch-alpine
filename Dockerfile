FROM redislabs/rejson:2.0.6 as json
FROM alpine:3.14 as builder
WORKDIR /data
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    echo 'ls -la "$@"' > /usr/bin/ll && chmod 755 /usr/bin/ll && \
    apk add curl make gcc git make cmake g++ gettext libarchive-tools libxxhash xxhash-dev tree && \
    cd /data/ &&curl -L https://github.com/RediSearch/RediSearch/archive/refs/tags/v2.2.7.zip | bsdtar -xkf- -C ./ && \
    cd RediSearch-* && mkdir build -p && cd build && cmake .. && make && \
    echo "RediSearch build finished!"
# friso initialize
#RUN cd /data/ && curl -L "https://github.com/lionsoul2014/friso/archive/refs/heads/master.zip" |  bsdtar -xkf- -C ./ &&\
#    mv friso-*/ friso/ &&\
#    mkdir /friso/dict/ -p && mv friso/vendors/dict/UTF-8/ /friso/dict/ &&\
#    cp friso/friso.ini /friso/ && sed -i "s/^friso.lex_dir .*$/friso.lex_dir  = \/friso\/dict\/UTF-8\//" /friso/friso.ini &&\
#    cd /friso/dict/UTF-8/ && echo "#" > lex-extra1.lex && echo "#" > lex-extra2.lex && echo "#" > lex-extra3.lex &&\
#    sed -i "s/# add more here.*$/\tlex-extra1.lex;\n\tlex-extra2.lex;\n\tlex-extra3.lex;/" /friso/dict/UTF-8/friso.lex.ini &&\
#    echo "friso initialized"

# roaring
RUN	cd /data/ && curl -L https://github.com/yorkane/redis-roaring/archive/refs/heads/main.zip | bsdtar -xkf- -C ./ && \
    cd redis-roaring-main && sh deps.sh && make && \
    echo "croaring and redis-roaring build finished!"
#RUN cd /data/redis-roaring-main/croaring && make && ll /usr/local/lib/

RUN	apk add automake libtool autoconf bzip2 linux-headers && \
    cd /data/ &&curl -L https://github.com/vipshop/redis-migrate-tool/archive/refs/heads/master.zip | bsdtar -xkf- -C ./ && \
    cd redis-migrate-tool* && autoreconf -fvi && ./configure && make && mv ./src/redis-migrate-tool ../ && \
    echo "redis-migrate-tool build finished!"

FROM alpine:3.14
ENV LIBDIR /redis/
ENV DATADIR /redisdata/
ENV REDIS_PASSWORD pwd4Redis
ENV REDIS_BIND 127.0.0.1
ENV REDIS_PORT 6379
ENV REDIS_MAXMEMORY 2000MB
ENV REDIS_MAXMEMORY_POLICY allkeys-lru
WORKDIR /redisdata
COPY --from=builder /data/RediSearch-*/build/redisearch.so "$LIBDIR"
COPY --from=builder /usr/lib/libroaring.so.2 /usr/lib/
COPY --from=builder /data/redis-roaring-main/croaring/roaring.h* /usr/include/roaring/
COPY --from=builder /data/redis-roaring-main/redis-roaring.so "$LIBDIR"
COPY --from=builder  /usr/bin/envsubst /usr/local/bin/
COPY --from=builder  /data/redis-migrate-tool /usr/local/bin/
#COPY --from=builder  /friso/ /friso/
COPY --from=json    /usr/lib/redis/modules/rejson.so* "$LIBDIR"
COPY redisearch_entrypont.sh  "$LIBDIR"
EXPOSE 6379
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && echo 'ls -la "$@"' > /usr/bin/ll && chmod 755 /usr/bin/ll \
    && ln -sf /usr/lib/libroaring.so.2 /usr/lib/libroaring.so \
    && apk --no-cache add redis gcompat libgcc && mkdir -p "$LIBDIR" \
    && sed -i "s/^bind .*$/bind $REDIS_BIND/g" /etc/redis.conf \
    && sed -i "s/^#*requirepass foobared/requirepass $REDIS_PASSWORD/" /etc/redis.conf \
    && sed -i "s/^dir .*$/dir \/redisdata/" /etc/redis.conf \
    && sed -i "s/^dbfilename .*$/dbfilename redisearch.rdb/" /etc/redis.conf \
    && sed -i "s/^logfile .*$/logfile \/redisdata\/redis.log/" /etc/redis.conf \
    && sed -i "s/^#* *maxmemory .*$/maxmemory $REDIS_MAXMEMORY/" /etc/redis.conf \
    && sed -i "s/^#* *maxmemory-policy .*$/maxmemory-policy $REDIS_MAXMEMORY_POLICY/" /etc/redis.conf \
    && sed -i "s/^# loadmodule \/path\/to\/my_module.so/loadmodule \/redis\/redisearch.so" /etc/redis.conf \
    && sed -i "s/^# loadmodule \/path\/to\/other_module.so/loadmodule \/redis\/rejson.so/" /etc/redis.conf \
    && sed -i "s/^loadmodule \/redis\/rejson.so/loadmodule \/redis\/rejson.so\nloadmodule \/redis\/redis-roaring.so\n/" /etc/redis.conf \
    && cp /etc/redis.conf /redis/redis.conf \
    && chmod 755 /redis/redisearch_entrypont.sh \
    && echo "redis-server --loadmodule /redis/redisearch.so --loadmodule /redis/rejson.so --loadmodule /redis/redis-roaring.so --requirepass $REDIS_PASSWORD"

ENTRYPOINT ["/redis/redisearch_entrypont.sh"]
