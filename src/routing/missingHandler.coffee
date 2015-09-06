module.exports = ->
  # Example 404 page via simple Connect middleware
  (req, res) ->
    req.pluginName = 'kerplunk-server'
    res.statusCode = '404'
    if req.params?.format == 'json'
      res.send error: '404'
    else
      res.render '404'
