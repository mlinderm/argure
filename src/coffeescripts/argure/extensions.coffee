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
		argure_observable.observableName = name
		argure_observable.state = state
		argure_observable.errors = false  # Default is no errors
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
		wkStrength = 0
		cnToNotify = []
		argure_observable = ko.dependentObservable
			read : -> state()
			write: (value) ->
				priority(@priority())
				wkStrength = @priority(false)
				state(value)
				for cn in cnToNotify
					@notifyCn(cn,name)
				return null
			owner: @
		argure_observable.observableName = name
		argure_observable.state = state
		argure_observable.errors = false  # Default is no errors
		argure_observable.priority = priority
		argure_observable.wkStrength = (value) ->
			wkStrength = value if value?
			wkStrength
		argure_observable.cnToNotify = cnToNotify
		return argure_observable
	
	@build_constraint_callback ?= (constraint)->
		for method in constraint.methods
			do (method) =>
				for input in method.inputs
					if @[input].cnToNotify != undefined and @[input].cnToNotify.indexOf(constraint)==-1
						@[input].cnToNotify.push(constraint)
					if @[method.output].cnToNotify != undefined and @[method.output].cnToNotify.indexOf(constraint)==-1
						@[method.output].cnToNotify.push(constraint)

	@_delayed ->
		@notifyObs = (obs,preCn) ->
			for cn in @[obs].cnToNotify
				if cn != preCn
					@notifyCn(cn,obs)

		@notifyCn = (cn,preObs) ->
			oldMethod = cn.currentMethod
			if(oldMethod!=undefined)
				oldValue = @[oldMethod.output[0]].state()
				oldStr = @[oldMethod.output[0]].wkStrength()
			wkStrengthCorrect = false
			while (!wkStrengthCorrect)
				wkStrengthCorrect = true
				minStr = Infinity
				minMethod = undefined
				for method in cn.methods
					if @[method.output[0]].wkStrength() < minStr
						minStr = @[method.output[0]].wkStrength()
						minMethod = method
				if minStr == oldStr
					minMethod = oldMethod # Try to keep the old one if possible
				if minMethod != oldMethod and oldMethod != undefined and oldMethod.output[0] != preObs
					wkStrengthCorrect = false if @[oldMethod.output[0]].wkStrength() != @[oldMethod.output[0]].priority()
					@[oldMethod.output[0]].wkStrength(@[oldMethod.output[0]].priority()) # The original output[0] is free
																						  # Its stay constraint is redirected,	
									 											          # And its walk about strength should be equal to its priority
			newStr = Infinity
			for method in cn.methods
				if method == minMethod
					continue
				if @[method.output[0]].wkStrength() < newStr
					newStr = @[method.output[0]].wkStrength()

			if minMethod == undefined
				throw new Error("The graph is over constrainted.")
			else
				if minMethod.condition != undefined
					if minMethod.condition.apply(this, (ko.utils.unwrapObservable(@[name]) for name in minMethod.inputs)) != true # Execute Condition
						if cn.currentMethod ==undefined
							return null
						cn.currentMethod = undefined
						@[oldMethod.output[0]].wkStrength(@[oldMethod.output[0]].priority())
						@notifyObs(oldMethod.output[0], cn)
						return null
				@[minMethod.output[0]].state minMethod.body.apply(this, (ko.utils.unwrapObservable(@[name]) for name in minMethod.inputs)) # Execute Method
#				cnGraph.detectCycle()
				if(minMethod == oldMethod)
					if(@[minMethod.output[0]].state() == oldValue and newStr == oldStr)
						return null
				cn.currentMethod = minMethod
				@[minMethod.output[0]].wkStrength(newStr)
				@notifyObs(minMethod.output[0],cn)
				return null


	@_delayed ->
		for name, options of @.constructor.observables
			for cn in @[name].cnToNotify
				@notifyCn(cn)


#
# Validate Extensions
#
apply_validate_extensions = ->
	ko.bindingHandlers.validate ?=
		update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
			value = valueAccessor()
			$(element).children('.argure-error-message').remove()
			if value.errors()  # Insert error messages if they exist
				$(element).prepend """
				<div class='argure-error-message'>
					<strong>Errors Detected:</strong>
					<nl>
						#{"<li>#{msg}</li>" for msg in viewModel.errors.get(value.observableName)}
					</nl>
				</div>
				"""
			ko.bindingHandlers.css.update element, (->
				{ "ui-state-error": value.errors } 
			), allBindingsAccessor, viewModel



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

		#The default for knockout is that the "selections" do not change
		#when the options do, e.g., "deleting" an option does not delete
		# the corresponding option from the selected options. This 
		# subscription fixes that by propagrating removals...
		@_delayed ->
			if ko.isObservable(@[name+'_opts']) && ko.observable(@[name+'_slct'])
				@[name+'_opts'].state.subscribe (value) =>
					orphans = (item for item in @[name+'_slct'].state() when value.indexOf(item) < 0)
					if orphans.length
						this[name+'_slct'].state.removeAll(orphans)
						this.notifyObs(name+'_slct')
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
				name: value.observableName + "Template"
				foreach: value
				templateOptions: { parentCollection: value, uqId: _.uniqueId() }
			), allBindingsAccessor, viewModel
# /SetExtensions

namespace 'Argure.Extensions', (exports) ->
	exports.Knockout = apply_knockout_solver
	exports.DeltaBlue = apply_deltaBlue_solver
	exports.Set = apply_set_extensions
	exports.Validate = apply_validate_extensions
