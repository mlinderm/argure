class Model
	constructor: ->
		# Convert observables into corresponding knockout observables
		for name, options of @.constructor.observables
			do (name, options) =>  # Create closure around each observable's name and options
				state = "_" + name
				@[state] = ko.observable options.initial
				@[name] = ko.dependentObservable
					read: -> @[state]()
					write: (value) -> @[state](value)
					owner: @
		# Create dependent observables for relations (this is a crude way to do this)
		@methods = []
		for constraints in @.constructor.relations
			for name, method of constraints
				do (name, method) =>
					@methods.push ko.dependentObservable ->
						@[name](method.call(this))
					, @

	@observe: (name, options=undefined) ->
		@observables ?= {}
		throw new Error("Observable #{name} already exists") if @observables[name]?
		@observables[name] = options ? {}

	@relate: (methods) ->
		@relations ?= []
		throw new Error("You must specify constraint methods") if !(methods instanceof Object)
		@relations.push(methods)

namespace 'Argure', (exports) ->
	exports.Model = Model
