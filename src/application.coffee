express         = require 'express'
morgan          = require 'morgan'
body_parser     = require 'body-parser'
errorhandler    = require 'errorhandler'
http            = require 'http'
path            = require 'path'
SlowController  = require './controllers/slow_controller'

app = express()

app.use morgan 'dev'
app.use body_parser()
app.use express.static path.join(__dirname, '../public')

# development only
app.use errorhandler() if 'development' == app.get('env')

slow_controller = new SlowController
app.get '/:delay', slow_controller.show
app.get '/', (request, response) ->
  response.sendfile path.join(__dirname, '../public/index.html')

server = app.listen 3001, ->
  console.log "Express server listening on port #{server.address().port}"
