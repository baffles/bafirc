should = require 'should'

parser = require '../lib/parser'

describe 'parser', ->
	describe '#parse', ->
		it 'should properly parse message suffixes', ->
			nickOnly = parser.parse ':some.server COMMAND p1 p2 :p3'
			nickOnly.prefix.should.have.properties nick: 'some.server', user: null, host: null

			fullPrefix = parser.parse ':nick!user@host COMMAND p1'
			fullPrefix.prefix.should.have.properties nick: 'nick', user: 'user', host: 'host'

		it 'should handle FreeNode-style cloaked hostnames', ->
			cloaked = parser.parse ':nick!user@some/cloaked/hostmask COMMAND param'
			cloaked.prefix.should.have.property 'host', 'some/cloaked/hostmask'

		it 'should properly parse server hostname prefixes', ->
			serverName = parser.parse ':some.server.host COMMAND param'
			serverName.prefix.should.have.property 'nick', 'some.server.host'

		it "shouldn't fail on messages with no prefix", ->
			noPrefix = parser.parse 'COMMAND p1 p2'
			should.be.null noPrefix.prefix

		it 'should properly parse command from message', ->
			parsed = parser.parse 'COMMAND param'
			parsed.command.should.equal 'COMMAND'

		it 'should normalize commands to upper-case', ->
			parsed = parser.parse 'command param'
			parsed.command.should.equal 'COMMAND'

		it 'should properly parse middle-params', ->
			oneParam = parser.parse 'COMMAND param1'
			oneParam.parameters.should.equal [ 'param1' ]

			fourParams = parser.parse 'COMMAND p1 p2 p3 p4'
			fourParams.parameters.should.equal [ 'p1', 'p2', 'p3', 'p4' ]

		it 'should properly parse trailing-params', ->
			noMiddle = parser.parse 'COMMAND :trailing param'
			noMiddle.parameters.should.equal [ 'trailing param' ]

			middle = parser.parse 'COMMAND p1 :trailing trailing:trail'
			middle.parameters.should.equal [ 'p1', 'trailing trailing:trial' ]

		it 'should handle CRLF at end of message', ->
			crlf = parser.parse 'COMMAND :trailing\r\n'
			crlf.parameters.should.equal [ 'trailing' ]
