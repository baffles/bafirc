PEG = require 'pegjs'
pegcoffee = require 'pegcoffee'

fs = require 'fs'
path = require 'path'

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
		parsed
