_ = require 'lodash'

module.exports = (body, layout, content, options, scripts = [], preloadComponents = []) ->
  clumperEnabled = true

  clumperScript = if clumperEnabled
    "<script src='/clumper.js?include=true&files=#{scripts.join ','}'></script><script>var requirejs = require;</script>"
  else
    ''

  base = "<base href='/'>"
  dom = "<div id='content'>#{body}</div>"

  scriptTags = if clumperEnabled
    ''
  else
    scripts.unshift '/js/require.js'
    _ scripts
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
    #{base}
  </head>
  <body>
  #{dom}
  #{scriptTags}
  <script>
  var layoutComponentPath = '#{layout.pluginName}:#{layout.componentPath}';
  var contentComponentPath = '#{content.pluginName}:#{content.componentPath}';
  var initialProps = #{JSON.stringify options, null, 2};
  var preloadComponents = #{JSON.stringify preloadComponents, null, 2};
  </script>
  <script src='/plugins/kerplunk-server/js/main.js'></script>
  </body>
  </html>"
