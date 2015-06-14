###
DifficultySelectScene
	- Lets user choose difficulty of levels
###
define [
	'jquery'
	'backbone'
	'cs!utilities/env'
	'cs!views/common/scene'
	'cs!views/common/dialog-box'
	'text!templates/difficulty-select.html'
], ($, Backbone, env, Scene, DialogBox, template) ->
	class DifficultySelectScene extends Scene
		events: ->
			# Determine whether touchscreen or desktop
			if env.mobile
				events =
					'touchstart .back': 'back' 
					'touchstart .restore': 'restore'
					'touchstart .difficulty button': 'select'
			else
				events =
					'click .back': 'back'
					'click .restore': 'restore'
					'click .difficulty button': 'select'

		productIds: [
			'com.ganbarugames.shikakumadnessfree.easy',
			'com.ganbarugames.shikakumadnessfree.medium',
			'com.ganbarugames.shikakumadnessfree.hard'
		]

		initialize: ->
			@elem = $(template)

			if window.inAppPurchaseManager?
				for id in @productIds
					window.inAppPurchaseManager.requestProductData id

				# Callbacks for IAP
				window.inAppPurchaseManager.onPurchased = (transactionIdentifier, productId, transactionReceipt) =>
					# Store the product ID the player just bought
					purchased = localStorage.getObject 'purchased'
					purchased.push productId
					localStorage.setObject 'purchased', purchased

					difficulty = productId.split('.').pop()

					# Update the link so they can play those levels
					$('.' + difficulty, @elem).data 'purchased', 'yes'
					$('.' + difficulty + ' span', @elem).html "0%"

					# Show a "success" message
					new DialogBox
						el: @elem
						title: 'Your purchase was successful!'
						buttons: [{ text: 'OK' }]

				window.inAppPurchaseManager.onRestored = (originalTransactionIdentifier, productId, originalTransactionReceipt) =>
					# Store the product ID the player just bought
					purchased = localStorage.getObject 'purchased'
					purchased.push productId
					localStorage.setObject 'purchased', purchased

					# Update the button so player can play levels
					difficulty = productId.split('.').pop()
					$('.' + difficulty, @elem).data 'purchased', 'yes'
					$('.' + difficulty + ' span', @elem).html "0%"

					# Show a "success" message
					new DialogBox
						el: @elem
						title: 'Level packs restored!'
						buttons: [{ text: 'OK' }]

				window.inAppPurchaseManager.onFailed = (errorNumber, errorText) =>
					# Show some sort of error message
					new DialogBox
						el: @elem
						title: errorText
						buttons: [{ text: 'OK' }]

				# Allow users to access IAP, otherwise hide the "restore" button because this isn't the IAP version
				@updatePurchaseStatus()
				
			else
				$('.restore', @elem).hide()

			@render()

		# Update % complete labels
		updatePercentComplete: () ->
			complete = localStorage.getObject 'complete'

			$('.beginner span', @elem).html "#{Math.round complete.beginner * 100 / 30}%"

			if $('.easy', @elem).data('purchased') is 'yes'
				$('.easy span', @elem).html "#{Math.round complete.easy * 100 / 30}%"

			if $('.hard', @elem).data('purchased') is 'yes'
				$('.medium span', @elem).html "#{Math.round complete.medium * 100 / 30}%"

			if $('.hard', @elem).data('purchased') is 'yes'
				$('.hard span', @elem).html "#{Math.round complete.hard * 100 / 30}%"

		updatePurchaseStatus: ->
			# If IAP version, get previously purchased level paks
			purchased = localStorage.getObject 'purchased'

			# Set data-purchased="no" for level paks player hasn't bought; change text in span
			for id in @productIds
				if purchased.indexOf(id) is -1
					difficulty = id.split('.').pop()
					$('.' + difficulty, @elem).data 'purchased', 'no'
					$('.' + difficulty + ' span', @elem).html "$0.99"

		# Restore past purchases
		restore: (e) ->
			e.preventDefault()
			window.inAppPurchaseManager?.restoreCompletedTransactions()
				
		# Difficulty choice
		select: (e) ->
			e.preventDefault()
			button = $(e.target)

			if button.data('purchased') is 'yes'
				@trigger 'sfx:play', 'button'
				@trigger 'scene:change', 'level', { difficulty: button.data 'difficulty' }
			else
				productId = "com.ganbarugames.shikakumadnessfree.#{button.data 'difficulty'}"

				# Prompt user to buy
				window.inAppPurchaseManager?.makePurchase productId, 1

		# Go back to title
		back: (e) ->
			e.preventDefault()
			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'title'

		# Re-delegate event handlers and show the view's elem
		show: (duration = 500, callback) ->
			# Update the "percent complete" labels on difficulty select buttons
			@updatePercentComplete()

			# Call "super"
			Scene.prototype.show.call this, duration, callback