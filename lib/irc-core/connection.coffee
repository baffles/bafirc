###
Simple IRC connection layer.
###

{parser, defaultPrioritizer} = require './message'
SendQueue = require './send-queue'

net = require 'net'
carrier = require 'carrier'

events = require 'events'

module.exports = class IrcConnection extends events.EventEmitter
	constructor: (@options) ->
		@queue = new SendQueue
		@prioritizer = @options.prioritizer or defaultPrioritizer

	connect: ->
		#TODO: SSL support
		@connection = net.createConnection host: @options.host, port: @options.port
		@lastActive = Date.now()
		@connection.on 'connect', =>
			@identity = family: @connection.remoteFamily, remoteAddress: @connection.remoteAddress, remotePort: @connection.remotePort, localAddress: @connection.localAddress, localPort: @connection.localPort
			@emit 'connect'
		@connection.on 'error', (error) -> # log? no-op for now, close will be emitted right after
		@connection.on 'close', (isError) => @emit 'close', isError

		@carrier = carrier.carry @connection
		@carrier.on 'line', (line) =>
			@lastActive = Date.now()
			@emit 'raw', line
			@emit 'message', parser.parse line

		@queue.on 'send', (message) =>
			try
				@emit 'send', parser.parse message
			catch
			@emit 'send-raw', message
			@connection.write message

	disconnect: -> @connection.end()

	flushQueue: -> @queue.flush()
	queueStats: -> @queue.stats()

	stats: -> received: @connection.bytesRead, sent: @connection.bytesWritten

	sendWithPriority: (priority, command, params...) =>
		if typeof command is 'object'
			# handle IRC message objects
			params = command.parameters
			command = command.command

		msg = command

		[params..., lastParam] = params

		msg += " #{param}" for param in params

		switch
			when (lastParam?.indexOf ' ') >= 0 or lastParam?[0] is ':'
				msg += " :#{lastParam}"
			when lastParam?
				msg += " #{lastParam}"

		@sendRaw msg, priority

	send: (command, params...) ->
		priority = @prioritizer command, params...
		@sendWithPriority priority, command, params...

	sendRaw: (message, priority=0) ->
		message = "#{message}\r\n"
		@queue.send message, priority
