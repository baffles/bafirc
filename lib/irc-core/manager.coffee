###
Manages a persistent IRC connection to a server.
Handles reconnecting on disconnect, registration, etc.
###

events = require 'events'
backoff = require 'backoff'

IrcConnection = require './connection'
NicknameGenerator = (require './nickname-strategy').generator

module.exports = class IrcConnectionManager extends events.EventEmitter
	constructor: (options={}) -> #@name, @connectionOptions, @nickname, @username, @realname) ->
		@name = options.name ? ''
		@userInfo = options['user']
		@userInfo.username = @userInfo.username ? 'bafirc'
		@userInfo.realName = @userInfo.realName ? 'bafirc'
		@nicknameStrategy = options['nickStrategy'] ? new NicknameGenerator @userInfo.nickname
		#TODO: SSL support
		@serverInfo = options['server']
		@serverInfo.port = @serverInfo.port ? 6667
		@backoff = options['backoff'] or backoff.fibonacci randomisationFactor: 0, initialDelay: 2000, maxDelay: 30000

		@backoff.on 'backoff', (attempt, delay) => @emit 'reconnect-wait', { attempt, delay }
		@backoff.on 'ready', (attempt, delay) => @connect()
		@backoff.on 'fail', =>
			@reconnect = false
			@emit 'end'

	connect: ->
		return if @connection?

		registered = false
		@connection = connection = new IrcConnection host: @serverInfo.host, port: @serverInfo.port
		@reconnect = true

		connection.on 'connect', =>
			@emit 'connect'
			@backoff.reset()
			@register()
		connection.on 'close', (wasError) =>
			@emit 'disconnect', wasError
			delete @connection
			if @reconnect
				@backoff.backoff()
			else
				@emit 'end'

		connection.on 'message', (message) =>
			@emit 'message', message

			switch message.command
				when 'RPL_WELCOME'
					registered = true
					@emit 'registered'
				when 'NICK'
					@currentNick = message.parameters[0] if message.prefix.nick.toLowerCase() is @currentNick.toLowerCase()
					@nicknameStrategy.set @currentNick
				when 'ERR_ERRONEUSNICKNAME', 'ERR_NICKNAMEINUSE'
					if not registered
						if not @cycleNick()
							@disconnect 'no nickname'
				when 'PING'
					connection.send 'PONG', message.parameters[0]

		connection.connect()

	disconnect: (reason) ->
		return if not @connection?
		@reconnect = false
		@connection.send 'QUIT', reason ? ''

	register: ->
		@nicknameStrategy.reset()
		@currentNick = @nicknameStrategy.nick

		@connection.send 'PASS', @serverInfo.password if @serverInfo.password?
		@connection.send 'NICK', @currentNick
		@connection.send 'USER', @userInfo.username, @userInfo.userMode ? '*', '*', @userInfo.realName

	cycleNick: ->
		if @nicknameStrategy.next()
			@currentNick = @nicknameStrategy.nick
			@connection.send 'NICK', @currentNick
			true
		else
			false
