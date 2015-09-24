module.exports = (redisClient) ->
  (req, res, next) ->
    if req.isUser
      res.header 'Cache-Control', 'private, no-cache, no-store, must-revalidate'
      res.header 'Expires', '-1'
      res.header 'Pragma', 'no-cache'
      return next()
    return next() if req.session.sessionToken or req.session.noCache
    # console.log 'not user, check for cached copy of', req.url
    redisClient.get req.url, (err, data) ->
      return next err if err
      if data
        # console.log 'send cached copy', req.url
        res.__send data.toString()
      else
        # console.log 'not cached', req.url
        next()
