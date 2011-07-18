(function() {

	
	// Provide namespaces
	var namespace;
	namespace = function(name, block) {
		var item, target, top, _i, _len, _ref;
		top = target = typeof exports !== 'undefined' ? exports : window;
		_ref = name.split('.');
		for (_i = 0, _len = _ref.length; _i < _len; _i++) {
			item = _ref[_i];
			target = target[item] || (target[item] = {});
		}
		return block(target, top);
	};
	
	
	//= require "../../build/javascripts/argure/model.js"
	//= require "../../build/javascripts/argure/bindings.js"


}).call(this);

//= require "../../vendor/coffee-script-debug.js"
