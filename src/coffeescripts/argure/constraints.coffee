class Method
	constructor: (@inputs, @output, @body) ->
		

class Constraint
	constructor: (formulas) ->
		@methods = []
		if typeof formulas == "function"
			formulas.call(this, this)
		else
			throw new Error("Only object-based constraints are supported")
	
	method: (args_or_code, body) ->
		[output, inputs] = [undefined, []]
		for o, i of args_or_code
			[output, inputs] = [o, i]
		@methods.push new Method inputs, output, body


namespace 'Argure', (exports) ->
	exports.Constraint = Constraint
