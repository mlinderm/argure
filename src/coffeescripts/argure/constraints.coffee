class ASTVisitor
	apply: (node) ->
		result = @[node.constructor.name]?(node) ? (@.default?(node) ? false)
		return result && node.eachChild (node) =>
			@.apply(node)


class ExtractOperandsVisitor extends ASTVisitor
	constructor: ->
		@operands = []
	
	default: (node) -> true
	Value: (node) ->
		@operands.push node.base.value if node.isAssignable()
		true

extract_operands = (ast) ->
	v = new ExtractOperandsVisitor
	v.apply(ast)
	return _.uniq v.operands


class Method
	constructor: (@inputs, @output, @body, @condition) ->
		

class Constraint
	constructor: (formulas) ->
		@methods = []
		@currentMethod = undefined
		@cycleDetectionNum = 0
		formulas.call(this, this)
	
	method: (args_or_code, body, condition) ->
		if typeof args_or_code == "string"
			ast = CoffeeScript.nodes args_or_code
		
			# We are looking for Block -> Assign
			assignment = ast.unwrap()
			if assignment.constructor.name == "Assign"
				[output] = extract_operands assignment.variable  # LHS
				inputs = extract_operands assignment.value     # RHS
				eval "body = function(#{inputs.join ','}) { return #{assignment.value.compile()}; }"  # Convert RHS to function
				@methods.push new Method inputs, output, body, condition
			else
				throw new Error "Ill formed constraint method: no inputs or output found" if !ev.inputs? || !ev.output?

		else if typeof args_or_code == "object"
			for o, i of args_or_code
				[output, inputs] = [o, i]
			@methods.push new Method inputs, output, body, condition
		else
			throw new Error("Unsupported method specification")

namespace 'Argure', (exports) ->
	exports.Constraint = Constraint
