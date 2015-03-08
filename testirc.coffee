# connect to irc!

IrcConnectionManager = require './lib/irc-core/manager'

{ ctcp } = require './lib/irc-core/message'
CtcpResponder = require './lib/irc-core/ctcp-responder'

os = require 'os'

ctcpResponder = new CtcpResponder
	FINGER: 'BAFIRC, idle FOREVER!'
	VERSION: 'bafirc v0.0.0'
	SOURCE: 'https://github.com/baffles/bafirc'
	USERINFO: 'I AM AWESOME'
	PING: (ts) -> ts
	TIME: -> Date.now().toString()

irc = new IrcConnectionManager
	name: 'FreeNode'
	user:
		nickname: 'bafirc'
		user: 'bafirc'
		realName: 'lol'
	server:
		host: 'chat.freenode.net'

irc.on 'connect', ->
	console.log 'connected!'
	ctcpResponder.register irc.connection
	irc.connection.on 'send-raw', (raw) -> console.log "-> #{raw.trim()}"
	irc.connection.on 'raw', (raw) -> console.log "<- #{raw.trim()}"
irc.on 'disconnect', -> console.log 'disconnected...'
irc.on 'reconnect-wait', (wait) -> console.log "waiting #{wait.delay}ms to reconnect..."
irc.on 'end', -> console.log 'connection keepalive ended'

irc.on 'registered', () ->
	#irc.join '#bafsoft,#iia'
	#irc.privmsg '#bafsoft', 'I AM THE BEST IN THE WORLD!'
	irc.connection.send 'JOIN', '#bafsoft,#iia'

###irc.on 'message', (message) ->
	if message.command is 'PRIVMSG' and message.ctcpParts?
		for part in message.ctcpParts
			switch part.tag
				when 'VERSION'
					irc.connection.send 'NOTICE', message.prefix.nick, ctcp.ctcp 'VERSION', 'bafirc (pwns)'
				when 'PING'
					irc.connection.send 'NOTICE', message.prefix.nick, ctcp.ctcp 'PING', part.data###

irc.on 'message', (message) ->
	if message.command is 'PRIVMSG'
		dest = message.parameters[0]
		text = message.parameters[1]
		switch
			when (text.indexOf 'fuck you') >= 0
				irc.connection.send 'PRIVMSG', dest, 'fuck you too'
			when text is '!quit'
				irc.connection.send 'QUIT', 'bye'
			when (text.substring 0, 6) is '!echo '
				irc.connection.sendRaw text.substring 6
			when text is '!mem'
				mem = process.memoryUsage()
				irc.connection.send 'PRIVMSG', dest, "I'm using #{bytesToSize mem.rss} of memory! Google V8's heap is #{bytesToSize mem.heapUsed} used / #{bytesToSize mem.heapTotal} total"
			when text is '!sysinfo'
				info = "PID #{process.pid} (#{process.title}) - running on #{process.platform} on #{process.arch}. Up for #{process.uptime()}s."
				irc.connection.send 'PRIVMSG', dest, info
				info = "System up for #{os.uptime()}s. Memory #{bytesToSize os.freemem()} free / #{bytesToSize os.totalmem()}. #{os.cpus().length} CPUs / #{os.networkInterfaces().length} network interfaces."
				irc.connection.send 'PRIVMSG', dest, info
			when text is '!flood'
				irc.connection.send 'PRIVMSG', dest, "#{i}" for i in [1..20]
			when text is '!flushq'
				irc.connection.flushQueue()
			when text is '!queue'
				irc.connection.sendWithPriority 100, 'PRIVMSG', dest, JSON.stringify irc.connection.queueStats()
				#irc.privmsg dest, JSON.stringify irc.queueStats()
			when text is '!conn'
				irc.connection.send 'PRIVMSG', dest, "Connected to #{irc.connection.identity.remoteAddress}:#{irc.connection.identity.remotePort}"
				stats = irc.connection.stats()
				irc.connection.send 'PRIVMSG', dest, "Sent #{bytesToSize stats.sent}; received #{bytesToSize stats.received}"

irc.connect()

###
irc.serverScreen.on 'message', (message) ->
	console.log "[server #{message.type}] #{if message.who? then "<#{message.who.nick}> " else ""}#{message.message}"

