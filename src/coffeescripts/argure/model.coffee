class Model
	constructor: ->
		@priCounter=0

		# Convert observables into corresponding knockout observables
		for name, options of @.constructor.observables ? {}
			do (name, options) =>  # Create closure around each observable's name and options
				state    = ko.observable options.initial
				priority = ko.observable 0
				argure_observable = ko.dependentObservable
					read : -> state()
					write: (value) ->
						priority(++@priCounter)
						state(value)
						return null
					owner: @
			
				argure_observable.state = state
				argure_observable.priority = priority
				@[name] = argure_observable

		# Convert collections into corresponding knockout observable arrays
		for name, options of @.constructor.collections ? {}
			do (name, options) =>
				state = ko.observableArray options.initial
				priority = ko.observable 0
				argure_observable = ko.dependentObservable
					read: -> state()
					write: (value) ->
						priority(++@priCounter)
						state(value)
						return null
					owner: @
				
				for method in ["pop", "push", "reverse", "shift", "sort", "splice", "unshift", "slice", "remove", "removeAll", "destroy", "destroyAll", "indexOf"]
					do(method) ->
						argure_observable[method] = ->
							state[method].apply state, arguments
				argure_observable.state = state
				argure_observable.priority = priority
				@[name] = argure_observable

		# Create dependent observables for relations (this is a crude way to do this)
		@_methods = []
		@constraints = []
		for constraint in @.constructor.relations ? []
			idx = @constraints.push new Argure.Constraint constraint
			for method in @constraints[idx-1].methods
				do (method) =>
					@_methods.push ko.dependentObservable ->
						@[method.output].state method.body.apply(this, (ko.utils.unwrapObservable(@[name]) for name in method.inputs))
					, @

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

namespace 'Argure', (exports) ->
	exports.Model = Model
