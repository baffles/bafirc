parser = require './parser'
SendQueue = require './sendqueue'

net = require 'net'
carrier = require 'carrier'

events = require 'events'

module.exports = class IrcConnection extends events.EventEmitter
	constructor: (@options) ->
		@queue = new SendQueue

	connect: ->
		@connection = net.createConnection host: @options.host, port: @options.port
		@connection.on 'connect', =>
			@identity = family: @connection.remoteFamily, remoteAddress: @connection.remoteAddress, remotePort: @connection.remotePort, localAddress: @connection.localAddress, localPort: @connection.localPort
			@emit 'connect'
		@connection.on 'close', (isError) => @emit 'close', isError

		@carrier = carrier.carry @connection
		@carrier.on 'line', (line) =>
			@emit 'raw', line
			@emit 'message', parser.parse line

		@queue.on 'send', (message) =>
			try
				@emit 'send', parser.parse message
			catch
			@emit 'send-raw', message
			@connection.write message

	kill: -> @connection.end()

	flushQueue: -> @queue.flush()
	queueStats: -> @queue.stats()

	stats: -> received: @connection.bytesRead, sent: @connection.bytesWritten

	sendWithPriority: (priority, command, params...) =>
		msg = command

		[params..., lastParam] = params

		msg += " #{param}" for param in params

		switch
			when (lastParam?.indexOf ' ') >= 0
				msg += " :#{lastParam}"
			when lastParam?
				msg += " #{lastParam}"

		@sendRaw msg, priority

	send: (command, params...) -> @sendWithPriority 0, command, params...

	sendRaw: (message, priority=0) ->
		message = "#{message}\r\n"
		@queue.send message, priority
