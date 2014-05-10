_ = require 'underscore'

class SlowController
  show: (request, response) =>
    delay = parseInt request.params.delay

    _.delay =>
      response.send status: 'success', delay: delay
    , delay

module.exports = SlowController
