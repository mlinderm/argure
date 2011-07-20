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
				wkStrength = 0
				argure_observable = ko.dependentObservable
					read : -> state()
					write: (value) ->
						priority(++@priCounter)
						argure_observable.wkStrength = @priCounter
						state(value)
						for cn in @[name].cnToNotify
							@notifyCn(cn)
						return null
					owner: @

				argure_observable.state = state
				argure_observable.priority = priority
				argure_observable.wkStrength = wkStrength
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
						if @[input].cnToNotify != undefined and @[input].cnToNotify.indexOf(@constraints[idx-1])==-1
							@[input].cnToNotify.push(@constraints[idx-1])
					if @[method.output].cnToNotify != undefined and @[method.output].cnToNotify.indexOf(@constraints[idx-1])==-1
						@[method.output].cnToNotify.push(@constraints[idx-1])
#					@_methods.push ko.dependentObservable ->
#						@[method.output].state method.body.apply(this, (ko.utils.unwrapObservable(@[name]) for name in method.inputs))
#					, @

		@notifyObs = (obs,preCn) ->
			for cn in @[obs].cnToNotify
				if cn != preCn
					@notifyCn(cn)

		@notifyCn = (cn) ->
			oldMethod = cn.currentMethod
			if(oldMethod!=undefined)
				oldValue = @[oldMethod.output].state()
				oldStr = @[oldMethod.output].wkStrength
			minStr = Infinity
			subminStr = Infinity
			minMethod = undefined
			for method in cn.methods
				if @[method.output].wkStrength < minStr
					subminStr = minStr
					minStr = @[method.output].wkStrength
					minMethod = method
				else if @[method.output].wkStrength < subminStr
					subminStr = @[method.output].wkStrength
			if minStr == oldStr
				minMethod = oldMethod # Try to keep the old one if possible
			if minMethod == undefined
				throw new Error("The graph is over constrainted.")
			else
				@[minMethod.output].state minMethod.body.apply(this, (ko.utils.unwrapObservable(@[name]) for name in minMethod.inputs)) # Execute Method
#				cnGraph.detectCycle()
				if(minMethod == oldMethod)
					if(@[minMethod.output].state() == oldValue and subminStr == oldStr)
						return
				cn.currentMethod = minMethod
				@[minMethod.output].wkStrength = subminStr
				@notifyObs(minMethod.output,cn)
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
