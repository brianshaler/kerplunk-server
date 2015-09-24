_ = require 'lodash'

module.exports = (System, primus) ->
  getID = (spark) ->
    id = (spark.request.sessionID ? 'Anon').substring 0, 4
    if spark.request.friendDomain
      id = spark.request.friendDomain
    if spark.request.session?.friendDomain
      id = spark.request.session.friendDomain
    if spark.request.isUser
      me = System.getMe()
      displayNames = []
      if me?.data
        for platform, profile of me.data
          displayNames.push profile.nickname ? profile.fullName
      # console.log 'displayNames', displayNames
      displayName = null
      for n in displayNames
        displayName = n if n and (!displayName? or n?.length > displayName.length)
      id = displayName if displayName
    id

  isInRoom = (spark, room) ->
    return false unless spark?._rooms and room
    !!(_.find spark._rooms, (r) -> r.name == room)

  sendToRoom = (spark, room, msg) ->
    id = getID spark
    # console.log "primus.room(#{room}).write(#{msg})", id
    primus.room(room).write
      room: room
      msg: msg
      id: id
      t: Date.now()

  announceToRoom = (room, msg) ->
    data =
      room: room
      msg: msg
      t: Date.now()
    # console.log "primus.room(#{room}).write(#{JSON.stringify data})"
    primus.room(room).write data

  announceToSpark = (spark, room, msg) ->
    data =
      room: room
      msg: msg
      t: Date.now()
    spark.write data

  primus.on 'disconnection', (spark) ->
    return unless spark._rooms?.length > 0
    rooms = _.pluck spark._rooms, 'name'
    for room in rooms
      announceToRoom room, "#{getID spark} left the room #{room}"
    # console.log 'disconnection', _.pluck spark._rooms, 'name'

  primus.on 'connection', (spark) ->
    return spark.write lol: 'nope' unless spark.request.isUser or /^public-/.test spark.query?.name
    spark.sendToRoom = (room, msg) ->
      sendToRoom spark, room, msg
    spark.__primus = primus

    spark.on 'data', (data = {}) ->
      # console.log 'server checking room/action', data?.action ? data
      return unless data.room?
      {room} = data
      action = data.action
      msg = data.msg

      # // join a room
      if action is 'join'
        # console.log 'join room', room
        return if isInRoom spark, room

        spark.join room

        # // send message to all clients except this one
        announceToRoom room, "#{getID spark} joined room #{room}"
        # // send message to this client
        announceToSpark spark, room, "you (#{getID spark}) joined room #{room}"
        return

      # // leave a room
      if action is 'leave'
        # console.log 'leave room', room
        spark.leave room
        # // send message to this client
        spark.write
          room: room
          msg: "you left room #{room}"
        return

      if msg
        # console.log 'sending', msg, 'to', room
        # // check if spark is already in this room
        spark.join room unless isInRoom spark, room
        sendToRoom spark, room, msg
        return
        # return sendToRoom spark, room, msg
