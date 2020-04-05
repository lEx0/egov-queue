local redis = require "resty.redis"
local red = redis:new()

red:set_timeouts(1000, 1000, 1000) -- 1 sec

local ok, err = red:connect("redis", 6379)
if not ok then
    ngx.say("failed to connect to redis: ", err)
    return
end

local offset, err = red:get("global_offset")
ngx.say(offset)