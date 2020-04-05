--- Queue Egov
-- @module queue
-- @license MIT
-- @release 0.0.1


local _M = {
    _VERSION = '0.0.1'
}

function _M.getPosition(size)
    local ck = require "resty.cookie"
    local cookie, err = ck:new()
    if not cookie then
        ngx.log(ngx.ERR, err)
        return nil, err
    end

    local redis = require "resty.redis"
    local red = redis:new()

    red:set_timeouts(1000, 1000, 1000) -- 1 sec

    local ok, err = red:connect("redis", 6379)
    if not ok then
        return nil, err
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
    else
        currentUuid = uuidCookie
    end

    local myPosition, err = red:get(currentUuid)
    if myPosition == ngx.null then
        myPosition, err = red:incr("global_counter")
    end

    -- время жизни юзера - 20 секунд
    red:setex(currentUuid, 20, myPosition)

    myPosition=tonumber(myPosition)
    ngx.log(ngx.INFO, "client position: " .. myPosition)

    local globalOffset, err = red:get("global_offset")
    if globalOffset == ngx.null then
        globalOffset = tostring(size)
        red:set("global_offset", tostring(size))
    end

    return myPosition - globalOffset, nil
end

return _M