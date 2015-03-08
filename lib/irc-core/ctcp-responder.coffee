###
CTCP handler, to handle responding to CTCP requests in an extensible fashion.

Constructor takes an object whose keys are requests and values are responses.
Response may either be a string (sent as reply data with the same tag), an
object containing tag and optional data fields, or a function returning either
of the two prior options.

Unless overridden, CLIENTINFO responds based on the registered responses. To
disable this behavior without providing any response, set CLIENTINFO to a falsey
value.

Descriptions of the requests may be included for CLIENTINFO responses. To do so,
register an object containing response and description.

e.g.:

new CtcpResponder
	VERSION: 'bafirc'
	FINGER: response: 'bad touch', description: 'FINGER requests are blocked'
	PING: (ts) -> tag: 'PING', data: ts

If more than `maxResponses` requests are found in a single message, an error
reply is made.
###

{ ctcp } = require './message'

module.exports = class CtcpResponder
	constructor: (@responses, @maxResponses=3) ->
		@responses.CLIENTINFO = @responses.CLIENTINFO ?
			description: 'CLIENTINFO with 0 arguments gives a list of known client query keywords. With 1 argument, a description of the client query keyword is returned.'
			response: (tag) =>
				if not tag? or tag.trim().length is 0
					"Supported CTCP commands are: #{Object.keys(@responses).join ' '}"
				else
					@responses[tag]?.description ? "No help available for #{tag}."
	register: (connection) ->
		connection.on 'message', (message) =>
			if message.command is 'PRIVMSG' and message.ctcpParts?
				responses = (@getResponse part for part in message.ctcpParts)
				responses = responses.filter (r) -> !!r
				responses = [ tag: 'ERRMSG', data: "Refusing to respond to more than #{@maxResponses} requests per message" ] if responses.length > @maxResponses
				#TODO: build a single response with multiple parts instead?
				connection.send 'NOTICE', message.prefix.nick, ctcp.ctcp response.tag, response.data for response in responses
	getResponse: (ctcpPart) ->
		response = @responses[ctcpPart.tag] if ctcpPart.tag?
		return if not response
		response = response.response if typeof response is 'object' and response.response?
		response = response(ctcpPart.data) if typeof response is 'function'
		response = tag: ctcpPart.tag, data: response if typeof response is 'string'
		response
