Argure.js
=========

'''javascript
class ExtractOperandsVisitor extends ASTVisitor
	constructor: ->
		@operands = []
	
	default: (node) -> true
	Value: (node) ->
		@operands.push node.base.value if node.isAssignable()
		true
'''

An experiment in using [property
models](http://parasol.tamu.edu/~jarvi/papers/gpce08.pdf) and functional
reactive programming for command synthesis.
