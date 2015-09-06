module.exports = ->
  # 500 page
  (err, req, res, next) ->
    req.pluginName = 'kerplunk-server'
    console.log err.stack
    if req?.params?.format == 'json'
      res.send
        error: '500'
        raw: err
        stack: err.stack
    else
      res.render '500',
        error: err
        stack: err.stack
