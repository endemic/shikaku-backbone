define [
	'jquery'
	'backbone'
	'cs!utilities/env'
	'cs!views/common/scene'
	'text!templates/title.html'
], ($, Backbone, env, Scene, template) ->
	class TitleScene extends Scene
		events: ->
			# Determine whether touchscreen or desktop
			if env.mobile
				events =
					'touchstart .start': 'start' 
					'touchstart .tutorial': 'tutorial' 
					'touchstart .about': 'about'
			else
				events =
					'click .start': 'start' 
					'click .tutorial': 'tutorial' 
					'click .about': 'about'

		initialize: ->
			@elem = $(template)
			@render()

		start: (e) ->
			e.preventDefault()
			@undelegateEvents()
			
			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'difficulty'

		tutorial: (e) ->
			e.preventDefault()
			@undelegateEvents()

			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'game', { difficulty: 'beginner', level: 0, tutorial: true }

		about: (e) ->
			e.preventDefault()
			@undelegateEvents()

			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'about'
		