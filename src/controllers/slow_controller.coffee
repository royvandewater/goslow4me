_ = require 'underscore'

class SlowController
  show: (request, response) =>
    delay = parseInt request.params.delay

    _.delay =>
      response.send status: 'success', delay: delay, params: request.params, body: request.body, query: request.query
    , delay

module.exports = SlowController
