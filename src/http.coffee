
Robot         = require '../robot'
Adapter       = require '../adapter'
{TextMessage} = require '../message'
crypto = require 'crypto'


newId = (callback) ->
  crypto.randomBytes 30, (e, buf) ->
    if (e)
      callback(e, null)
    callback(null, buf.toString('hex'))
    

class Http extends Adapter
  send: (user, strings...) ->
    messageText = strings.join("\n")
    console.log "reqid #{user.lastRequestId} response"
    
    response = @.responces[user.id][user.lastRequestId]
    delete @.responces[user.id][user.lastRequestId]
    response.writeHead(200, {"Content-Type": "application/json"});
    response.write (JSON.stringify({message:messageText}))
    response.end()

  reply: (user, strings...) ->
    @send user, strings...

 
  run: ->
    self = @
    self.responces = {}
    process.on 'uncaughtException', (err) =>
      @robot.logger.error err.stack
    @robot.connect.use require('connect-requestid')
    @robot.router.post "/hubot/tell", (req, res) =>
      newId (err, id) =>
        user = @userForId '1', name: 'Shell', room: 'Shell'
        user.lastRequestId = id
        messageText = req.body.message
        console.log "reqid #{user.lastRequestId} said #{messageText}"
        self.responces[user.id] ?= {}
        self.responces[user.id][id] = res
        @receive new TextMessage user, messageText
      
      


    self.emit 'connected'


exports.use = (robot) ->
  new Http robot
