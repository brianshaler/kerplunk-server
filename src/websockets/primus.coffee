Primus = require 'primus'
primusRedisRooms = require 'primus-redis-rooms'

Authorize = require '../routing/authorize'
Rooms = require './rooms'

module.exports = (System, server, redisConfig) ->
  dbPlugin = System.getPlugin 'kerplunk-database'
  sessionMiddleware = dbPlugin.getSessionMiddleware()
  authorize = Authorize System

  {ip, ports} = System.getService 'redis'
  port = ports['6379/tcp']

  primusOpt =
    transformer: 'websockets'
    pathname: '/admin/socket'
    redis:
      host: ip
      port: port

  primus = new Primus server, primusOpt

  primus.use 'redis', primusRedisRooms
  primus.before 'session', -> sessionMiddleware
  primus.before 'authorize', -> authorize

  Rooms System, primus
  primus
