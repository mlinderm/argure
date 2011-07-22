# Compatibility method for Object.keys (https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object/keys)
class Errors
	constructor: ->
		errors = {}
		
		@size = ->
			_.reduce (errors[k].length for k in _.keys(errors)), ((m, k) -> m+k), 0
		@add = (name, message) ->
			(errors[name] ?= []).push message
			@

#/Errors


class Model
	constructor: ->

		@errors = new Errors()


		_priCounter=0
		build_observable = (name, observable_kind, initial_value) ->
			state    = observable_kind initial_value
			priority = ko.observable 0
			argure_observable = ko.dependentObservable
				read : -> state()
				write: (value) ->
					priority(++_priCounter)
					state(value)
					null
				owner: @
			argure_observable.observableName = name
			argure_observable.state = state
			argure_observable.priority = priority
			argure_observable.errors = false  # Default is no errors
			return argure_observable

		# Convert observables into corresponding knockout observables
		for name, options of @.constructor.observables ? {}
			continue if @[name]
			@[name] = build_observable.call @, name, ko.observable, options.initial
			true

		# Convert collections into corresponding knockout observable arrays
		for name, options of @.constructor.collections ? {}
			continue if @[name]
			observable = build_observable.call @, name, ko.observableArray, options.initial
			for method in ["pop", "push", "reverse", "shift", "sort", "splice", "unshift", "slice", "remove", "removeAll", "destroy", "destroyAll", "indexOf"]
				do (observable, method) ->
					observable[method] = ->
						observable.state[method].apply observable.state, arguments
				true
			@[name] = observable
			true
								
		# Create dependent observables for relations (this is a crude way to do this)
		@_methods = []
		@_constraints = []
		for constraint in @.constructor.relations ? []
			idx = @_constraints.push new Argure.Constraint constraint
			for method in @_constraints[idx-1].methods
				do (method) =>
					@_methods.push ko.dependentObservable ->
						@[method.output].state method.body.apply(this, (ko.utils.unwrapObservable(@[name]) for name in method.inputs))
						null
					, @

		for name, validators of @.constructor.validators ? {}
			do (name, validators) =>
				@[name].errors = ko.dependentObservable ->
					valid = true
					for v in validators
						result = v.call(@)
						valid &&= result
					return !valid  # Observable returns true if error, false otherwise
				, @
				null


		# Apply delays
		for fn in @.constructor._delays ? {}
			fn.call(@)


	@_delayed: (fn) ->
		@_delays ?= []
		@_delays.push(fn)

	Argure.Extensions.Validate.call @  # Add validate extensions by default
	@include: (mixin) ->
		throw new Error("Mixin must be a function") if typeof mixin != "function"
		mixin.call @
	
	@observe: (name, options=undefined) ->
		@observables ?= {}
		throw new Error("Observable #{name} already exists") if @observables[name]?
		@observables[name] = options ? {}

	@collection: (name, options=undefined) ->
		@collections ?= {}
		throw new Error("Collection #{name} already exists") if @collections[name]?
		@collections[name] = options ? {}

	@relate: (methods) ->
		@relations ?= []
		throw new Error("You must specify constraint methods") if typeof methods != "function"
		@relations.push(methods)

	@validate: (name, validator, message=undefined) ->
		validator.message = message
		((@validators ?= {})[name] ?= []).push(validator)
		


namespace 'Argure', (exports) ->
	exports.Model = Model
