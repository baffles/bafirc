###
Basic message prioritization.
###

priorityTable =
	PONG: 128
	PING: 128

module.exports = (command, params...) -> priorityTable[command] ? 0
