tryToServeFromCache = require './tryToServeFromCache'
requireAuthentication = require './requireAuthentication'
authHandlers = require './authHandlers'

module.exports = (System, redisClient) ->
  cacheMiddleware = tryToServeFromCache redisClient
  auths = authHandlers System
  # console.log 'auths', Object.keys auths

  (pluginName, route, handlerKey, authType = 'public') ->
    handler = System.getPlugin(pluginName)?.handlers?[handlerKey]
    return console.log "Apparently #{pluginName} can't handle the #{handlerKey}" unless handler
    if typeof handler is 'string'
      handlerString = handler
      handler = (req, res, next) ->
        res.render handlerString
    return unless typeof handler is 'function'
    routeHandler = (req, res, next) ->
      req.pluginName = pluginName
      # return unless !admin or requireAuthentication req, res, next
      if req.params.format == 'json'
        res.setHeader 'Content-Type', 'text/javascript'
      else if req.params.format == 'rss'
        # res.setHeader 'Content-Type', 'application/xml+rss'
        res.setHeader 'Content-Type', 'text/xml+rss'
      handler req, res, next
    route = "#{route}.:format?" unless /\.[a-z0-9]+$/i.test route

    handlers = {}
    switch authType
      when 'public'
        handlers.post = [route, routeHandler]
        handlers.get = [route, cacheMiddleware, routeHandler]
      when 'admin'
        handlers.post = [route, requireAuthentication, routeHandler]
        handlers.get = [route, requireAuthentication, routeHandler]
      else
        # console.log 'special auth', authType, auths?[authType]?
        handlers.post = [route, auths?[authType]?(), routeHandler]
        handlers.get = [route, auths?[authType]?(), routeHandler]
    handlers
