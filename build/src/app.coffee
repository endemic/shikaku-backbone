###
Main controller
	- Handles instantiating all game view objects and switching between them
	- Inits sound manager
###
define [
	'jquery'
	'underscore'
	'backbone'
	'buzz'
	'cs!utilities/env'
	'cs!views/title'
	'cs!views/game'
	'cs!views/about'
	'cs!views/level-select'
	'cs!views/difficulty-select'
	'cs!views/difficulty-select-android'
], ($, _, Backbone, buzz, env, TitleScene, GameScene, AboutScene, LevelSelectScene, DifficultySelectScene, DifficultySelectAndroidScene) ->
	
	# Extend local storage
	Storage.prototype.setObject = (key, value) ->
	    @setItem key, JSON.stringify value

	Storage.prototype.getObject = (key) ->
    	value = @getItem key
	    return value and JSON.parse value

	# Extend Backbone
	Backbone.View.prototype.close = ->
		@elem.remove()
		@undelegateEvents()

		if typeof @onClose == "function"
			@onClose()

	# Define app obj
	class App extends Backbone.View
		el: null
		activeScene: null
		sounds: {}

		initialize: ->
			# Ensure 'this' context is always correct
			_.bindAll @

			# Ensure that user data is initialized to defaults
			@initializeDefaults()

			# Create all game views here
			@el = if @options.el? then @options.el else $('#shikaku')
			@titleScene = new TitleScene { el: @el }
			@gameScene = new GameScene { el: @el }
			@aboutScene = new AboutScene { el: @el }
			@levelScene = new LevelSelectScene { el: @el }

			# Differentiate between views that have platform-specific IAP code
			if env.cordova and env.android
				@difficultyScene = new DifficultySelectAndroidScene { el: @el }
			else
				@difficultyScene = new DifficultySelectScene { el: @el }

			# Bind handlers on each view to allow easy switching between scenes
			@titleScene.on 'scene:change', @changeScene, @
			@gameScene.on 'scene:change', @changeScene, @
			@aboutScene.on 'scene:change', @changeScene, @
			@levelScene.on 'scene:change', @changeScene, @
			@difficultyScene.on 'scene:change', @changeScene, @

			# Bind handlers that deal with SFX/Music
			@titleScene.on 'sfx:play', @playSfx, @
			@gameScene.on 'sfx:play', @playSfx, @
			@aboutScene.on 'sfx:play', @playSfx, @
			@levelScene.on 'sfx:play', @playSfx, @
			@difficultyScene.on 'sfx:play', @playSfx, @

			# Hide all scenes
			@titleScene.hide 0
			@gameScene.hide 0
			@aboutScene.hide 0
			@levelScene.hide 0
			@difficultyScene.hide 0

			# Set "active" scene
			@activeScene = @titleScene

			# Show the active scene after a slight delay so user can view the amazing splash screen
			_.delay =>
				if env.cordova then navigator.splashscreen.hide()	# Manually remove the Cordova splash screen; prevent a white flash while UIWebView is initialized
				@activeScene.show()
			, 500

			# Add an additional class to game container if "installed" on iOS homescreen - currently unused
			if window.navigator.standalone then @el.addClass 'standalone'

			# Do an initial resize of the content area to ensure a 2:3 ratio
			@resize()

			# This handles desktop resize events as well as orientation changes
			$(window).on 'resize', @resize

			# Always listen for orientation change on mobile
			# if env.mobile then $(window).on 'orientationchange', @resize

			if env.mobile
				$('body').on 'touchmove', (e) ->
					e.preventDefault()
				$('body').on 'gesturestart', (e) ->
					e.preventDefault()
				$('body').on 'gesturechange', (e) ->
					e.preventDefault()
				$('body').on 'gestureend', (e) ->
					e.preventDefault()
			
			# If using Cordova w/ audio plugin, try to use that
			if env.cordova and window.LowLatencyAudio
				extension = if env.ios is true then 'm4a' else 'ogg'
				window.LowLatencyAudio.preloadFX 'button', "assets/sounds/button.#{extension}"
				window.LowLatencyAudio.preloadFX 'move', "assets/sounds/move.#{extension}"
				window.LowLatencyAudio.preloadFX 'erase', "assets/sounds/erase.#{extension}"
				window.LowLatencyAudio.preloadFX 'win', "assets/sounds/win.#{extension}"
			else
				# Load sound effects
				window.sounds = {}

				window.sounds.button = new buzz.sound "assets/sounds/button",
				    formats: [ "ogg", "mp3", "m4a" ]
				    preload: true

				window.sounds.move = new buzz.sound "assets/sounds/move",
				    formats: [ "ogg", "mp3", "m4a" ]
				    preload: true

				window.sounds.erase = new buzz.sound "assets/sounds/erase",
				    formats: [ "ogg", "mp3", "m4a" ]
				    preload: true

				window.sounds.win = new buzz.sound "assets/sounds/win",
				    formats: [ "ogg", "mp3", "m4a" ]
				    preload: true

				# Lower SFX volume a bit
				for key, sound of window.sounds
					sound.setVolume 25

		# Callback to play a sound effect
		playSfx: (id) ->
			# Try to use Cordova plugin if possible
			if env.cordova and window.LowLatencyAudio
				window.LowLatencyAudio.play id
			else
				# Otherwise, play the sound if the specified index exists
				window.sounds[id]?.play()

		# Handle hiding/showing the active scene
		changeScene: (scene, options) ->
			@activeScene.hide()

			switch scene
				when 'title' then @activeScene = @titleScene
				when 'about' then @activeScene = @aboutScene
				when 'difficulty' then @activeScene = @difficultyScene
				when 'level' 
					@levelScene.difficulty = options.difficulty
					@activeScene = @levelScene
				when 'game' 
					# Set the game's diff & level props from the passed "options" arg
					@gameScene.difficulty = options.difficulty
					@gameScene.level = options.level
					@gameScene.tutorial = options.tutorial
					@activeScene = @gameScene
				else
					console.log "Error! Scene not defined in switch statement" 
					@activeScene = @titleScene

			@activeScene.show()

		resize: ->
			# Attempt to force a 2:3 aspect ratio, so that the percentage-based CSS layout is consistant
			width = @el.width()
			height = @el.height()

			# This obj will be used to store how much padding is needed for each scene's container
			padding = 
				width: 0
				height: 0

			if width > height
				@el.removeClass('portrait').addClass('landscape')
				orientation = 'landscape'
			else 
				@el.removeClass('landscape').addClass('portrait')
				orientation = 'portrait'

			# Landscape
			# example, 1280 x 800 - correct 2:3 ratio is 1200 x 800
			# example, 1024 x 768 - correct 2:3 ratio is 1024 x 682

			# Aspect ratio to enforce
			ratio = 3 / 2

			# Tweet: Started writing some commented-out psuedocode, but it turned out to be CoffeeScript, so I uncommented it.
			if orientation is 'landscape'
				if width / ratio > height 		# Too wide; add padding to width
					newWidth = height * ratio
					padding.width = width - newWidth
					width = newWidth
				else if width / ratio < height 	# Too high; add padding to height
					newHeight = width / ratio
					padding.height = height - newHeight
					height = newHeight
				$('body').css { 'font-size': "#{width * 0.1302}%" }		# Dynamically update the font size - 0.1302% font size per pixel in width

			else if orientation is 'portrait'
				if height / ratio > width 		# Too high; add padding to height
					newHeight = width * ratio
					padding.height = height - newHeight
					height = newHeight
				else if height / ratio < width 	# Too wide, add padding to width
					newWidth = height / ratio
					padding.width = width - newWidth
					width = newWidth
				$('body').css { 'font-size': "#{height * 0.1302}%" }	# Dynamically update the font size - 0.1302% font size per pixel in height

			# Add the calculated padding to each scene <div>
			@el.find('.scene .container').css
				width: width
				height: height
				padding: "#{padding.height / 2}px #{padding.width / 2}px"

			# Call a "resize" method on views that need it
			@gameScene.resize width, height, orientation
			@levelScene.resize width, height, orientation

		# Make sure that any data stored in localStorage is initialized to a default (read: expected) value
		initializeDefaults: ->
			console.log localStorage.getObject('stats')
			console.log 'what?'
			# Obj that stores # of tries, best time, etc.
			if localStorage.getObject('stats') == null
				stats = 
					beginner: {}
					easy: {}
					medium: {}
					hard: {}
				localStorage.setObject 'stats', stats

			# Obj that stores # of completed levels per difficulty
			if localStorage.getObject('complete') == null
				complete = 
					beginner: 0
					easy: 0
					medium: 0
					hard: 0
				localStorage.setObject 'complete', complete

			# Obj that stores the most recently viewed level in a difficulty
			if localStorage.getObject('lastViewedLevel') == null
				lastViewedLevel = 
					beginner: 0
					easy: 0
					medium: 0
					hard: 0
				localStorage.setObject 'lastViewedLevel', lastViewedLevel

			# Array that contains purchased IAP product IDs
			if localStorage.getObject('purchased') == null
				localStorage.setObject 'purchased', []
	
	# Wait until "deviceready" event is fired, if necessary (Cordova only)
	if env.cordova
		document.addEventListener "deviceready", ->
			window.shikaku = new App
		, false
	else
		window.shikaku = new App