package = "iam-request-permission"
version = "0.0.1-1"
-- The version '1.0.0' is the source code version, the trailing '1' is the version of this rockspec.
-- whenever the source version changes, the rockspec should be reset to 1. The rockspec version is only
-- updated (incremented) when this file changes, but the source remains the same.

-- TODO: This is the name to set in the Kong configuration `plugins` setting.
-- Here we extract it from the package name.

supported_platforms = {"linux", "macosx"}

description = {
  summary = "request permission plugin for ms-iam services",
  -- homepage = "http://ms-iam",
  -- license = "private"
}

source = {
  url = "git://github.com/baoyadong/iam-request-permission",
}

dependencies = {
  "lua >= 5.1"
}

build = {
  type = "builtin",
  modules = {
    -- TODO: add any additional files that the plugin consists of
    -- 根据自己的实际路径去修改
    ["kong.plugins.iam-request-permission.handler"] = "kong/plugins/iam-request-permission/handler.lua",
    ["kong.plugins.iam-request-permission.schema"] = "kong/plugins/iam-request-permission/schema.lua",
  }
}
