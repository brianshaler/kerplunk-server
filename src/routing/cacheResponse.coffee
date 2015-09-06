module.exports = (redisClient) ->
  (req, res, next) ->
    return next() if req.wasUser or req.isUser or req.method?.toUpperCase?() != 'GET'
    res.__send = res.send
    res.send = (obj) ->
      if /no-cache/i.test res._headers?.pragma or /no-cache/i.test res._headers['cache-control']
        return res.__send obj
      # If payload isn't a string yet, let express pass it back through
      if typeof obj == 'string'
        # console.log 'cache it!', req.url, req.method
        redisClient.set req.url, obj, (err, reply) ->
          throw err if err
          res.__send obj
        redisClient.expire req.url, 60 * 5
      else
        # console.log 'not caching an obj..', req.url
        res.__send obj
    next()
