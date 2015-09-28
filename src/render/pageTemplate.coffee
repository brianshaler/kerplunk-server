_ = require 'lodash'

module.exports = (body, layout, content, options, scripts = [], preloadComponents = [], injectedScripts = '') ->
  clumperEnabled = process.env.NODE_ENV != 'dev'

  clumperScript = if clumperEnabled
    # &files=#{scripts.join ','}
    "<script src='/clumper.js?include=true'></script><script>var requirejs = require;</script>"
  else
    ''

  base = "<base href='/'>"
  dom = "<div id='content'>#{body}</div>"

  unless clumperEnabled
    scripts.unshift '/js/require.js'
  scriptTags = _ scripts
    .map (script) ->
      "<script src='#{script}'></script>"
    .value()
    .join '\n    '

  "<!DOCTYPE html>
  <html>
  <head>
    <title>#{options.title ? ''}</title>
    <meta charset='UTF-8'>
    <meta content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' name='viewport'>
    <script src='/js/primus.js'></script>
    #{clumperScript}
    <script>
    var layoutComponentPath = '#{layout.pluginName}:#{layout.componentPath}';
    var contentComponentPath = '#{content.pluginName}:#{content.componentPath}';
    var initialProps = #{JSON.stringify options};
    var preloadComponents = #{JSON.stringify preloadComponents};
    </script>
    <script>console.log('page', new Date());</script>
    <script>#{injectedScripts}</script>
    <script src='/plugins/kerplunk-server/js/main.js'></script>
    #{base}
  </head>
  <body>
  #{dom}
  #{scriptTags}
  <script>KerplunkInit();</script>
  </body>
  </html>"
