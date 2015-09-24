crypto = require 'crypto'

module.exports = (System) ->
  (req, res, next) ->
    req.isUser = req.wasUser = false
    return next() unless req.session.sessionKey
    System.getSettings (err, settings) ->
      return next() if err or !settings?.sessionKey
      return next() unless settings.sessionKey == req.session.sessionKey
      correctToken = crypto.createHash 'sha1'
        .update "#{req.session.userName}|#{req.session.sessionKey}"
        .digest 'hex'
      return next() unless req.session.sessionToken == correctToken
      req.wasUser = req.isUser = true
      settings.lastActivity = new Date()
      System.updateSettings
        $set:
          lastActivity: settings.lastActivity
      , (err) ->
        next()
