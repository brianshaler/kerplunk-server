_ = require 'lodash'
React = require 'react'
routeMatcher = require 'route-matcher'

routeMatcher = routeMatcher.routeMatcher if routeMatcher.routeMatcher

{DOM} = React

defaultTitle = 'Kerplunk'

resolveComponentPath = (componentPath) ->
  return unless componentPath?.indexOf
  index = componentPath.indexOf ':'
  '/plugins' +
  "/#{componentPath.substr 0, index}" +
  '/components' +
  "/#{componentPath.substr index + 1}" +
  if /\.js/.test componentPath
    ''
  else
    '.js'

chopUrl = (url) ->
  String(url).replace /^http[s]?:\/\/[^\/]+\//, '/'

PlaceholderComponent = React.createFactory React.createClass
  render: ->
    DOM.span null, 'loading'

getLinkTags = (arr, key = '') ->
  if typeof arr is 'string'
    arr = [arr]
  _.map arr, (substyle, index) ->

Styles = React.createFactory React.createClass
  customProperty: 'stuff'

  uniquePaths: (names) ->
    _.uniq _.compact _.flatten _.map names, (name) =>
      return null unless @props.css[name]
      isObject = typeof @props.css[name] is 'object'
      isArray = @props.css[name] instanceof Array
      if isObject and !isArray
        _.values @props.css[name]
      else
        @props.css[name]

  render: ->
    {current, all} = @props.getStyles()
    currentNames = ['*'].concat current
    allNames = ['*'].concat all
    currentPaths = @uniquePaths currentNames
    allPaths = @uniquePaths allNames

    DOM.div null, _.map allPaths, (stylePath) ->
      enabled = 0 <= currentPaths.indexOf stylePath
      DOM.link
        key: stylePath
        rel: 'stylesheet'
        href: "/plugins/#{stylePath}"
        disabled: (true if !enabled)

