local http = require "resty.http"
local cjson = require "cjson"
local redis = require "resty.redis"
local kong_meta = require "kong.meta"


local KONG_ENV = 'dev'
local whiteList = {
  "/",
  "/api/ms-iam/v1/user/token",
  "/api/ms-iam/v2/api/auth/logout",
  "/ms-iam/v2/api/auth/logout",
  "/ms-iam/v1/user/token",

  "/login/ms-iam/v1/sso/callback",
  "/login/ms-iam/v1/sso/logout",
  "/login/ms-iam/v1/sso/acs",
  "/ms-iam/v1/sso/callback",
  "/ms-iam/v1/sso/acs",
  "/ms-iam/v1/sso/logout",

  "/login/ms-iam/v1/api/auth",
  "/login/ms-iam/v1/api/auth/login",
  "/login/ms-iam/v1/api/auth/check/authToken",
  "/login/ms-iam/v1/api/auth/register",
  "/login/ms-iam/v1/api/auth/permission",
  "/login/ms-iam/v1/api/auth/permission/detail",
  "/login/ms-iam/v1/api/auth/check/password",
  "/login/ms-iam/v1/api/auth/accessKey",
  "/login/ms-iam/v1/api/auth/secretKey",
  "/login/ms-iam/v1/api/auth/user/register",
  "/login/ms-iam/v1/api/auth/activate",
  "/login/ms-iam/v1/api/auth/assist/login",
  "/login/ms-iam/v1/api/auth/wx/login",
  "/login/ms-iam/v1/api/auth/sso",
  "/login/ms-iam/v1/api/auth/logoutAndRedirect",

  "/ms-iam/v1/api/auth",
  "/ms-iam/v1/api/auth/login",
  "/ms-iam/v1/api/auth/check/authToken",
  "/ms-iam/v1/api/auth/register",
  "/ms-iam/v1/api/auth/permission",
  "/ms-iam/v1/api/auth/permission/detail",
  "/ms-iam/v1/api/auth/check/password",
  "/ms-iam/v1/api/auth/accessKey",
  "/ms-iam/v1/api/auth/secretKey",
  "/ms-iam/v1/api/auth/user/register",
  "/ms-iam/v1/api/auth/activate",
  "/ms-iam/v1/api/auth/assist/login",
  "/ms-iam/v1/api/auth/wx/login",
  "/ms-iam/v1/api/auth/sso",
  "/ms-iam/v1/api/auth/logoutAndRedirect",
}

function isSpecificFileType(filename)
  -- 使用模式匹配来判断文件名是否以.html, .js, .css或图片扩展名结尾
  return filename:match("%.html$") or
         filename:match("%.js$") or
         filename:match("%.css$") or
         filename:match("%.png$") or
         filename:match("%.jpg$") or
         filename:match("%.jpeg$") or
         filename:match("%.gif$") or
         filename:match("%.bmp$") or
         filename:match("%.readme$") or
         filename:match("%.ico$") or
         filename:match("%.woff2$") or
         filename:match("%.svg$")
end

local function isInWhiteList(arr, val)
  for index, value in ipairs(arr) do
    if val == value then
      return true
    end
  end
  return false
end


local REDIS_CACHE_TTL = 5 * 60 -- 缓存时间，单位秒

-- 获取当前环境的配置
-- function get_enviromnent_config()
--   if KONG_ENV == 'production' then
--     return {
--       permission_api_url = "http://ms-iam/v1/permission/path",
--       redis_host = "production-redis-host",
--       redis_port = 6379,
--     }
--   end
--   if KONG_ENV== 'test' then
--     return {
--       permission_api_url = "http://ms-iam/v1/permission/path",
--       redis_host = "production-redis-host",
--       redis_port = 6379,
--     }
--   end
--   return {
--     permission_api_url = "http://ms-iam/v1/permission/path",
--     redis_host = "development-redis-host",
--     redis_port = 6379,
--   }
-- end

-- 检查权限并缓存到Redis
local function has_permission(path)
  -- 获取当前环境配置
  local env_config = {
    permission_api_url = "http://172.16.255.27:46473/v1/permission/path",
    redis_host = "development-redis-host",
    redis_port = 6379
  }

  local headers = ngx.req.get_headers()

  kong.log("headers")
  kong.log.inspect(headers)
  local authorization_header = headers["authorization"]
  local action = kong.request.get_method()
  local appId = headers["x-system-identify"]
  local userId = headers["x-user-id"]
  kong.log(authorization_header, action, appId, userId)

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
  local request_body_string = cjson.encode(request_body)
  kong.log("request_body_string: ", request_body_string)
  kong.log("request_body_string length: ", #request_body_string)

  local httpc = http.new()
  local res, err = httpc:request_uri(permission_api_url, {
    method = "POST",
    body = request_body_string,
    headers = {
      ["Content-Type"] = "application/json;charset=UTF-8",
      -- ["Content-Length"] = #request_body_string,
      ["Authorization"] = authorization_header,
      ["x-user-id"] = userId,
      headers=headers
    },
    ssl_verify = false,  -- 仅在测试阶段，不建议在生产中使用
  })
  if not res or res.status ~= 200 then
    kong.log.err("Failed to request permission API: ", err)
    return false
  end

  kong.log.inspect(res)
  local permission_info = cjson.decode(res.body)
  kong.log("permission_info: ", permission_info)
  kong.log.inspect(permission_info)
  -- 将权限信息缓存到Redis
  -- red:setex(cache_key, REDIS_CACHE_TTL, cjson.encode(permission_info))

  if permission_info ~= nil and permission_info.data ~= nil then
    return permission_info.data
  end
  return false
end


local RequestHandler = {
  PRIORITY = 1000,
  VERSION=kong_meta.version
}

function RequestHandler:access(conf)
  -- 获取当前请求的路径
  kong.log.inspect(conf)
  local request_path = kong.request.get_path()
  kong.log("request_path: ", request_path)
  if not request_path then
    return;
  end

  if isSpecificFileType(request_path) or isInWhiteList(whiteList, request_path) then
    kong.log("whiteList")
    return;
  end

  local permission = has_permission(request_path)
  if not permission then
    -- 没有权限，返回403 Forbidden
    kong.response.exit(403, { message = "Forbidden: You do not have permission to access this resource." })
  end
end

return RequestHandler
