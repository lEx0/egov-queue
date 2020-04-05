local redis = require "resty.redis"
local red = redis:new()

red:set_timeouts(1000, 1000, 1000) -- 1 sec

local ok, err = red:connect("redis", 6379)
if not ok then
    ngx.say("failed to connect to redis: ", err)
    return
end

local args, err = ngx.req.get_uri_args()

if not args.offset then
    ngx.say("Usage: ?offset=123")
else
    red:set("global_offset", args.offset)
    ngx.say("ok, new offset is ", args.offset)
end