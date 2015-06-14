###
Help normalize input events
###
define () ->
	Input =
		normalize: (e, element = null) ->
			# Determine if the input is from mouse or touch
			if e.type.indexOf('mouse') != -1
				position = 
					x: e.pageX
					y: e.pageY
			else
				position = 
					x: e.touches[0].pageX
					y: e.touches[0].pageY

			return position

		distance: (point1, point2) ->
			return Math.sqrt(Math.pow(point1.x - point2.x, 2) + Math.pow(point1.y - point2.y, 2))