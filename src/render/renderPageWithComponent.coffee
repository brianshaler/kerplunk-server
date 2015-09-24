_ = require 'lodash'
path = require 'path'
url = require 'url'
React = require 'react'
ReactiveData = require 'reactive-data'

pageTemplate = require './pageTemplate'

module.exports = (System) ->
  (req, res, next) ->
    res.__render = res.render
    res.render = (componentPath, options = {}) ->
      defaults =
        isUser: req.isUser
      options = _.extend defaults, req.session, options
      unless options.isUser?
        options.isUser = req.isUser
      if /:/.test componentPath
        [pluginName, componentPath] = componentPath.split ':'
      else
        pluginName = req.pluginName
      if req.params?.format == 'json'
        res.send
          state: options
          component: "#{pluginName}:#{componentPath}"
        return
      layoutName = res.defaultLayout
      if options?.layout
        layoutName = options.layout
      pattern = /^([a-z0-9\-]+):(.+)$/i
      if pattern.test layoutName
        [match, layoutPlugin, layoutPath] = pattern.exec layoutName
      else
        layoutName = "public.layout.#{layoutName}"
        if !System.getGlobal(layoutName)
          console.log 'no global?', layoutName, System.getGlobal(layoutName)
        [layoutPlugin, layoutPath] = System.getGlobal(layoutName).split ':'

      layout =
        pluginName: layoutPlugin
        componentPath: layoutPath

      content =
        pluginName: pluginName
        componentPath: componentPath

      AppComponent = System.getComponent 'kerplunk-server:app'

      options.currentUrl = url.parse req.originalUrl
        .pathname
      #console.log 'options.currentUrl', options.currentUrl
      options.globals =
        public: System.getGlobal 'public'
      options.componentPaths = System.getComponentPaths()
      options.components = {}
      # for componentPath in options.componentPaths
      #   options.components[componentPath] = System.getComponent componentPath
      options.Repository = Repository = ReactiveData.generateRepository()
      if options.data?.length > 0
        for item in options.data
          if item?._id
            Repository.update item._id, item

      loadedComponents = []
      appComponent = new AppComponent _.extend {}, options,
        layoutComponent: "#{layout.pluginName}:#{layout.componentPath}"
        contentComponent: "#{content.pluginName}:#{content.componentPath}"
        serverGetComponent: (componentPath) ->
          loadedComponents.push componentPath
          System.getComponent componentPath
      renderedPage = React.renderToString appComponent
      preloadComponents = _.uniq loadedComponents

      scripts = []
      LayoutComponent = System.getComponent "#{layout.pluginName}:#{layout.componentPath}"
      if LayoutComponent?.scripts?.length > 0
        for script in LayoutComponent.scripts
          scripts.push script
      res.send pageTemplate renderedPage, layout, content, options, scripts, preloadComponents
    next()
