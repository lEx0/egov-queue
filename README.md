## Очередь с получением номера

#### Requirements
 - Openresty или nginx с luajit
 - Redis 

#### Доступные конфиги
 - `$queue_session_lifetime` - время жизни сессии в сек
 - `$queue_max_sessions` - количество максимальных сессий
 - `$queue_redis_timeout` - timeout к redis
 - `$queue_redis_host` - hostname или ip к redis
 - `$queue_redis_port` - port у redis
 - `$queue_cookie_name` - название куки 

#### QuickStart
##### Dev requirements:
- docker
- docker-compose

##### Запуск
`docker-compose up`

#### Проверка
Открываем localhost:9191.
Первые 5 сессий (зависит от куки), попадут сразу на egov.
Как только слоты забьются, дальше начнет отображаться заглушка со счетчиком.
Время жизни сесси 20 сек, все конфигы настраиваются в nginx.conf и выставлны выше в разделе `Доступные конфиги`.
