module.exports = (System) ->
  auths = {}
  plugins = System.getPlugins()

  for pluginName, plugin of plugins
    auth = plugin.plugin?.auth
    if typeof auth is 'object'
      for name, handler of auth
        # console.log 'introducing auth', name
        auths[name] = handler
  auths
