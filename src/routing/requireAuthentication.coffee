querystring = require 'querystring'

module.exports = (req, res, next) ->
  return next() if req.isUser == true
  if req.params.format == 'json'
    res.send
      error: 'permission_denied'
  else
    res.redirect "/admin/login?#{querystring.stringify redirectUrl: req.url}"
