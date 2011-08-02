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
	constructor: (@constraint, @inputs=undefined, @output=undefined, @body=undefined, @condition=undefined) ->
		#constructor: (@inputs, @output, @body, @condition) ->
	
	when: (body_or_code) ->
		@condition = body_or_code
		@

	method: (args_or_code, body) ->
		# Compile main body of method
		if typeof args_or_code == "string"
			ast = CoffeeScript.nodes args_or_code
		
			# We are looking for Block -> Assign
			assignment = ast.unwrap()
			if assignment.constructor.name == "Assign"
				[@output] = extract_operands assignment.variable # LHS
				@inputs   = extract_operands assignment.value    # RHS
				@body     = assignment.value.compile()           # Compile RHS
			else
				throw new Error "Ill-formed constraint method: No assignment found"

		else if typeof args_or_code == "object"
			for o, i of args_or_code
				[@output, @inputs] = [o, i]
			@body = body
		else
			throw new Error("Unsupported method specification")

		# Handle conditional if present...
		@condition = (
			if typeof @condition == "string"
				ast = (CoffeeScript.nodes @condition).unwrap()
				@inputs = _.union @inputs, extract_operands(ast)
				ast.compile()
			else
				@condition
		) if @condition?

		# Complete compilation (requires knowing all possible inputs)...
		eval "this.condition = function(#{@inputs.join ','}) { return #{@condition}; }" if @condition? && typeof @condition != "function"
		eval "this.body = function(#{@inputs.join ','}) { return #{@body}; }" if typeof @body != "function"

		@constraint.methods.push @
		@


class Constraint
	constructor: (formulas) ->
		@methods = []
		formulas.call(this, this)

	when: (body_or_code) ->
		return (new Method(@)).when body_or_code

	method: (args_or_code, body) ->
		return (new Method(@)).method args_or_code, body
		

namespace 'Argure', (exports) ->
	exports.Constraint = Constraint
