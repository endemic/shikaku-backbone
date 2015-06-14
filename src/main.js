require({
	paths: {
		cs: '../coffeescript/cs',
		CoffeeScript: '../coffeescript/CoffeeScript',
		// jquery: 'lib/jquery-1.7.2.min',
		jquery: 'lib/zepto',
		underscore: 'lib/underscore',
		backbone: 'lib/backbone',
		buzz: 'lib/buzz'
	},
  shim: {
  		// Only necessary when substituting Zepto for jQuery
  		'jquery': {
  			exports: '$'
  		},
  		'underscore': {
  			exports: '_'
  		},
        'backbone': {
            //These script dependencies should be loaded before loading backbone.js
            deps: ['underscore', 'jquery'],
            //Once loaded, use the global 'Backbone' as the module value.
            exports: 'Backbone'
        },
        'buzz': {
        	exports: 'buzz'
        }
    }
}, ['cs!app']);
