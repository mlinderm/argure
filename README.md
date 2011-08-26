Argure.js
=========

Readme
This system is a JavaScript library designed for simplifying web-based user interface (UI) programming. In this system, we try to provide a clean and easy-to-use interface for programmers to maintain complicated relationships between UI elements. So that UI programming would become easier.

1.	Installation.
To use our system, please download jquery-1.6.js, jquery.tmpl.js, knockout-1.2.1.debug.js, argure.js from our github repository, and just simply include them as script on your webpages.
For example, 
```html
<script src="jquery-1.6.js"></script>
<script src="jquery.tmpl.js"></script>
<script src="knockout-1.2.1.debug.js"></script>
<script src="javascripts/argure.js"></script>
```
2.	An introductory example. 
Form: 	
```HTML
<form id="Addition">
	<p>A example that show how addition works. "A + B = C"</p>
	<label for="A">A</label>
	<input type="text" id="A" data-bind="value: A"/>
	<br />
	<label for="B">B</label>
	<input type="text" id="B" data-bind="value: B"/>
	<br />
	<label for="C">C</label>
	<input type="text" id="C" data-bind="value: C"/>
	<br />
	</form>
```
Script:
```CoffeeScript
class Add extends Argure.Model
	constructor: () ->
		super()
	@observe 'A'
	@observe 'B'
	@observe 'C'
	@relate (c) ->
		c.method 'C = A*1 + B*1'
		c.method 'A = C - B'
		c.method 'B = C - A'
this.Add = new Add()
ko.applyBindings(this.Add)
```
