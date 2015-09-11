crypto = require 'crypto'

module.exports = (System) ->
  (req, res, next) ->
    req.isUser = req.wasUser = false
    if req.session.sessionKey
      System.getSettings (err, s) ->
        if !err && s
          if s.sessionKey && s.sessionKey == req.session.sessionKey
            correctToken = crypto.createHash 'sha1'
              .update "#{req.session.userName}|#{req.session.sessionKey}"
              .digest 'hex'
            if req.session.sessionToken == correctToken
              req.wasUser = req.isUser = true
              s.lastActivity = new Date()
              System.updateSettings {$set: {lastActivity: new Date()}}, (err) ->
                next()
              return
        next()
    else
      next()
