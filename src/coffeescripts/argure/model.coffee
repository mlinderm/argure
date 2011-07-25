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
		@notifyObs = (obs,preCn) ->
			for cn in @[obs].cnToNotify
				if cn != preCn
					@notifyCn(cn,obs)

		@notifyCn = (cn,preObs) ->
			oldMethod = cn.currentMethod
			if(oldMethod!=undefined)
				oldValue = @[oldMethod.output[0]].state()
				oldStr = @[oldMethod.output[0]].wkStrength
			wkStrengthCorrect = false
			while (!wkStrengthCorrect)
				wkStrengthCorrect = true
				minStr = Infinity
				minMethod = undefined
				for method in cn.methods
					if @[method.output[0]].wkStrength < minStr
						minStr = @[method.output[0]].wkStrength
						minMethod = method
				if minStr == oldStr
					minMethod = oldMethod # Try to keep the old one if possible
				if minMethod != oldMethod and oldMethod != undefined and oldMethod.output[0] != preObs
					wkStrengthCorrect = false if @[oldMethod.output[0]].wkStrength != @[oldMethod.output[0]].priority()
					@[oldMethod.output[0]].wkStrength = @[oldMethod.output[0]].priority() # The original output[0] is free
																						  # Its stay constraint is redirected,	
									 											          # And its walk about strength should be equal to its priority
			newStr = Infinity
			for method in cn.methods
				if method == minMethod
					continue
				if @[method.output[0]].wkStrength < newStr
					newStr = @[method.output[0]].wkStrength

			if minMethod == undefined
				throw new Error("The graph is over constrainted.")
			else
				if minMethod.condition != undefined
					if minMethod.condition.apply(this, (ko.utils.unwrapObservable(@[name]) for name in minMethod.inputs)) != true # Execute Condition
						if cn.currentMethod ==undefined
							return null
						cn.currentMethod = undefined
						@[oldMethod.output[0]].wkStrength = @[oldMethod.output[0]].priority()
						@notifyObs(oldMethod.output[0], cn)
						return null
				@[minMethod.output[0]].state minMethod.body.apply(this, (ko.utils.unwrapObservable(@[name]) for name in minMethod.inputs)) # Execute Method
#				cnGraph.detectCycle()
				if(minMethod == oldMethod)
					if(@[minMethod.output[0]].state() == oldValue and newStr == oldStr)
						return null
				cn.currentMethod = minMethod
				@[minMethod.output[0]].wkStrength = newStr
				@notifyObs(minMethod.output[0],cn)
				return null


		@errors = new Errors()


		_priCounter=0
		_cnCounter=0

		build_observable = (name, observable_kind, initial_value) ->
			state    = observable_kind initial_value
			priority = ko.observable 0
			argure_observable = ko.dependentObservable
				read : -> state()
				write: (value) ->
					priority(++_priCounter)
					argure_observable.wkStrength = _priCounter
					state(value)
					for cn in @[name].cnToNotify
						@notifyCn(cn,name)
					return null
				owner: @
			argure_observable.observableName = name
			argure_observable.state = state
			argure_observable.priority = priority
			argure_observable.errors = false  # Default is no errors
			@.constructor.build_observable_callback?.call argure_observable
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
		for constraint in @.constructor.relations ? []
			con = new Argure.Constraint constraint
			@_methods.push @.constructor.build_constraint_callback?.call @, con

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

	Argure.Extensions.DeltaBlueSolver.call @
	Argure.Extensions.DeltaBlueObservable.call @
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
