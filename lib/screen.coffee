###
A screen instance represents one 'buffer' of view.
It contains rendered messages in a specific context (server, channel, etc.)
###

events = require 'events'

module.exports = class Screen extends events.EventEmitter
	constructor: (@name, @topic='') ->
		@contents = []

	push: (message) ->
		message.time = message.time or Date.now()
		#TODO: sort by time
		@contents.push message
		@emit 'message', message
