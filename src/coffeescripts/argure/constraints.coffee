class Method
	constructor: (@inputs, @output, @body, @condition) ->
		

class Constraint
	constructor: (formulas, id) ->
		@methods = []
		@id = id
		@currentMethod = undefined
		if typeof formulas == "function"
			formulas.call(this, this)
		else
			throw new Error("Only object-based constraints are supported")
	
	method: (args_or_code, body, condition) ->
		[output, inputs] = [undefined, []]
		for o, i of args_or_code
			[output, inputs] = [o, i]
		@methods.push new Method inputs, output, body, condition


namespace 'Argure', (exports) ->
	exports.Constraint = Constraint
