# IRC Message Parser

Small sub-system to handle parsing of IRC messages, as per RFC-1459.

The actual parser is generated pegjs/pegcoffee, based on the grammar in `irc.pegcoffee`. Messages are parsed into objects such as these:

	{
		prefix: {
			nick: 'TestUser',
			user: 'test',
			host: 'test.com'
		},
		command: 'PRIVMSG',
		parameters: [
			'#channel',
			'hi!'
		]
	}

	{
		prefix: {
			nick: 'some.server.net'
			user: null,
			host: null
		},
		command: 'RPL_WELCOME',
		commandRaw: '001',
		parameters: [
			'yournick',
			'Welcome to the Internet Relay Chat Network yournick'
		]
	}
