## 安装lua插件
luarocks install lua-cjson
luarocks install lua-resty-http
luarocks install lua-resty-redis

### 踩坑
1. 打印日志的话，使用 kong.log，kong.log.inspect等，其他的kong.log.info，kong.log.debug等打印不出来
2. 本地打包使用 luarocks make --pack-binary-rock $@.rockspec，可以打进本地修改的文件。