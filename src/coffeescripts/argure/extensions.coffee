#
# Default Knockout "Constraint" Solver
#
apply_knockout_solver = ->
	@build_constraint_callback ?= (constraint) ->
		for method in constraint.methods
			do (method) =>
				ko.dependentObservable ->
					@[method.output].state method.body.apply(@, (ko.utils.unwrapObservable(@[name]) for name in method.inputs))
					null
				, @

apply_deltaBlue_solver = ->
	@build_constraint_callback ?= (constraint)->
			for method in constraint.methods
				do (method) =>
					for input in method.inputs
						if @[input].cnToNotify != undefined and @[input].cnToNotify.indexOf(constraint)==-1
							@[input].cnToNotify.push(constraint)
					if @[method.output].cnToNotify != undefined and @[method.output].cnToNotify.indexOf(constraint)==-1
						@[method.output].cnToNotify.push(constraint)


_obsCounter = 0
add_deltaBlue_observable = ->
	@build_observable_callback ?= () ->
		@id = _obsCounter++
		@cnToNotify = []
		@wkStrength = 0
		return null
#
# Validate Extensions
#
apply_validate_extensions = ->
	ko.bindingHandlers.validate ?=
		update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
			ko.bindingHandlers.css.update element, (->
				value = valueAccessor()
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
				templateOptions: { parentCollection: value }
			), allBindingsAccessor, viewModel
# /SetExtensions

namespace 'Argure.Extensions', (exports) ->
	exports.Knockout = apply_knockout_solver
	exports.DeltaBlueSolver = apply_deltaBlue_solver
	exports.DeltaBlueObservable = add_deltaBlue_observable
	exports.Set = apply_set_extensions
	exports.Validate = apply_validate_extensions
