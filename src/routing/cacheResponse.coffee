module.exports = (redisClient) ->
  (req, res, next) ->
    return next() if req.wasUser or req.isUser or req.method?.toUpperCase?() != 'GET'
    return next() if req.session.sessionToken?.length > 0
    return next() if String(req.session.noCache) == 'true'
    res.__send = res.send
    res.send = (obj) ->
      if /no-cache/i.test res._headers?.pragma or /no-cache/i.test res._headers['cache-control']
        return res.__send obj
      # If payload isn't a string yet, let express pass it back through
      if typeof obj == 'string'
        # console.log 'cache it!', req.url, req.method
        cacheKey = req.url + String(req.cookies?.clumper ? '')
        redisClient.set cacheKey, obj, (err, reply) ->
          throw err if err
          res.__send obj
        redisClient.expire req.url, 60 * 5
      else
        # console.log 'not caching an obj..', req.url
        res.__send obj
    next()
