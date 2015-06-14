###
DifficultySelectAndroidScene
	- Lets user choose difficulty of levels
	- Android-specific code for IAP pushed in here
###
define [
	'jquery'
	'underscore'
	'backbone'
	'cs!utilities/env'
	'cs!views/common/scene'
	'cs!views/common/dialog-box'
	'text!templates/difficulty-select.html'
], ($, _, Backbone, env, Scene, DialogBox, template) ->
	class DifficultySelectAndroidScene extends Scene
		events:
			'touchstart .back': 'back' 
			'touchstart .restore': 'restore'
			'touchstart .difficulty button': 'select'
			'touchstart .buy button': 'buy'

		initialize: ->
			@elem = $(template)

			if window.inappbilling?
				# Init plugin
				window.inappbilling.init()

				# Callbacks for IAP
				@callbacks = {}

				@callbacks.purchased = (productId) =>
					console.log productId

					# Store the product ID the player just bought
					purchased = localStorage.getObject 'purchased'
					purchased.push productId
					localStorage.setObject 'purchased', purchased

					# Update the link so they can play those levels
					$('.easy, .medium, .hard', @elem).show()
					$('.buy', @elem).hide()
					$('.restore', @elem).hide()

					# Show a "success" message
					new DialogBox
						el: @elem
						title: 'Your purchase was successful!'
						buttons: [{ text: 'OK' }]

				@callbacks.restored = (productId) =>
					if productId
						$('.easy, .medium, .hard', @elem).show()
						$('.buy', @elem).hide()
						$('.restore', @elem).hide()

						# Store the product ID the player just bought
						purchased = localStorage.getObject 'purchased'
						purchased.push productId
						localStorage.setObject 'purchased', purchased

						message = 'Level packs restored!'
					else
						message = 'No purchases found.'

					# Show a message
					new DialogBox
						el: @elem
						title: message
						buttons: [{ text: 'OK' }]

				@callbacks.failed = =>
					# Show some sort of error message
					new DialogBox
						el: @elem
						title: "Sorry, there was some sort of problem."
						buttons: [{ text: 'OK' }]

				# Allow users to access IAP, otherwise hide the "restore" button because this isn't the IAP version
				@updatePurchaseStatus()
				
			else
				# No IAP plugin, allow player to play all levels
				$('.easy, .medium, .hard', @elem).show()
				$('.buy', @elem).hide()
				$('.restore', @elem).hide()

			@render()

		# Update % complete labels
		updatePercentComplete: ->
			complete = localStorage.getObject 'complete'

			$('.beginner span', @elem).html "#{Math.round complete.beginner * 100 / 30}%"
			$('.easy span', @elem).html "#{Math.round complete.easy * 100 / 30}%"
			$('.medium span', @elem).html "#{Math.round complete.medium * 100 / 30}%"
			$('.hard span', @elem).html "#{Math.round complete.hard * 100 / 30}%"

		# Re-enable buttons for IAP-enabled versions of the app
		updatePurchaseStatus: ->
			# If IAP version, get previously purchased level paks
			purchased = localStorage.getObject 'purchased'

			if purchased.length is 0
				$('.easy, .medium, .hard', @elem).hide()
				$('.buy', @elem).css { 'display': 'inline-block' }
			else
				$('.restore', @elem).hide()

		# Restore past purchases
		restore: (e) ->
			e.preventDefault()

			@trigger 'sfx:play', 'button'

			window.inappbilling.getOwnItems @callbacks.restored, @callbacks.failed
				
		# Difficulty choice
		select: (e) ->
			e.preventDefault()

			# Prevent multiple clicks
			@undelegateEvents()

			button = $(e.target)

			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'level', { difficulty: button.data 'difficulty' }
		
		# Buy the product!
		buy: (e) ->
			@trigger 'sfx:play', 'button'

			productId = "com.ganbarugames.shikakujs.levelpak"

			# DEBUG
			# productId = 'android.test.purchased'

			# Prompt user to buy
			window.inappbilling.purchase @callbacks.purchased, @callbacks.failed, productId

		# Go back to title
		back: (e) ->
			e.preventDefault()
			
			# Prevent multiple clicks
			@undelegateEvents()

			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'title'

		# Re-delegate event handlers and show the view's elem
		show: (duration = 500, callback) ->
			# Update the "percent complete" labels on difficulty select buttons
			@updatePercentComplete()

			# Call prototype
			super duration, callback