class Model
	constructor: ->
		@priCounter=0
		@obsCounter=0
		@cnCounter=0
		# Convert observables into corresponding knockout observables
		for name, options of @.constructor.observables ? {}
			do (name, options) =>  # Create closure around each observable's name and options
				id = @obsCounter++
				cnToNotify = []
				state    = ko.observable options.initial
				priority = ko.observable 0
				argure_observable = ko.dependentObservable
					read : -> state()
					write: (value) ->
						priority(++@priCounter)
						state(value)
						for cn in @[name].cnToNotify
							@notifyCn(cn)
						return null
					owner: @

				argure_observable.state = state
				argure_observable.priority = priority
				argure_observable.id = id
				argure_observable.cnToNotify = cnToNotify
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
			idx = @constraints.push new Argure.Constraint constraint, @cnCounter++
			for method in @constraints[idx-1].methods
				do (method) =>
					for input in method.inputs
						if @[input].cnToNotify != undefined and @[input].cnToNotify.indexOf(constraint)==-1
							@[input].cnToNotify.push(@constraints[idx-1])
					if @[method.output].cnToNotify != undefined and @[method.output].cnToNotify.indexOf(constraint)==-1
						@[method.output].cnToNotify.push(@constraints[idx-1])
#					@_methods.push ko.dependentObservable ->
#						@[method.output].state method.body.apply(this, (ko.utils.unwrapObservable(@[name]) for name in method.inputs))
#					, @

		@notifyObs = (obs) ->
			for cn in @[obs].cnToNotify
				@notifyCN(cn)

		@notifyCn = (cn) ->
			oldMethod = cn.currentMethod
			if(oldMethod!=undefined)
				oldValue = @[oldMethod.output].state()
				oldPri = @[oldMethod.output].priority()
			minPri = Infinity
			minMethod = undefined
			for method in cn.methods
				if @[method.output].priority() < minPri
					minPri = @[method.output].priority()
					minMethod = method
			if minMethod == undefined
				throw new Error("The graph is over constrainted.")
			else
				@[minMethod.output].state minMethod.body.apply(this, (ko.utils.unwrapObservable(@[name]) for name in minMethod.inputs))
#				cnGraph.detectCycle()
				if(minMethod == oldMethod)
					if(@[minMethod.output].state() == oldValue and minPri == oldPri)
						return
				cn.currentMethod = minMethod
				@[minMethod.output].priority(minPri)
				@notifyObs(minMethod.output)
				return
	

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
