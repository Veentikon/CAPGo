package main

import (
	"context"
	"log"

	"github.com/redis/go-redis/v9"
)

// Global redis connection
var rd *RedisHandler

// This is the redis handler struct along with its methods that encapsulate redis portion of the application
// There are all the necessary functions to use redis in the scope of a real-time messenger application
type RedisHandler struct {
	ctx    context.Context
	client *redis.Client
}

func newRedisHandler(addr, password string, db int) *RedisHandler {
	ctx := context.Background()
	client := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: password,
		DB:       db,
	})

	return &RedisHandler{
		client: client,
		ctx:    ctx,
	}
}

// ============= Lower level redis functions
func (r *RedisHandler) Set(key string, value interface{}) error {
	return r.client.Set(r.ctx, key, value, 0).Err()
}

func (r *RedisHandler) Get(key string) (string, error) {
	return r.client.Get(r.ctx, key).Result()
}

func (r *RedisHandler) Subscribe(channel string) *redis.PubSub {
	return r.client.Subscribe(r.ctx, channel)
}

func ConnectRedis() error {
	rd = newRedisHandler("redis:6379", "S?sd^l.!23", 0)
	_, err := rd.client.Ping(rd.ctx).Result()
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}
	return err
}
