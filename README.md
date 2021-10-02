# redisearch-alpine
A Docker image for alpine

## redisearch
> https://oss.redis.com/redisearch/Commands/
```
FT.DROPINDEX myIdx DD
FT.CREATE myIdx ON HASH LANGUAGE chinese PREFIX 1 doc: SCHEMA title TEXT WEIGHT 5.0 body TEXT url TEXT
hset doc:1 title "hello world" body "lorem ipsum 汉字 朋友 china and england" url "http://redis.io"
FT.SEARCH myIdx "朋友" LIMIT 0 10
```

## redisjson
> https://oss.redis.com/redisjson/
```
JSON.SET obj . '{"name":"Leonard Cohen","lastSeen":1478476800,"loggedOut": true, "foo":{"a":"letter a","b":2, "arr":[0,1,2,3]}}'
JSON.GET obj .foo.a -> "letter"
JSON.GET obj .foo.arr[0] -> 0
JSON.TYPE obj .name -> string
JSON.NUMINCRBY obj .foo.arr[0] 10
JSON.GET obj .foo.arr[0] -> 10
```