module.exports = React.createFactory React.createClass
  getInitialState: ->
    #refreshState: => @refreshState()
    globals: @props.globals
    currentUrl: @props.currentUrl
    layoutComponent: @props.layoutComponent
    contentComponent: @props.contentComponent
    components: @props.components
    pushState: @pushState
    getSocket: @getSocket
    routes: _.map @props.globals.public.routes, (component, route) ->
      name: route
      matcher: routeMatcher route
      component: component

  navigate: (url) ->
    url = chopUrl url
    # console.log 'navigate', url
    #component = @getRouteComponent url, @props.routes
    #params = @getRouteParams url, @props.routes
    match = _.find @state.routes, (route) ->
      route.matcher.parse url

    return false unless match?.component?.length > 0

    # console.log 'no fetch required; switching to the component', match.component

    changedState =
      currentUrl: url
      contentComponent: match.component
      title: defaultTitle

    state = {}
    state[k] = v for k, v of changedState
    history.pushState state, '', url
    if @state.app?.navActive
      @state.app.navActive = false
      changedState.app = @state.app
    @setState changedState
    true

  pushState: (e, force = false, data) ->
    url = chopUrl e.currentTarget.href
    # console.log 'pushState', url
    try
      navigable = @navigate url
    catch err
      console.log 'error navigating?', err
      return
    if navigable
      e.preventDefault()
      return
    #if force == true
    # console.log 'fetch data to populate component', e
    e.preventDefault()
    @setState
      contentComponent: @props.globals.public.loadingComponent
    return false unless url

    handleData = (data) =>
      historyState = _.extend {}, data.state,
        currentUrl: url
        contentComponent: data.component
      if data.title
        document.title = data.title
        historyState.title = data.title
      history.pushState historyState, url, url
      if data.state.data?[0]?._id
        for item in data.state.data
          @props.Repository.update item._id, item
      newState = _.extend {}, data.state,
        contentComponent: data.component
        currentUrl: url
        title: data.state.title ? defaultTitle
      document.title = newState.title
      # console.log 'data received, show component', newState
      @setState newState

    if data?
      handleData data
      return
    jsonUrl = "#{url}.json"
    @props.request.get jsonUrl, null, (err, data) =>
      if err or !data?.component or !data?.state
        return window.location = url
      handleData data

  sockets: {}
  getSocket: (socketName, obj = {}) ->
    return @sockets[socketName] if @sockets[socketName]?
    params = [
      "name=#{socketName}"
    ]
    for k, v of obj
      params.push "#{k}=#{encodeURIComponent v}"
    @sockets[socketName] = Primus.connect "?#{params.join '&'}"

  componentDidMount: ->
    ignoreProps = [
      'isUser'
      'globals'
      'componentPaths'
      'components'
      'Repository'
      'layoutComponent'
      'contentComponent'
      'System'
      'request'
    ]

    obj =
      contentComponent: @props.contentComponent

    for k, v of @props
      if -1 == ignoreProps.indexOf k
        obj[k] = v

    window.stuff = @
    document.title = @props.title ? defaultTitle
    history.replaceState obj, '', window.location

    unless @props.isUser == false
      # console.log 'isUser', @props.isUser
      @socket = @getSocket 'kerplunk'
      @socket.on 'data', (data) =>
        return unless @isMounted()
        if data.state?
          # console.log 'set state', data.state
          @setState data.state

    window.addEventListener 'popstate', (e) =>
      # console.log 'popstate', history.state
      newState = history.state
      unless newState and Object.keys(newState ? {}).length > 0
        newState = obj
      if newState?.title
        document.title = newState.title
      if newState.data?[0]?._id
        for item in newState.data
          unless @props.Repository.getLatest item._id
            @props.Repository.update item._id, item
      @setState newState

  componentDidUpdate: (prevProps, prevState) ->
    if prevState.currentUrl != @state.currentUrl
      return
      console.log 'was', prevState.currentUrl
      console.log 'now', @state.currentUrl

  refreshState: ->
    url = '/admin/globals.json'
    @props.request.get url, null, (err, newGlobals) =>
      return console.error err if err
      # console.log 'new globals', newGlobals
      rjs1 = @state.globals.public?.requirejs
      rjs2 = newGlobals.public?.requirejs
      if rjs1 and rjs2 and !(_.isEqual rjs1, rjs2)
        requirejs.config rjs2
      @setState
        globals: newGlobals

  getComponent: (c) ->
    if @props.serverGetComponent
      @props.components[c] = @props.serverGetComponent c
    if @props.components[c]? and @props.components[c] != 'loading'
      return @props.components[c]
    if @props.components[c] == 'loading'
      return PlaceholderComponent
    @state.components[c] = 'loading'
    setTimeout =>
      @state.components[c] = 'loading'
      @setState
        components: @state.components
    , 0
    componentPath = resolveComponentPath c
    return PlaceholderComponent unless requirejs?
    requirejs [componentPath], (Component) =>
      return unless @isMounted()
      @state.components[c] = Component
      @setState
        components: @state.components
    # console.log c, '=>', componentPath
    PlaceholderComponent
    #@props.components[c]

  render: ->
    @reportedComponents = {} unless @reportedComponents
    reportedComponents = {}
    obj = _.extend {}, @props, @state,
      refreshState: => @refreshState()
      getComponent: (c) =>
        reportedComponents[c] = true
        @reportedComponents[c] = true
        @getComponent(c)
    obj.globals = @state.globals
    Component = obj.getComponent @state.layoutComponent
    if !Component or !(typeof Component is 'function')
      # console.log 'component not found', @state.layoutComponent
      return DOM.div null, 'wat.. @app'
    DOM.div null,
      Component obj
      Styles
        css: obj.globals.public.css ? {}
        getStyles: =>
          current: Object.keys reportedComponents
          all: Object.keys @reportedComponents
