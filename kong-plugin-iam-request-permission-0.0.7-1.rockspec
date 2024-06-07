local plugin_name = "iam-request-permission"
version = "0.0.7-1"
local package_name = "kong-plugin-" .. plugin_name

-- The version '1.0.0' is the source code version, the trailing '1' is the version of this rockspec.
-- whenever the source version changes, the rockspec should be reset to 1. The rockspec version is only
-- updated (incremented) when this file changes, but the source remains the same.

-- TODO: This is the name to set in the Kong configuration `plugins` setting.
-- Here we extract it from the package name.

supported_platforms = {"linux", "macosx"}

package = package_name


description = {
  summary = "request permission plugin for ms-iam services",
  -- homepage = "http://ms-iam",
  -- license = "private"
}

source = {
  url = "git://github.com/baoyadong/iam-request-permission",
  branch = "main",
}

dependencies = {
  "lua >= 5.1",
  -- "lua-cjson = 2.1.0.9-1",
  "lua-resty-http >= 0.16",
  "lua-resty-redis >= 0.27",
}

build = {
  type = "builtin",
  modules = {
    -- TODO: add any additional files that the plugin consists of
    -- 根据自己的实际路径去修改
    ["kong.plugins."..plugin_name..".handler"] = "kong/plugins/"..plugin_name.."/handler.lua",
    ["kong.plugins."..plugin_name..".schema"] = "kong/plugins/"..plugin_name.."/schema.lua",
  }
}
