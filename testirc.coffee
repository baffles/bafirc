# connect to irc!

IrcNetwork = require './lib/network'

os = require 'os'

###irc = new IrcConnection host: 'chat.freenode.net', port: 6667

irc.connect()

irc.on 'connect', () -> console.log 'connected'
irc.on 'end', () -> console.log 'disconnected'###

irc = new IrcNetwork 'FreeNode', { host: 'chat.freenode.net', port: 6667 }, 'bafirc', 'bafirc', 'bafirc'

irc.connect()

irc.on 'connect', () ->
	irc.join '#bafsoft,#iia'
	#irc.privmsg '#bafsoft', 'I AM THE BEST IN THE WORLD!'

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
