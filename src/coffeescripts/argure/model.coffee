class ModelHelper
	constructor: (@callback) ->
	build: (viewModel) ->
		@callback.call(viewModel)

namespace 'Argure', (exports) ->
	exports.ModelHelper = ModelHelper


Model = (properties) ->
	_ = {}
	(_[name] = if (value instanceof ModelHelper) then value.build(_) else value) for name, value of properties if properties
	_

namespace 'Argure', (exports) ->
	exports.Model = Model
