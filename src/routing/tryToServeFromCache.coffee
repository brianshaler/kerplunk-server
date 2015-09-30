module.exports = (redisClient) ->
  (req, res, next) ->
    if req.isUser
      res.header 'Cache-Control', 'private, no-cache, no-store, must-revalidate'
      res.header 'Expires', '-1'
      res.header 'Pragma', 'no-cache'
      return next()
    return next() if req.session.sessionToken?.length > 0
    return next() if String(req.session.noCache) == 'true'
    # console.log 'not user, check for cached copy of', req.url
    cacheKey = req.url + String(req.cookies?.clumper ? '')
    redisClient.get cacheKey, (err, data) ->
      return next err if err
      if data
        # console.log 'send cached copy', req.url
        res.__send data.toString()
      else
        # console.log 'not cached', req.url
        next()
