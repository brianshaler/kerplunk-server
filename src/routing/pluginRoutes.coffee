_ = require 'lodash'

handlerGenerator = require './handlerGenerator'

module.exports = (System, redisClient, app) ->
  (plugins) ->
    generateHandlers = handlerGenerator System, redisClient
    for pluginName, plugin of plugins
      if typeof plugin?.plugin?.routes is 'object'
        for authType, routes of plugin.plugin.routes
          for route, handlerKey of routes
            handlers = generateHandlers pluginName, route, handlerKey, authType
            for method, callbacks of handlers
              # console.log route, callbacks.length, _.map callbacks, (cb) -> typeof cb
              app[method].apply app, callbacks
