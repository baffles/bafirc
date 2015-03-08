###
Basic message prioritization.
###

priorityTable =
	PONG: 100

module.exports = (command, params...) -> priorityTable[command] ? 0
