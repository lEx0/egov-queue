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
Первые 5 сессий (клиенты из разных браузеров - зависит от куки) попадут сразу на egov.
Как только слоты забьются, дальше начнет отображаться заглушка со счетчиком.
Время жизни сессии по-умолчанию - 20 секунд. Все конфиги настраиваются в nginx.conf и описаны выше в разделе `Доступные конфиги`.

#### Схема работы

На старте из конфига берется значение `$queue_max_sessions` и создается global_offset в redis.
Каждая новая сессия получет position из инкрементируемого counter-а в redis и сохраняет uuid в redis с position.
В дальнейшем каждый запрос, на nginx мы видим его позицию, и текущий offset.
Отнимая offset от position, и если значение меньше или равно 0, то у нас есть слоты, если больше мы получаем позицию,
сколько еще сессий перед ним.
При каждом запросе, время жизни сессии в redis увеличивается на значение в конфиге, если сессия истекает global_offset инкрементируеся.
 
