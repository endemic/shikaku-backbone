###
Try to determine some basic info about the run environment
###
define () ->
	agent = navigator.userAgent.toLowerCase()
	android = agent.match(/android/i)
	android = android?.length > 0
	ios = agent.match(/ip(hone|od|ad)/i)
	ios = ios?.length > 0
	bb10 = agent.match(/BB10/i)
	bb10 = bb10?.length > 0
	mobile = android or ios or bb10
	desktop = not mobile
 
	return {
		android: android
		ios: ios
		bb10: bb10
		mobile: mobile
		desktop: desktop
		cordova: typeof cordova != "undefined"
	}