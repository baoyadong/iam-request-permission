local typedefs = require "kong.db.schema.typedefs"

return {
  name = "request-permission",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {},
      }
    }
  }
}
