local http = require "resty.http"
local cjson = require "cjson"
local redis = require "resty.redis"
local kong_meta = require "kong.meta"


local KONG_ENV = 'dev'


local REDIS_CACHE_TTL = 5 * 60 -- 缓存时间，单位秒

-- 获取当前环境的配置
local function get_enviromnent_config()
  if KONG_ENV == 'production' then
    return {
      permission_api_url = "http://ms-iam/v1/permission/path",
      redis_host = "production-redis-host",
      redis_port = 6379,
    }
  end
  if KONG_ENV== 'test' then
    return {
      permission_api_url = "http://ms-iam/v1/permission/path",
      redis_host = "production-redis-host",
      redis_port = 6379,
    }
  end
  return {
    permission_api_url = "http://ms-iam/v1/permission/path",
    redis_host = "development-redis-host",
    redis_port = 6379,
  }
end

-- 检查权限并缓存到Redis
local function has_permission(path, headers)
  -- 获取当前环境配置
  local env_config = get_environment_config()

  local authorization_header = headers['Authorization']
  local action = headers['method']
  local appId = headers['appId']

  -- 尝试从Redis缓存获取权限信息
  -- local red = redis:new()
  -- red:set_timeout(1000) -- 1秒超时
  -- local ok, err = red:connect(env_config.redis_host, env_config.redis_port)
  -- if not ok then
  --   kong.log.err("Failed to connect to Redis: ", err)
  --   return false
  -- end

  -- local cache_key = table.concat({appId, action, path}, ':')
  -- local cached_permission, err = red:get(cache_key)
  -- if cached_permission and cached_permission ~= ngx.null then
  --   -- 从缓存中获取权限信息
  --   kong.log.debug("Permission found in Redis cache", cached_permission)
  --   return cjson.decode(cached_permission)
  -- end

  -- 缓存中不存在，从权限接口获取
  local permission_api_url = env_config.permission_api_url

  local request_body = {action=action, path=path}
  local httpc = http.new()
  local res, err = httpc:request_uri(permission_api_url, {
    method = "POST",
    body = cjson.encode(request_body),
    headers = {
      ["Content-Type"] = "application/json",
      ["Content-Length"] = #request_body,
      ["Authorization"]=authorization_header,
      headers=headers
    },
    -- ssl_verify = false,  -- 仅在测试阶段，不建议在生产中使用
  })

  if not res or res.status ~= 200 then
    kong.log.err("Failed to request permission API: ", err)
    return false
  end

  local permission_info = cjson.decode(res.body)
  kong.log.debug("permission_info: ", permission_info)
  
  -- 将权限信息缓存到Redis
  -- red:setex(cache_key, REDIS_CACHE_TTL, cjson.encode(permission_info))

  return permission_info
end


local RequestHandler = {
  PRIORITY = 1000,
  VERSION=kong_meta.version
}

function RequestHandler:access(conf)
  -- 获取当前请求的路径
  local request_path = kong.request.get_path()
  local headers = kong.request.get_headers()
  local permission = has_permission(request_path, headers)
  if not permission then
    -- 没有权限，返回403 Forbidden
    kong.response.exit(403, { message = "Forbidden: You do not have permission to access this resource." })
  end
  -- 添加日志记录
  kong.log.info("Request path: ", request_path)
  kong.log.info("Permission info: ", cjson.encode(permission))
end

return RequestHandler