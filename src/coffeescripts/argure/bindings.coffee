buildSetObservable = (viewModel, set) ->
	if typeof set == 'function' then ko.dependentObservable(set, viewModel) else ko.observableArray(set)


Many = (set=[]) ->
	new Argure.ModelHelper ->
		set: buildSetObservable(this, set)

namespace 'Argure', (exports) ->
	exports.Many = Many



ManyFromMany = (superset=[], subset=[]) ->
	new Argure.ModelHelper ->
		superset: buildSetObservable(this, superset)
		subset:   buildSetObservable(this, subset)

namespace 'Argure', (exports) ->
	exports.ManyFromMany = ManyFromMany


# Create the associated binding for knockout.js
ko.bindingHandlers.manyFromMany =
	init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
		ko.bindingHandlers.selectedOptions.init(element, (-> valueAccessor().subset ), allBindingsAccessor, viewModel)
		null
	update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
		ko.bindingHandlers.options.update(element, (-> valueAccessor().superset ), allBindingsAccessor, viewModel)
		ko.bindingHandlers.selectedOptions.update(element, (-> valueAccessor().subset ), allBindingsAccessor, viewModel)
		null

ko.bindingHandlers.displayMany =
	update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
		template = allBindingsAccessor()['displayTemplate']
		throw new Error "'displayTemplate' binding needed when using 'displayMany'" if !template?
		ko.bindingHandlers.template.update(element, (->
			name: template
			foreach: valueAccessor().set
			templateOptions:
				model: viewModel
		), allBindingsAccessor, viewModel)
		null
		
