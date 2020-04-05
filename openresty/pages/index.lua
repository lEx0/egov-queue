-- функция проверяет позицию юзера в очереди
-- через lua скрипт в редисе
local function getPostitionByUid(red, uuid)
    local script = [[
    --todo вынести в конфиг
    local userLifetime = 600 -- время жизни ключа юзера в редисе
    local maxUsersOnline = 20 -- максимальное число пользователей на егов

    local currentUsersOnline = tonumber(redis.call("GET", "users_online"))
    local userKey = string.format("user_%s", KEYS[1])
    local userValue = tonumber(redis.call("GET", userKey))
    local userPosition = redis.call("ZRANK", "user_queue", userKey)

    redis.log(redis.LOG_DEBUG, "total users online", currentUsersOnline)

    if userValue == -1 then
        -- пользователь уже пропущен на сайт
        redis.log(redis.LOG_DEBUG, "user is already online", userKey)

        return -1
    elseif userPosition == 0  and (currentUsersOnline ~= nil and currentUsersOnline < maxUsersOnline) then
        -- пользователь должен пройти на сайт прямо сейчас
        redis.call("INCR", "users_online")
        redis.call("ZREM", "user_queue", userKey)
        redis.call("SETEX", userKey, userLifetime, -1)
        redis.log(redis.LOG_DEBUG, "user is allowed to go online", userKey)

        return -1
    elseif userPosition ~= false then
        -- пользователь находится в очереди, нужно продлить время жизни его ключа и вернуть его позицию
        redis.call("SETEX", userKey, userLifetime, userPosition)
        redis.log(redis.LOG_DEBUG, "user position is retrieved", userKey, userPosition)

        return userPosition
    elseif currentUsersOnline ~= nil and currentUsersOnline >= maxUsersOnline then
        -- пользователь новый и его надо добавить в очередь
        local usersInQueue = redis.call("ZCARD", "user_queue")
        if usersInQueue == false then
            usersInQueue = 0
        end

        redis.call("ZADD", "user_queue", usersInQueue, userKey)
        redis.call("SETEX", userKey, userLifetime, usersInQueue)
        redis.log(redis.LOG_DEBUG, "new user is added", userKey, usersInQueue)

        return usersInQueue
    else
        -- пользователь новый, очередь свободна - пропускаем на сайт
        currentUsersOnline = redis.call("INCR", "users_online")
        redis.call("SETEX", userKey, userLifetime, -1)
        redis.log(redis.LOG_DEBUG, "new user is allowed to go online", userKey)

        return -1
    end
    ]]

    local position, err = red:eval(script, 1, uuid)
    if err then
        ngx.log(ngx.ERR, "Redis error: " .. err)
    end

    return position
end


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

local position = getPostitionByUid(red, currentUuid)
ngx.say("<br>your position is ", position)
ngx.say("<br><br>-1 means you must be redirected to egov. otherwise wait and reload the page")
