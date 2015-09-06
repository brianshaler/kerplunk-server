{EventEmitter} = require 'events'

_ = require 'lodash'

Primus = require './primus'

module.exports = (System, server, httpsServer, redisConfig) ->
  primii = [Primus System, server, redisConfig]
  if httpsServer
    primii.push Primus System, httpsServer, redisConfig

  sockets = {}

  for primus in primii
    primus.on 'connection', (spark) ->
      unless spark.request.isUser or /^public-/.test spark.query?.name
        return spark.write lol: 'nope'

      for socketName, socket of sockets
        socket.primus = primus
        if spark.query?.name == socket.name
          #console.log "connecting spark #{spark.id} to #{socket.name}"
          socket.emit 'connection', spark

  defaultSocketListener = (socket) ->
    (spark) ->
      onSocketData = (data) ->
        if data?._condition
          return unless data._condition(spark) == true
          return spark.write data._data
        spark.write data
      #console.log 'server: connection', spark
      spark.on 'data', (data) ->
        #console.log 'emitting receive on socket', socket.name
        socket.emit 'receive', spark, data
      socket.on 'broadcast', onSocketData
      spark.on 'end', ->
        socket.removeListener 'data', onSocketData
        socket.removeListener 'broadcast', onSocketData

  getSocket = (socketName) ->
    return sockets[socketName] if sockets[socketName]
    socket = new EventEmitter()
    socket.name = socketName
    socket.on 'connection', defaultSocketListener socket
    socket.broadcast = (data) -> socket.emit 'broadcast', data
    sockets[socketName] = socket

  stop = ->
    for socketName, socket of sockets
      socket.removeAllListeners()

  reset = ->
    for socketName, socket of sockets
      socket.on 'connection', defaultSocketListener socket

  primus: primii
  getSocket: (socketName) ->
    getSocket socketName
  addPluginSockets: (plugin) ->
    for socketName in (plugin.sockets ? [])
      getSocket socketName
  stop: -> stop()
  reset: -> reset()
