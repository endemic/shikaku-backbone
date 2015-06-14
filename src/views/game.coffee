###
GameScene
	- Contains the main game logic
###
define [
	'jquery'
	'underscore'
	'backbone'
	'data/levels'
	'cs!utilities/env'
	'cs!utilities/cgrect'
	'cs!utilities/input'
	'cs!views/common/scene'
	'cs!views/common/dialog-box'
	'text!templates/game.html'
], ($, _, Backbone, levels, env, CGRect, Input, Scene, DialogBox, template) ->
	class GameScene extends Scene
		events: ->
			# Determine whether touchscreen or desktop
			if env.mobile
				events = 
					'touchstart .quit': 'quit'
					'touchstart .reset': 'reset'
					'touchstart': 'onActionStart'
					'touchmove': 'onActionMove'
					'touchend': 'onActionEnd'
			else 
				events = 
					'click .quit': 'quit'
					'click .reset': 'reset'
					'mousedown': 'onActionStart'
					'mouseup': 'onActionEnd'

		difficulty: "beginner"
		level: 0
		timer: null
		seconds: 0
		rectangle: null
		rectangles: []
		clues: []
		blockSize: 0
		startRow: -1
		startCol: -1
		previousRow: -1
		previousCol: -1
		startPosition: null
		ignoreInput: false
		tutorial: false
		tutorialStep: 0
		hint: null

		initialize: ->
			# View is initialized hidden
			@elem = $(template)

			# Create "rectangle" element w/ default size
			@rectangle = $('<div class="rectangle"><span></span></div>').hide()
			@elem.append(@rectangle)

			# Create the "hint" rect
			@hint = $('<div class="rectangle hint"><span></span></div>').hide()
			@elem.append(@hint)

			# Get some references to DOM elements that we need later
			@grid = $('.grid', @elem)

			@render()

		# Append the view's elem to the DOM
		render: ->
			@$el.append @elem

			# Get size of grid blocks - round to nearest whole number to prevent weirdness w/ decimals
			@blockSize = Math.round @grid.width() / 10

		# Triggered on mousedown or touchstart
		onActionStart: (e) ->
			e.preventDefault()
			if @ignoreInput then return

			# Determine if event was caused by mouse or finger
			if e.type == 'mousedown'
				@elem.on 'mousemove', $.proxy @, 'onActionMove'

			position = @startPosition = Input.normalize e
			# console.log position

			row = Math.floor((position.y - @grid.offset().top) / @blockSize)
			col = Math.floor((position.x - @grid.offset().left) / @blockSize)

			# Only recognize movement if within grid bounds
			if 0 <= row <= 9 and 0 <= col <= 9
				# Determine the row/col
				@startRow = @previousRow = row
				@startCol = @previousCol = col

				# Move indicator to correct place
				@rectangle.css { left: col * @blockSize + Math.floor(@grid.offset().left - @elem.offset().left), top: row * @blockSize + Math.floor(@grid.offset().top - @elem.offset().top) }

				# Determine if new rect overlaps
				# This is slightly convoluted since CoffeeScript doesn't have "for" loops
				i = 0
				while i < @rectangles.length
					rect = @rectangles[i]
					rectAABB = CGRect.make rect.offset().left, @elem.height() - rect.offset().top, rect.width(), rect.height()
					touchAABB = CGRect.make position.x, @elem.height() - position.y, 2, 2
					if CGRect.intersectsRect rectAABB, touchAABB
						rect.remove()
						@rectangles.splice i, 1
						i--
						@trigger 'sfx:play', 'erase'
					i++

		# Triggered on mousemove or touchmove
		onActionMove: (e) ->
			e.preventDefault()
			if @ignoreInput then return
			if @startRow is -1 or @startCol is -1 then return

			# Get user input
			position = Input.normalize e

			# Determine the row/col
			row = Math.floor((position.y - @grid.offset().top) / @blockSize)
			col = Math.floor((position.x - @grid.offset().left) / @blockSize)

			# Only recognize movement if within grid bounds
			if 0 <= row <= 9 and 0 <= col <= 9

				width = Math.abs(@startCol - col) + 1
				height = Math.abs(@startRow - row) + 1

				# This allows a single click/tap to remove rects
				# User has to move input at least 5px to start drawing a new one
				if Input.distance(position, @startPosition) > 5 and @rectangle.css('display') is 'none'
					@rectangle.show()
					@$('.area').html "Area:<br>1"
					@trigger 'sfx:play', 'move'

				if row != @previousRow
					@rectangle.height(height * @blockSize)
					
					# Determine if necessary to just draw (normal) or draw & move up (upwards movement)
					if row <= @startRow
						@rectangle.css { left: Math.floor(@rectangle.offset().left - @elem.offset().left), top: row * @blockSize + Math.floor(@grid.offset().top - @elem.offset().top) }

				if col != @previousCol
					@rectangle.width(width * @blockSize)

					if col <= @startCol
						@rectangle.css { left: col * @blockSize + Math.floor(@grid.offset().left - @elem.offset().left), top: Math.floor(@rectangle.offset().top - @elem.offset().top) }

				if row != @previousRow or col != @previousCol
					@trigger 'sfx:play', 'move'
					@$('.area').html "Area:<br>#{width * height}"

				@previousRow = row
				@previousCol = col

		# Triggered on mouseup or touchend
		onActionEnd: (e) ->
			e.preventDefault()
			if @ignoreInput then return

			# Determine if event was caused by mouse or finger
			if e.type == 'mouseup' then @elem.off 'mousemove', $.proxy @, 'onActionMove'

			# Only draw a rect if the player moved their cursor/finger enough
			if @rectangle.css('display') is 'block'
				width = Math.abs(@startCol - @previousCol) + 1
				height = Math.abs(@startRow - @previousRow) + 1
				area = width * height

				# Create a dupe of the currently displayed rect
				clone = @rectangle.clone()
				@elem.append clone

				# Check to see if the rect overlaps a clue, and if it's the correct size for the clue
				# If so, give it an additional class
				rectAABB = CGRect.make clone.offset().left, @elem.height() - clone.offset().top, clone.width(), clone.height()
				count = 0
				for clue in @clues
					clueAABB = CGRect.make clue.offset().left, @elem.height() - clue.offset().top, clue.width(), clue.height()
					if CGRect.intersectsRect rectAABB, clueAABB
						validClue = clue
						count++

				if count == 1 and parseInt(validClue.text(), 10) == area
					clone.addClass 'valid'

				# For the win condition check
				clone.data 'area', area 

				# This other data is to support re-positioning rects in the case of an orientation change
				clone.data 'left', (clone.offset().left - @grid.offset().left) / @blockSize
				clone.data 'top', (clone.offset().top - @grid.offset().top) / @blockSize
				clone.data 'width', width
				clone.data 'height', height

				# Store
				@rectangles.push clone

				# Reset the original rectangle
				@rectangle.width @blockSize
				@rectangle.height @blockSize
				@rectangle.hide()

				# Reset area counter
				@$('.area').html "Area:<br>&mdash;"

			# Check if player has won
			if @check() then @win()

			# Clear out previous touch data
			@startRow = @previousRow = @startCol = @previousCol = -1

		# Check whether player has won or not
		check: () ->
			# Fast fail
			if @rectangles.length != @clues.length then return false

			# Iterate through rects
			for rect in @rectangles
				count = 0
				validClue = null

				rectAABB = CGRect.make rect.offset().left, @elem.height() - rect.offset().top, rect.width(), rect.height()
				for clue in @clues
					clueAABB = CGRect.make clue.offset().left, @elem.height() - clue.offset().top, clue.width(), clue.height()
					if CGRect.intersectsRect rectAABB, clueAABB
						validClue = clue
						count++

				if count > 1 or count == 0
					# console.log "Failing because count is #{count} for clue #{rect.data('area')}"
					return false

				if parseInt(validClue.text(), 10) != parseInt(rect.data('area'), 10)
					# console.log "Clue and rect area don't match! #{validClue.text()} #{rect.data('area')}"
					return false

			return true

		# Actions when player solves the puzzle
		win: () ->
			@ignoreInput = true

			# Play jingle
			@trigger 'sfx:play', 'win'

			# Stop the timer
			clearInterval(@timer)

			if not @tutorial
				stats = localStorage.getObject 'stats'

				# If level hasn't been completed before...
				if not stats[@difficulty][@level].time
					stats[@difficulty][@level].time = @seconds
					complete = localStorage.getObject 'complete'
					complete[@difficulty]++
					localStorage.setObject 'complete', complete
				else if stats[@difficulty][@level].time > @seconds
					stats[@difficulty][@level].time = @seconds

				localStorage.setObject 'stats', stats
			else
				# Reset the tutorial
				@tutorialStep = 0

			new DialogBox
				el: @elem
				title: 'Puzzle solved!'
				buttons: [
					{ 
						text: 'OK'
						callback: => 
							@ignoreInput = false
							if @tutorial
								@trigger 'scene:change', 'title'
							else
								@trigger 'scene:change', 'level', { difficulty: @difficulty }
					}
				]

		# Go back to the level select screen
		quit: (e) ->
			e.preventDefault()
			@ignoreInput = true
			@trigger 'sfx:play', 'button'

			new DialogBox
				el: @elem
				title: 'Are you sure?'
				buttons: [
					{ 
						text: 'Yes'
						callback: => 
							@ignoreInput = false
							if @tutorial
								# Reset the tutorial
								@tutorialStep = 0

								# Go back to title
								@trigger 'scene:change', 'title'
							else
								@trigger 'scene:change', 'level', { difficulty: @difficulty }
					}, {
						text: 'No'
						callback: =>
							@ignoreInput = false
					}
				]

		# Remove all rectangles from board
		reset: (e) ->
			e.preventDefault()
			@ignoreInput = true
			@trigger 'sfx:play', 'button'

			new DialogBox
				el: @elem
				title: 'Are you sure?'
				buttons: [
					{ 
						text: 'Yes'
						callback: => 
							@ignoreInput = false

							# Wait for overlay to move off the screen before erasing
							_.delay =>
								for rect in @rectangles
									rect.remove()	# Remove from DOM
								@rectangles = []
								@trigger 'sfx:play', 'erase'
							, 300
					}, {
						text: 'No'
						callback: =>
							@ignoreInput = false
					}
				]

		# Update timer elem
		updateTimer: (e) ->
			@seconds++

			pad = (number, length) ->
				string = String(number)
				string = '0' + string while string.length < length
				return string

			minutes = pad Math.floor(@seconds / 60), 2
			seconds = pad @seconds % 60, 2

			$('.timer', @elem).html "Time:<br>#{minutes}:#{seconds}"

			# Update steps in tutorial here if necessary
			if @tutorial
				success = false

				# Check if user placed the correct rect
				switch @tutorialStep
					when 7
						# Search through rects and see if a drawn one matches the one we want
						for rect in @rectangles
							if parseInt(rect.data('area'), 10) == 7 and rect.offset().left == 0 * @blockSize + @grid.offset().left and rect.offset().top == 9 * @blockSize + @grid.offset().top
								success = true
					when 8
						for rect in @rectangles
							if parseInt(rect.data('area'), 10) == 9 and rect.offset().left == 7 * @blockSize + @grid.offset().left and rect.offset().top == 7 * @blockSize + @grid.offset().top
								success = true
					when 11
						for rect in @rectangles
							if parseInt(rect.data('area'), 10) == 7 and rect.offset().left == 9 * @blockSize + @grid.offset().left and rect.offset().top == 0 * @blockSize + @grid.offset().top
								success = true
					when 12
						for rect in @rectangles
							if parseInt(rect.data('area'), 10) == 10 and rect.offset().left == 7 * @blockSize + @grid.offset().left and rect.offset().top == 2 * @blockSize + @grid.offset().top
								success = true
					when 13
						for rect in @rectangles
							if parseInt(rect.data('area'), 10) == 8 and rect.offset().left == 5 * @blockSize + @grid.offset().left and rect.offset().top == 0 * @blockSize + @grid.offset().top
								success = true
					when 14
						for rect in @rectangles
							if parseInt(rect.data('area'), 10) == 12 and rect.offset().left == 0 * @blockSize + @grid.offset().left and rect.offset().top == 3 * @blockSize + @grid.offset().top
								success = true
					when 16
						for rect in @rectangles
							if parseInt(rect.data('area'), 10) == 9 and rect.offset().left == 2 * @blockSize + @grid.offset().left and rect.offset().top == 0 * @blockSize + @grid.offset().top
								success = true

				if success
					@tutorialStep++
					@showTutorial()
							

		showTutorial: ->
			@ignoreInput = true

			text = [
				"Welcome to Shikaku Madness! Shikaku are logic puzzles where you try to cover a grid with rectangles." # 0
				"Solve each puzzle using the numeric clues placed on the grid."										   # 1
				"Each number represents the size of the square or rectangle that covers it."						   # 2
				"Each rectangle can only contain one clue, and can't overlap other rectangles."
				"Tap and drag on the grid to draw. If you make a mistake, tap to remove."
				"A good place to start drawing is in corners. Look at the \"7\" in the bottom left."
				"A rectangle can only overlap one clue, so the one that covers \"7\" has to go along the bottom."		# 6
				"Go ahead and draw a long, thin rectangle with 7 squares in the bottom left corner."					# 7
				# Action
				"Check out the lower right corner. A \"9\" can only fit by making a 3x3 square."						# 8
				# Action 
				"Continue up the right side. The rectangle that covers the \"7\" can't go horizontally."				# 9
				"There's only one way it can be drawn... vertically along the side of the grid."						# 10
				"Go ahead and draw that \"7\" now."																		# 11
				# Action
				"Having eliminated some blank space, we can draw the \"10\"."											# 12
				# Action
				"Then we can also deduce where the \"8\" should be placed."												# 13
				# Action
				"Now go back to the bottom left side and draw over the \"12\"."											# 14
				# Action
				"You can make educated guesses on where each rectangle is drawn. If it doesn't work, just erase!"		# 15
				"Try drawing a square around the remaining \"9\"."														# 16
				# Action
				"The rest is up to you! Don't be afraid to use trial and error. Good luck!"
			]

			# Hide previous hint
			@hint.hide()

			# Show hint overlays here
			switch @tutorialStep
				when 7
					# Set data attributes on the hint, so it can be resized/reoriented
					@hint.data 'left', 0
					@hint.data 'top', 9
					@hint.data 'width', 7
					@hint.data 'height', 1
					@hint.width(7 * @blockSize)
					@hint.height(1 * @blockSize)
					@hint.show().css { left: 0 * @blockSize + @grid.offset().left - @elem.offset().left, top: 9 * @blockSize + @grid.offset().top - @elem.offset().top }
				when 8
					@hint.data 'left', 7
					@hint.data 'top', 7
					@hint.data 'width', 3
					@hint.data 'height', 3
					@hint.width(3 * @blockSize)
					@hint.height(3 * @blockSize)
					@hint.show().css { left: 7 * @blockSize + @grid.offset().left - @elem.offset().left, top: 7 * @blockSize + @grid.offset().top - @elem.offset().top }
				when 11
					@hint.data 'left', 9
					@hint.data 'top', 0
					@hint.data 'width', 1
					@hint.data 'height', 7
					@hint.width(1 * @blockSize)
					@hint.height(7 * @blockSize)
					@hint.show().css { left: 9 * @blockSize + @grid.offset().left - @elem.offset().left, top: 0 * @blockSize + @grid.offset().top - @elem.offset().top }
				when 12
					@hint.data 'left', 7
					@hint.data 'top', 2
					@hint.data 'width', 2
					@hint.data 'height', 5
					@hint.width(2 * @blockSize)
					@hint.height(5 * @blockSize)
					@hint.show().css { left: 7 * @blockSize + @grid.offset().left - @elem.offset().left, top: 2 * @blockSize + @grid.offset().top - @elem.offset().top }
				when 13
					@hint.data 'left', 5
					@hint.data 'top', 0
					@hint.data 'width', 4
					@hint.data 'height', 2
					@hint.width(4 * @blockSize)
					@hint.height(2 * @blockSize)
					@hint.show().css { left: 5 * @blockSize + @grid.offset().left - @elem.offset().left, top: 0 * @blockSize + @grid.offset().top - @elem.offset().top }
				when 14
					@hint.data 'left', 0
					@hint.data 'top', 3
					@hint.data 'width', 2
					@hint.data 'height', 6
					@hint.width(2 * @blockSize)
					@hint.height(6 * @blockSize)
					@hint.show().css { left: 0 * @blockSize + @grid.offset().left - @elem.offset().left, top: 3 * @blockSize + @grid.offset().top - @elem.offset().top }
				when 16
					@hint.data 'left', 2
					@hint.data 'top', 0
					@hint.data 'width', 3
					@hint.data 'height', 3
					@hint.width(3 * @blockSize)
					@hint.height(3 * @blockSize)
					@hint.show().css { left: 2 * @blockSize + @grid.offset().left - @elem.offset().left, top: 0 * @blockSize + @grid.offset().top - @elem.offset().top }

			new DialogBox
				el: @elem
				title: text[@tutorialStep]
				buttons: [{ 
					text: 'OK'
					callback: =>
						@ignoreInput = false

						# These steps indicate where the player has to take action
						if [ 7, 8, 11, 12, 13, 14, 16 ].indexOf(@tutorialStep) == -1 and @tutorialStep < 17
							@tutorialStep++
							@showTutorial()
				}]

		resize: (width, height, orientation) ->
			# Use Math.floor here to ensure the grid doesn't round up to be larger than width/height of container
			if orientation is 'landscape'
				gridWidth = Math.round(height * 0.97 / 10) * 10 	# Make sure grid size is 97% of viewport, and is a multiple of 10
				@grid.width(gridWidth)
				@grid.height(gridWidth)

				# Manually apply absolute positioning, based on the size of the grid and how much padding the container has
				paddingRight = parseInt(@elem.find('.container').css('padding-right'), 10)
				paddingBottom = parseInt(@elem.find('.container').css('padding-bottom'), 10)
				@grid.css 
					'bottom': "#{paddingBottom + (height - gridWidth) / 2}px"
					'right': "#{paddingRight + (height - gridWidth) / 2}px"

			else if orientation is 'portrait'
				gridWidth = Math.round(width * 0.97 / 10) * 10 	# Make sure grid size is 97% of viewport, and is a multiple of 10
				@grid.width(gridWidth)
				@grid.height(gridWidth)
				paddingRight = parseInt(@elem.find('.container').css('padding-right'), 10)
				paddingBottom = parseInt(@elem.find('.container').css('padding-bottom'), 10)
				@grid.css 
					'bottom': "#{paddingBottom + (width - gridWidth) / 2}px"
					'right': "#{paddingRight + (width - gridWidth) / 2}px"


			# Reset the size of the rectangle prototype
			size = Math.round(@grid.width() / 10)
			@blockSize = size
			@rectangle.width size
			@rectangle.height size

			# Set the border radius/width of rectangle prototype
			@rectangle.css 
				'border-radius': "#{size / 2}px"
				'border-width': "#{size / 10}px"
			@rectangle.find('span').css
				'border-radius': "#{size / 3}px"

			# Also set for tutorial hint
			@hint.css 
				'border-radius': "#{size / 2}px"
				'border-width': "#{size / 10}px"
			@hint.find('span').css
				'border-radius': "#{size / 3}px"

			# Re-size the placed rectangles
			# Reset the left/top values of the rect to the anchor value plus the new grid offset
			for rect in @rectangles
				left = rect.data 'left'
				top = rect.data 'top'
				width = rect.data 'width'
				height = rect.data 'height'
				rect.css
					left: (left * @blockSize) + @grid.offset().left
					top: (top * @blockSize) + @grid.offset().top
					width: width * @blockSize
					height: height * @blockSize

			# Update the tutorial "hint" as well, if it's visible
			if @hint.css 'display' is 'block'
				left = @hint.data 'left'
				top = @hint.data 'top'
				width = @hint.data 'width'
				height = @hint.data 'height'
				@hint.css
					left: (left * @blockSize) + @grid.offset().left
					top: (top * @blockSize) + @grid.offset().top
					width: width * @blockSize
					height: height * @blockSize

		# Remove event handlers and hide this view's elem
		hide: (duration = 500, callback) ->
			# Call "super"
			Scene.prototype.hide.call this, duration, callback
			
			# Do all this stuff after transition offscreen
			_.delay =>
				# Make sure tutorial is hidden
				@tutorial = false
				@hint.hide()

				# Reset timer
				clearInterval(@timer)
				@seconds = 0
				@$('.timer').html "Time:<br>00:00"
				
				# Reset clues
				@$('.grid div').html('')
				@clues = []
				
				# Reset Rects
				for rect in @rectangles
					rect.remove()	# Remove from DOM
				@rectangles = []
			, duration

		# Re-delegate event handlers and show the view's elem
		show: (duration = 500, callback) ->
			# Call "super"
			Scene.prototype.show.call this, duration, callback

			# Start timer
			@timer = setInterval($.proxy(@, 'updateTimer'), 1000)

			if @tutorial is true
				_.delay =>
					@showTutorial()
				, duration
			else
				# Record attempts
				stats = localStorage.getObject 'stats'

				if not stats[@difficulty][@level]
					stats[@difficulty][@level] = { attempts: 1 }
				else 
					stats[@difficulty][@level].attempts++

				localStorage.setObject 'stats', stats

			# Load level/parse clues
			for clue in levels[@difficulty][@level].clues
				x = clue[0]
				y = clue[1]
				value = clue[2]
				index = y * 10 + x

				# Insert clues
				c = $("<span>#{value}</span>")
				@$('.grid div').eq(index).html c
				# $("tr td", @elem).eq(index).html c

				# Add to organizational array
				@clues.push c