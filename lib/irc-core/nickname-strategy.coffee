###
Nickname selection strategies, for resolving nick-in-use errors on connect.
###

# A single nickname, never changing
class StaticNickname
	constructor: (@nick) ->
	set: (@nick) ->
	reset: ->
	next: -> false

# Rotates nicknames from a list
class NicknameList
	constructor: (@nickList, startId=0) ->
		@current = startId
		@nick = @nickList[@start]
		@reset()
	set: (@nick) ->
		idx = @nickList.indexOf @nick
		@current = idx if idx >= 0
	reset: ->
		@start = @current
	next: ->
		custom = false
		if @nick is @nickList[@current]
			++@current
			@current %= m
		else
			custom = true
		@nick = @nickList[@current]
		custom or @current != @start

# Generates nicknames by gradually incrementing and adding letters/numbers
class NicknameGenerator
	constructor: (@seed) ->
		@reset
	set: (@nick) ->
		@seed = @nick
	reset: ->
		@nick = @seed
	next: ->
		last = @nick.length - 1
		lastChar = @nick[last]
		if 'a' <= lastChar < 'z' or 'A' <= lastChar < 'Z' or '0' <= lastChar < '9'
			@nick = @nick.substr(0, last) + String.fromCharCode @nick.charCodeAt(last) + 1
		else
			@nick += switch
				when 'a' <= lastChar <= 'z' then 'a'
				when 'A' <= lastChar <= 'Z' then 'A'
				else '0'
		true

module.exports =
	static: StaticNickname
	list: NicknameList
	generator: NicknameGenerator
