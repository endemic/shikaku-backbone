define [
	'jquery'
	'underscore'
	'backbone'
	'data/levels'
	'cs!utilities/env'
	'cs!views/common/scene'
	'text!templates/level-select.html'
], ($, _, Backbone, levels, env, Scene, template) ->
	class LevelSelectScene extends Scene
		events: ->
			if env.mobile
				events =
					'touchstart .back': 'back' 
					'touchstart .previous': 'previous'
					'touchstart .next': 'next'
					'touchstart .play': 'play'
			else
				events =
					'click .back': 'back' 
					'click .previous': 'previous'
					'click .next': 'next'
					'click .play': 'play'

		current: 0
		difficulty: 'beginner'
		stats: {}

		initialize: ->
			@elem = $(template)
			@render()

		previous: (e) ->
			e.preventDefault()

			if @current > 0
				@current--

				# Handle dimming prev/next buttons
				if @current == 0 then @$('.previous').addClass 'disabled'
				if @current == 28 then @$('.next').removeClass 'disabled'

				@trigger 'sfx:play', 'button'

				@showPreview levels[@difficulty][@current]

		next: (e) ->
			e.preventDefault()

			if @current < 29
				@current++

				# Handle dimming prev/next buttons
				if @current == 29 then @$('.next').addClass 'disabled'
				if @current == 1 then @$('.previous').removeClass 'disabled'

				@trigger 'sfx:play', 'button'

				@showPreview levels[@difficulty][@current]

		play: (e) ->
			e.preventDefault()
			
			# Prevent multiple clicks
			@undelegateEvents()

			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'game', { difficulty: @difficulty, level: @current }


		back: (e) ->
			e.preventDefault()

			# Prevent multiple clicks
			@undelegateEvents()
			
			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'difficulty'

		# Parse through a level object and display on a table
		showPreview: (json) ->
			pad = (number, length) ->
				string = String(number)
				string = '0' + string while string.length < length
				return string

			if @stats[@current]?.time			
				minutes = pad Math.floor(@stats[@current].time / 60), 2
				seconds = pad @stats[@current].time % 60, 2
				time = "#{minutes}:#{seconds}"
			else
				time = '--:--'

			attempts = if @stats[@current]?.attempts then @stats[@current].attempts else "0"
			
			@$('.level-number').html "#{@difficulty.charAt(0).toUpperCase() + @difficulty.slice(1)} ##{@current + 1}"
			@$('.attempts').html "Attempts: #{attempts}"
			@$('.best-time').html "Best Time: #{time}"

			# Add a checkmark in front of the level title if already completed
			if time != '--:--' then @$('.level-number').prepend '<span class="complete">&#10004;</span>'

			# Clear out previous preview
			@$('.preview div').html ''

			for clue in json.clues
				x = clue[0]
				y = clue[1]
				value = clue[2]
				index = y * 10 + x

				@$('.preview div').eq(index).html "<span>#{value}</span>"

		resize: (width, height, orientation) ->
			preview = @$('.preview')

			# TODO: Is it possible to get rid of this hardcoded nonsense? I don't think so
			if orientation is 'landscape'
				width = width * 0.4
				preview.width(Math.round(width / 10) * 10)
				preview.height(preview.width())
			else
				width = width * 0.6
				preview.width(Math.round(width / 10) * 10)
				preview.height(preview.width())

		hide: (duration = 500, callback) ->
			# Call "super"
			Scene.prototype.hide.call this, duration, callback

			# Store the last viewed level for this difficulty
			lastViewedLevel = localStorage.getObject('lastViewedLevel')
			lastViewedLevel[@difficulty] = @current
			localStorage.setObject 'lastViewedLevel', lastViewedLevel

		# Re-delegate event handlers and show the view's elem
		show: (duration = 500, callback) ->
			# Call "super"
			Scene.prototype.show.call this, duration, callback

			# Handle bizarre condition where this property isn't being set
			if !@difficulty then @difficulty = "beginner"
			
			# Update level stats based on localStorage
			@stats = localStorage.getObject('stats')[@difficulty]

			# Determine the last viewed level for this difficulty
			@current = localStorage.getObject('lastViewedLevel')[@difficulty]

			# Re-populate the preview window
			@showPreview levels[@difficulty][@current]