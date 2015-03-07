events = require 'events'

IrcConnection = require './connection'
IrcScreen = require './screen'

module.exports = class IrcNetwork extends events.EventEmitter
	constructor: (@name, @connectionOptions, @nickname, @username, @realname) ->
		@screens = {}
		@serverScreen = new IrcScreen @name

	connect: ->
		@connection = new IrcConnection @connectionOptions

		@connection.on 'connect', =>
			console.log 'connected!', @connection.identity
			@register()
		#TODO exponential backoff
		@connection.on 'end', => @connect()

		#@connection.on 'raw', (raw) -> console.log "<- #{raw.trim()}"
		@connection.on 'send', (message) -> console.log "->", message
		@connection.on 'send-raw', (raw) -> console.log "-> #{raw.trim()}"

		@connection.on 'message', (message) =>
			@emit 'message', message

			switch message.command
				when 'RPL_WELCOME'
					@emit 'connect'
				when 'RPL_MOTDSTART', 'RPL_MOTD', 'RPL_ENDOFMOTD'
					@serverScreen.push type: 'motd', message: message.parameters[1]
				when 'JOIN'
					@getScreen(message.parameters[0]).push who: message.prefix, type: 'join'
				when 'RPL_TOPIC'
					screen = @getScreen(message.parameters[0])
					screen.push type: 'topic', topic: message.parameters[1]
					screen.topic = message.parameters[1]
				when 'RPL_NOTOPIC'
					screen = @getScreen(message.parameters[0])
					screen.push type: 'topic', topic: ''
					screen.topic = ''
				when 'PART'
					@getScreen(message.parameters[0]).push who: message.prefix, type: 'part', reason: message.parameters[1]
				#when 'QUIT'
					# this needs to go to all channels that the user is in
				when 'PRIVMSG'
					@getScreen(message.parameters[0]).push who: message.prefix, type: 'message', message: message.parameters[1]
				when 'NOTICE'
					console.log message
					@getScreen(message.parameters[0]).push who: message.prefix, type: 'notice', message: message.parameters[1]
				when 'PING'
					#TODO: no magic numbers
					@connection.sendWithPriority 100, 'PONG', message.parameters[0]
				else
					if message.isNumeric
						@serverScreen.push who: 'server', type: 'numeric', message: "#{message.command} #{message.parameters.join ' '}"
					else
						@serverScreen.push type: 'unknown', message: "#{message.command} #{message.parameters.join ' '}"

		@connection.connect()

	register: ->
		@connection.send 'NICK', @nickname
		@connection.send 'USER', @username, '*', '*', @realname

	getScreen: (key) ->
		@screens[key] ? (@screens[key] = new IrcScreen key)

	join: (channel) ->
		@connection.send 'JOIN', channel

	privmsg: (channel, message) ->
		@getScreen(channel).push who: @nickname, type: 'message', message: message
		@connection.send 'PRIVMSG', channel, message

	quit: (message = '') ->
		@connection.send 'QUIT', message
