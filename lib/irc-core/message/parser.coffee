###
The actual IRC parser itself. Uses a parser generated by pegjs/pegcoffee.
###

PEG = require 'pegjs'
pegcoffee = require 'pegcoffee'

fs = require 'fs'
path = require 'path'

ctcp = require './ctcp'
numerics = require './numerics'

parser = do ->
	grammarFile = path.join __dirname, 'irc.pegcoffee'
	grammar = fs.readFileSync grammarFile, 'utf8'
	PEG.buildParser grammar, plugins: [ pegcoffee ]

module.exports =
	parse: (message) ->
		parsed = parser.parse message
		numeric = numerics[parsed.command]
		if numeric?
			parsed.isNumeric = true
			parsed.commandRaw = parsed.command
			parsed.command = numeric
		if parsed.command is 'PRIVMSG' or parsed.command is 'NOTICE'
			# handle CTCP items
			parsed.ctcpParts = ctcp.parse parsed.parameters[1]
		parsed
