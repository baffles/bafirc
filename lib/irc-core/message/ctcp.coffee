###
An implementation of the client-to-client protocol
###

PEG = require 'pegjs'
pegcoffee = require 'pegcoffee'

fs = require 'fs'
path = require 'path'

parser = do ->
	grammarFile = path.join __dirname, 'ctcp.pegcoffee'
	grammar = fs.readFileSync grammarFile, 'utf8'
	PEG.buildParser grammar, plugins: [ pegcoffee ]

# low-level quoting
# M-QUOTE is octal 20 (hex 10)
lowDequote = (message) ->
	# dequote specials according to spec
	# M-QUOTE 0 -> \0
	# M-QUOTE n -> \n
	# M-QUOTE r -> \r
	# M-QUOTE M-QUOTE -> M-QUOTE
	# else drop the M-QUOTE
	message.replace /\x10(.?)/g, (sequence, op) ->
		switch op
			when '0' then '\0'
			when 'n' then '\n'
			when 'r' then '\r'
			when '\x10' then '\x10'
			else op

lowQuote = (message) ->
	# M-QUOTE all M-QUOTEs, \0, \r, and \n in the message
	message.replace /([\0\n\r\x10])/g, (escapee, char) ->
		switch char
			when '\0' then '\x100'
			when '\n' then '\x10n'
			when '\r' then '\x10r'
			when '\x10' then '\x10\x10'

# ctcp-level quoting
# X-QUOTE is octal 134 (hex 5c, aka '\')
ctcpDequote = (message) ->
	# dequote according to spec
	# X-QUOTE a -> X-DELIM
	# X-QUOTE X-QUOTE -> X-QUOTE
	# else drop the X-QUOTE
	message.replace /\x5c(.?)/g, (sequence, op) ->
		switch op
			when 'a' then '\x01'
			when '\x5c' then '\x5c'
			else op

ctcpQuote = (message) ->
	# X-QUOTE all X-QUOTEs and X-DELIMs
	message.replace /([\x5c\x01])/g, (escapee, char) ->
		switch char
			when '\x01' then '\x5ca'
			when '\x5c' then '\x5c\x5c'

ctcpExtract = (message) ->
	parts = parser.parse lowDequote message
	parts.map (part) ->
		if typeof part is 'object'
			part.tag = ctcpDequote part.tag
			part.data = ctcpDequote part.data if part.data?
			part
		else
			ctcpDequote part

ctcpEncode = (parts) ->
	parts = [parts] if not Array.isArray parts
	message = ''
	for part in parts
		if typeof part is 'object' and part.tag?
			ctcp = part.tag
			ctcp += ' ' + part.data if part.data?
			message += "\x01#{ctcpQuote ctcp}\x01"
		else
			part = part.toString() if typeof part isnt 'string'
			message += ctcpQuote part
	lowQuote message

module.exports =
	parse: ctcpExtract
	encode: ctcpEncode
	ctcp: (tag, data) -> ctcpEncode { tag, data }
