class Errors
	constructor: ->
		errors = {}
	
		@empty = ->
			@size() == 0
		@size = ->
			_.reduce (errors[k].length for k in _.keys(errors)), ((m, k) -> m+k), 0
		@clear = (name=undefined) ->
			if name? then delete errors[name] else errors = {}
			@
		@get = (name) ->
			errors[name]
		@add = (name, message) ->
			(errors[name] ?= []).push message
			@

#/Errors



class Model
	constructor: (parent=undefined)->
		
		# Inherit errors and priority from "parent" Model
		[@errors, @priority] = if parent? && parent instanceof Model
			[parent.errors, parent.priority]
		else
			_priority_counter = 0
			[new Errors(), ((inc=true) -> if inc then ++_priority_counter else _priority_counter)]
		
		# Convert observables into corresponding knockout observables
		for name, options of @.constructor.observables ? {}
			continue if @[name]
			observable = @.constructor.build_observable_callback.call @, name, ko.observable, options.initial
			observable.errors = false  # Default is no errors
			@[name] = observable
			null

		# Convert collections into corresponding knockout observable arrays
		for name, options of @.constructor.collections ? {}
			continue if @[name]
			observable = @.constructor.build_observable_callback.call @, name, ko.observableArray, options.initial
			observable.errors = false  # Default is no errors
			for method in ["pop", "push", "reverse", "shift", "sort", "splice", "unshift", "slice", "remove", "removeAll", "destroy", "destroyAll", "indexOf"]
				do (observable, method) ->
					observable[method] = ->
						observable.state[method].apply observable.state, arguments
				true
			@[name] = observable
			null
								
		# Create dependent observables via callback 
		@_methods = []
		for constraint in @.constructor.relations ? []
			con = new Argure.Constraint constraint
			@_methods.push @.constructor.build_constraint_callback?.call @, con

		# Apply delays
		for fn in @.constructor._delays ? {}
			fn.call(@)

		# Apply validations after delays (and other setup)
		for name, validators of @.constructor.validators ? {}
			do (name, validators) =>
				@[name].errors = ko.dependentObservable ->
					valid = true
					@.errors.clear name
					for v in validators
						result = v.call @
						@.errors.add name, v.message if !result
						valid &&= result
					return !valid  # Observable returns true if error, false otherwise
				, @
				null



	@_delayed: (fn) ->
		@_delays ?= []
		@_delays.push(fn)

	Argure.Extensions.DeltaBlue.call @
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
		validator.message = message ? "${name} failed validation"
		((@validators ?= {})[name] ?= []).push(validator)
		


namespace 'Argure', (exports) ->
	exports.Model = Model
