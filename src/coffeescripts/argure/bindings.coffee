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
				@[name+'_opts'].subscribe =>
					orphans = (item for item in @[name+'_slct'].state() when @[name+'_opts'].state.indexOf(item) < 0)
					this[name+'_slct'].state.removeAll(orphans) if orphans.length
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
	exports.Set = apply_set_extensions
