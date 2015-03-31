###
Provides throttling and flood control, as described in RFC 1459, section 8.10.
###

PriorityQueue = require 'priorityqueuejs'
events = require 'events'

module.exports = class SendQueue extends events.EventEmitter
	constructor: (opts={}) ->
		@enabled = opts.enabled ? true
		@penalty = opts.penalty ? 2000
		@window = opts.window ? 10000
		@queue = new PriorityQueue (a, b) ->
			(a.priority - b.priority) or (b.seq - a.seq)
		@seq = 0

		if @enabled
			processQueue = => @processQueue()
			@timer = setInterval processQueue, @penalty

	stop: -> clearInterval @timer

	stats: ->
		queued = @queue.size()
		queued: queued, eta: @penalty * queued

	flush: ->
		@queue.deq() for i in [1..@queue.size()] if @queue.size()

	actualSend: (message) ->
		@emit 'send', message
		@lastActualSend = Date.now()

	processQueue: ->
		return if @queue.isEmpty()
		canSend = (Date.now() - @lastActualSend) / @penalty
		willSend = Math.min canSend, @queue.size()
		@actualSend message for message in [1..willSend].map () => @queue.deq().message

	send: (message, priority=0) ->
		shouldQueue = if @enabled
			now = Date.now()
			@messageTimer = Math.max @messageTimer ? 0, now
			@messageTimer += @penalty

			not @queue.isEmpty() or @messageTimer >= now + @window
		else
			false

		if shouldQueue
			@queue.enq { seq: @seq++, message, priority }
		else
			@actualSend message
