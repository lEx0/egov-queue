local ck = require "resty.cookie"
local cookie, err = ck:new()
if not cookie then
    ngx.log(ngx.ERR, err)
    return
end

local redis = require "resty.redis"
local red = redis:new()

red:set_timeouts(1000, 1000, 1000) -- 1 sec

local ok, err = red:connect("redis", 6379)
if not ok then
    ngx.say("failed to connect to redis: ", err)
    return
end

local uuidGenerator = require "resty.jit-uuid"
local currentUuid
local uuidCookie, err = cookie:get("uuid")
if not uuidCookie then
    currentUuid = uuidGenerator()
    local ok, err = cookie:set({
        key = "uuid",
        value = currentUuid,
        samesite = "Strict"
    })
    ngx.say("hey new user, your cookie is ", currentUuid)
else
    currentUuid = uuidCookie
    ngx.say("you have returned, your cookie is ", currentUuid)
end

local myPosition, err = red:get(currentUuid)
if myPosition == ngx.null then
    myPosition, err = red:incr("global_counter")
end

-- время жизни юзера - 20 секунд
red:setex(currentUuid, 20, myPosition)

myPosition=tonumber(myPosition)
ngx.log(ngx.INFO, "client position: " .. myPosition)

-- todo унести в redis
local globalOffset = 2

ngx.say("<br>your position is ", myPosition, " ", myPosition - globalOffset)
ngx.say("<br><br><0 means you must be redirected to egov. otherwise wait and reload the page")
