-- функция пропускает следующего пользователя на сайт
-- уменьшая счетчик в редисе
local function next(red)
    local usersOnline, err = red:decr("users_online")
    if err then
        ngx.log(ngx.ERR, "Redis error: " .. err)
    end

    return usersOnline
end

local redis = require "resty.redis"
local red = redis:new()

red:set_timeouts(1000, 1000, 1000) -- 1 sec

local ok, err = red:connect("redis", 6379)
if not ok then
    ngx.say("failed to connect to redis: ", err)
    return
end

local usersOnline = next(red)
ngx.say("ok, users online: ", usersOnline)
