#
# Default Knockout "Constraint" Solver
#
apply_knockout_solver = ->
	@build_observable_callback ?= (name, observable_kind, initial_value) ->
		state = observable_kind initial_value
		argure_observable = ko.dependentObservable
			read : -> state()
			write: (value) ->
				state(value)
				return null
			owner: @
		argure_observable.cell = name
		argure_observable.state = state
		return argure_observable
	
	@build_constraint_callback ?= (constraint) ->
		for method in constraint.methods
			do (method) =>
				ko.dependentObservable ->
					@[method.output].state method.body.apply(@, (ko.utils.unwrapObservable(@[name]) for name in method.inputs))
					null
				, @


#
# DeltaBlue multi-way constraint solver 
#
apply_deltaBlue_solver = ->
	@build_observable_callback ?= (name, observable_kind, initial_value) ->
		state    = observable_kind initial_value
		priority = ko.observable @priority(false)
		wkStrength = if initial_value!=undefined then 0 else -1
		_constraints = []
		observable = ko.dependentObservable
			read : -> state()
			write: (value) ->
				priority(@priority())
				wkStrength = @priority(false)
				state(value)
				@addConstraint(cn, name) for cn in _constraints
				return null
			owner: @
		observable.cell = name
		observable.state = state
		observable.priority = priority
		observable.wkStrength = (value) ->
			wkStrength = value if value?
			wkStrength
		observable.constraints = (value) ->
			_constraints = _.union(_constraints, value) if value?
			_constraints

		return observable
	
	@build_constraint_callback ?= (c)->
		for method in c.methods
			@[method.output].constraints?(c)
			@[i].constraints?(c) for i in method.inputs
		null

	@_delayed ->
		@decreaseStrength = (obs, preCn) ->
			for cn in @[obs].constraints() when cn!= preCn
				oldMethod = cn.currentMethod
				[oldValue, oldStrength] = [@[oldMethod.output].state(), @[oldMethod.output].wkStrength()] if oldMethod?
				@[oldMethod.output].wkStrength(@[oldMethod.output].priority())
				@addConstraint(cn,obs) for cn in @[obs].constraints() when cn!=preCn
				if(oldMethod.output!=undefined and oldStrength != @[oldMethod.output].wkStrength())
					@decreaseStrength(oldMethod.output, cn)

		# Enforce
		@addConstraint= (cn, preObs) ->
			# Selected Method
			oldMethod = cn.currentMethod
			[oldValue, oldStrength] = [@[oldMethod.output].state(), @[oldMethod.output].wkStrength()] if oldMethod?
			
			minStr = Infinity
			minMethod = undefined
			for method in cn.methods
				if @[method.output].wkStrength() < minStr
					minStr = @[method.output].wkStrength()
					minMethod = method
			if minStr == oldStrength
				minMethod = oldMethod # Try to keep the old one if possible
			
			for input in minMethod.inputs
				if @[input]==undefined || @[input].wkStrength?() == -1
					return # Uninitialized Input
			
			# Walkabout strength is the weakest of all potential outputs
			newStrength = _.min (@[m.output].wkStrength() for m in cn.methods when m != minMethod)
			
			if minMethod == undefined
				throw new Error("The graph is over constrainted.")
			else
				if minMethod.condition != undefined
					if minMethod.condition.apply(this, (ko.utils.unwrapObservable(@[name]) for name in minMethod.inputs)) != true # Execute Condition
						if cn.currentMethod ==undefined
							return null
						cn.currentMethod = undefined
						@[oldMethod.output].wkStrength(@[oldMethod.output].priority())
						@decreaseStrength(oldMethod.output, cn)
						return null
				@[minMethod.output].state minMethod.body.apply(this, (ko.utils.unwrapObservable(@[name]) for name in minMethod.inputs)) # Execute Method
#				cnGraph.detectCycle()
				if(minMethod == oldMethod)
					if(@[minMethod.output].state() == oldValue and newStrength == oldStrength)
						return null
				cn.currentMethod = minMethod
				@[minMethod.output].wkStrength(newStrength)
				
				@addConstraint(nextCn, minMethod.output) for nextCn in @[minMethod.output].constraints() when nextCn != cn
				return null

 		null
	@_delayed ->
		for name, options of @.constructor.observables
			for cn in @[name].constraints()
				@addConstraint(cn)


#
# Validate Extensions
#
apply_validate_extensions = ->
	ko.bindingHandlers.validate ?=
		update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
			value = valueAccessor()
			$(element).children('.argure-error-message').remove()
			if ko.utils.unwrapObservable(value.errors)  # Insert error messages if they exist
				$(element).prepend """
				<div class='argure-error-message'>
					<strong>Errors Detected:</strong>
					<nl>
						#{"<li>#{msg}</li>" for msg in viewModel.errors.get(value.cell)}
					</nl>
				</div>
				"""
			ko.bindingHandlers.css.update element, (->
				{ "ui-state-error": value.errors } 
			), allBindingsAccessor, viewModel

	@validateRange ?= (name, min, max) ->
		@validate name, ->
			return max >= @[name]() >= min
		, "#{name} not in valid range of #{min}..#{max}"


#
# Set Extensions
#
apply_set_extensions = ->
	@collectionMultiSelect ?= (name, options=undefined) ->
		@collection name+'_opts', initial: options?.initialOpts
		@collection name+'_slct', initial: options?.initialSlct ? []
		
		# Create a meta property that can be used in bindings, etc. 
		@_delayed ->
			@[name] =
				opts: @[name+'_opts']
				slct: @[name+'_slct']
			null

		# The default for knockout is that the "selections" do not change
		# when the options do, e.g., "deleting" an option does not delete
		# the corresponding option from the selected options. This 
		# subscription fixes that by propagrating removals...
		@_delayed ->
			if ko.isObservable(@[name+'_opts']) && ko.observable(@[name+'_slct'])
				@[name+'_opts'].state.subscribe (value) =>
					orphans = (item for item in @[name+'_slct'].state() when value.indexOf(item) < 0)
					if orphans.length
						this[name+'_slct'].state.removeAll(orphans)
						@addConstraint(cn, name+'_slct') for cn in @[name+'_slct'].constraints()
					null

		
	ko.bindingHandlers.collectionMultiSelect ?=
		init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
			ko.bindingHandlers.selectedOptions.init(element, (-> valueAccessor().slct ), allBindingsAccessor, viewModel)
			null
		update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
			ko.bindingHandlers.options.update element, (-> valueAccessor().opts ), allBindingsAccessor, viewModel
			ko.bindingHandlers.selectedOptions.update element, (-> valueAccessor().slct ), allBindingsAccessor, viewModel
			null

	# Automatically match observable object to template name, set foreach, etc.
	ko.bindingHandlers.collectionTemplate ?=
		update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
			value = valueAccessor()
			ko.bindingHandlers.template.update element, (->
				name: value.cell + "Template"
				foreach: value
				templateOptions: { parentCollection: value, uqId: _.uniqueId() }
			), allBindingsAccessor, viewModel
# /SetExtensions

namespace 'Argure.Extensions', (exports) ->
	exports.Knockout = apply_knockout_solver
	exports.DeltaBlue = apply_deltaBlue_solver
	exports.Set = apply_set_extensions
	exports.Validate = apply_validate_extensions
