http = require 'http'
https = require 'https'
_ = require 'lodash'
Promise = require 'when'
express = require 'express'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
methodOverride = require 'method-override'
clumper = require 'clumper'
redis = require 'redis'

renderPageWithComponent = require './render/renderPageWithComponent'
cacheResponse = require './routing/cacheResponse'
requireAuthentication = require './routing/requireAuthentication'
pluginRoutes = require './routing/pluginRoutes'
Authorize = require './routing/authorize'
errorHandler = require './routing/errorHandler'
missingHandler = require './routing/missingHandler'

SetupWebsockets = require './websockets/setup'

module.exports = (System) ->
  app = express()
  server = null
  httpsServer = null
  websockets = null

  {ip, ports} = System.getService 'redis'
  #ip = '192.168.59.104' # tmp because mac->docker = :-3(
  port = ports['6379/tcp']
  redisClient = redis.createClient port, ip
  redisConfig =
    host: ip
    port: port

  addPluginRoutes = pluginRoutes System, redisClient, app

  requirejsPaths = System.getGlobal 'public.requirejs.paths'

  clumper.config.configure
    pathFilter: (pathname) ->
      return requirejsPaths[pathname] if requirejsPaths?[pathname]
      pathname

  Server =
    noRestart: true
    baseDir: System.baseDir
    redisConfig: redisConfig
    getMe: System.getMe

    globals:
      public:
        layout:
          admin: 'kerplunk-server:layout'
          public: 'kerplunk-server:layout'
        requirejs:
          paths:
            react: '/plugins/kerplunk-server/js/react.js'
            lodash: '/plugins/kerplunk-server/js/lodash.min.js'
            'route-matcher': '/plugins/kerplunk-server/js/ba-routematcher.js'
            'reactive-data': '/plugins/kerplunk-server/js/reactive-data.js'
            baconjs: '/plugins/kerplunk-server/js/Bacon'
            when: '/plugins/kerplunk-server/js/when.min.js'
          shim:
            baconjs:
              exports: 'Bacon'
            'route-matcher':
              exports: 'routeMatcher'

    init: (next) ->
      return next() if server?
      credentials = System.getCredentials()

      server = http.createServer app
      if credentials
        httpsServer = https.createServer credentials, app
      else
        httpsServer = null
        console.log 'no credentials provided = no ssl'

      dbPlugin = System.getPlugin 'kerplunk-database'

      websockets = SetupWebsockets System, server, httpsServer
      websockets.primus[0].save "#{System.baseDir}/public/js/primus.js"

      app.use bodyParser.urlencoded extended: true
      app.use bodyParser.json()
      app.use (req, res, next) ->
        res.defaultLayout = if /(^\/admin\/)|(^\/admin$)/.test req.originalUrl
          'admin'
        else
          'public'
        next()
      app.use cookieParser()
      app.use dbPlugin.getSessionMiddleware()
      app.use methodOverride()
      app.use Authorize System
      app.use cacheResponse redisClient
      app.use renderPageWithComponent System
      app.use app.router # cool shit goes here, i hope
      app.use clumper.middleware "#{System.baseDir}/public", {}
      app.use errorHandler()
      app.use express.static "#{System.baseDir}/public"
      app.use missingHandler()
      #]

      next()

    start: ->
      #console.log express.Route
      Server.addRoutes()
      port = process.env.NODE_PORT ? 3000
      server.listen port, ->
        console.log "Server:: Express server listening on port %d in %s mode", port, app.settings.env
      return unless httpsServer
      httpsServer.listen 443, ->
        console.log "Server:: Express HTTPS server listening on port %d in %s mode", 443, app.settings.env

    stop: ->
      Promise websockets.stop()

    reset: ->
      Promise.promise (resolve, reject) ->
        websockets.reset()
        requirejsPaths = System.getGlobal 'public.requirejs.paths'
        app.routes.get.splice 0, app.routes.get.length
        app.routes.post.splice 0, app.routes.post.length
        resolve Server.addRoutes()

    getSocket: (socketName) ->
      websockets.getSocket socketName

    addRoutes: ->
      plugins = System.getPlugins()
      app.get '/admin/globals.json', requireAuthentication, (req, res) ->
        res.send
          public: System.getGlobal 'public'

      app.get '/admin/reboot', requireAuthentication, (req, res) ->
        System.reset()
        .then ->
          redirectUrl = '/admin'
          redirectUrl = req.query.url if req.query.url
          res.redirect redirectUrl

      addPluginRoutes plugins

      for pluginName, plugin of plugins
        websockets.addPluginSockets plugin.plugin

      #console.log 'GLOBALS', globals
      homePage = System.getGlobal 'homePage'

      if homePage?.plugin and homePage.handler
        # console.log 'homePage', homePage
        plugin = System.getPlugin homePage.plugin
        handler = plugin.handlers[homePage.handler]
        if handler
          if typeof handler is 'string'
            handlerString = handler
            handler = (req, res, next) ->
              req.pluginName = homePage.plugin
              res.render handlerString
          app.get '/', (req, res, next) ->
            req.pluginName = homePage.plugin
            handler.call handler, req, res, next
      else
        console.log 'sketchy.. no homePage?'