for chan in [ '#bafsoft', '#iia' ]
	do (chan) ->
		irc.getScreen(chan).on 'message', (message) ->
			switch message.type
				when 'join'
					console.log "[#{chan} join] --> #{message.who.nick} (#{message.who.user}@#{message.who.host}) has joined #{chan}"
				when 'part'
					console.log "[#{chan} join] <-- #{message.who.nick} (#{message.who.user}@#{message.who.host}) has left #{chan}#{if message.reason? then " #{message.reason}" else ''}"
				else
					console.log "[#{chan} #{message.type}] #{if message.who? then "<#{message.who.nick}> " else ""}#{message.message}"

			if message.type is 'message'
				dest = chan
				text = message.message
				switch
					when (text.indexOf 'fuck you') >= 0
						irc.privmsg dest, 'fuck you too'
					when text is '!quit'
						irc.quit 'bye'
					when (text.substring 0, 6) is '!echo '
						irc.connection.sendRaw text.substring 6
					when text is '!mem'
						mem = process.memoryUsage()
						irc.privmsg dest, "I'm using #{bytesToSize mem.rss} of memory! Google V8's heap is #{bytesToSize mem.heapUsed} used / #{bytesToSize mem.heapTotal} total"
					when text is '!sysinfo'
						info = "PID #{process.pid} (#{process.title}) - running on #{process.platform} on #{process.arch}. Up for #{process.uptime()}s."
						irc.privmsg dest, info
						info = "System up for #{os.uptime()}s. Memory #{bytesToSize os.freemem()} free / #{bytesToSize os.totalmem()}. #{os.cpus().length} CPUs / #{os.networkInterfaces().length} network interfaces."
						irc.privmsg dest, info
					when text is '!flood'
						irc.privmsg dest, "#{i}" for i in [1..20]
					when text is '!flushq'
						irc.flushQueue()
					when text is '!queue'
						irc.connection.sendWithPriority 100, 'PRIVMSG', dest, JSON.stringify irc.connection.queueStats()
						#irc.privmsg dest, JSON.stringify irc.queueStats()
					when text is '!conn'
						irc.privmsg dest, "Connected to #{irc.connection.identity.remoteAddress}:#{irc.connection.identity.remotePort}"
						stats = irc.connection.stats()
						irc.privmsg dest, "Sent #{bytesToSize stats.sent}; received #{bytesToSize stats.received}"

irc.connect()
###

bytesToSize = `function (bytes) {
   var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
   if (bytes == 0) return '0 Byte';
   var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
   return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
}`

###

irc.on 'message', (message) ->
	#console.log message

	switch
		when message.command is 'RPL_WELCOME'
			console.log 'I am on IRC!'
		when message.command is 'PRIVMSG'
			dest = message.parameters[0]
			text = message.parameters[1]
			switch
				when (text.indexOf 'fuck you') >= 0
					irc.send 'PRIVMSG', dest, 'fuck you too'
				when text is '!quit'
					irc.send 'QUIT', 'bye'
				when (text.substring 0, 6) is '!echo '
					irc.sendRaw text.substring 6
				when text is '!mem'
					mem = process.memoryUsage()
					irc.send 'PRIVMSG', dest, "I'm using #{bytesToSize mem.rss} of memory! Google V8's heap is #{bytesToSize mem.heapUsed} used / #{bytesToSize mem.heapTotal} total"
				when text is '!sysinfo'
					info = "PID #{process.pid} (#{process.title}) - running on #{process.platform} on #{process.arch}. Up for #{process.uptime()}s."
					irc.send 'PRIVMSG', dest, info
					info = "System up for #{os.uptime()}s. Memory #{bytesToSize os.freemem()} free / #{bytesToSize os.totalmem()}. #{os.cpus().length} CPUs / #{os.networkInterfaces().length} network interfaces."
					irc.send 'PRIVMSG', dest, info
				when text is '!flood'
					irc.send 'PRIVMSG', dest, "#{i}" for i in [1..20]
				when text is '!flushq'
					irc.flushQueue()
				when text is '!queue'
					irc.sendWithPriority 100, 'PRIVMSG', dest, JSON.stringify irc.queueStats()
		when message.command is 'PING'
			irc.send 'PONG', message.parameters[0]
###

#irc.on 'raw', (raw) -> console.log "<- #{raw.trim()}"
#irc.on 'send', (raw) -> console.log "-> #{raw.trim()}"

#irc.send 'NICK', 'bafirc'
#irc.send 'USER', 'bafirc', '*', '*', 'bafirc'
#irc.send 'JOIN', '#iia,#bafsoft'
#irc.send 'PRIVMSG #iia :Sevalecan SUCKS and so does NubSaybit'
