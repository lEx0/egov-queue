package main

import (
	"github.com/go-redis/redis"
	"github.com/sirupsen/logrus"
	"os"
	"time"
)

func main() {
	redisAddr := os.Getenv("REDIS_ADDR")
	if len(redisAddr) == 0 {
		redisAddr = "redis:6379"
	}

	c := GetClient(redisAddr)

	logrus.Infoln("Watching expired redis keys")

	// подписываемся на события истекания ключей (=бездействующие пользователи),
	// и удаляем истекшие ключи из очереди
	pubsub := c.Client.Subscribe("__keyevent@0__:expired")
	ch := pubsub.Channel()

	for msg := range ch {
		logrus.Infoln(msg.Channel, msg.Payload)
		c.Client.ZRem("user_queue", msg.Payload)
	}
}

type RedisStorage struct {
	Client *redis.Client
}

func GetClient(addr string) *RedisStorage {
	strg := &RedisStorage{}
	opts := &redis.Options{
		Addr:        addr,
		ReadTimeout: time.Second * 2,
		PoolSize:    20,
	}

	strg.Client = redis.NewClient(opts)

	for {
		_, err := strg.Client.Ping().Result()
		if err != nil {
			logrus.WithError(err).Error("Could not connect to redis")
			time.Sleep(time.Second)
		} else {
			break
		}
	}

	return strg
}
