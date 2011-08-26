Argure.js
=========
Readme

This system is a JavaScript library designed for simplifying web-based user interface (UI) programming. In this system, we try to provide a clean and easy-to-use interface for programmers to maintain complicated relationships between UI elements. So that UI programming would become easier.

1.	Installation.
Please download jquery-1.6.js, jquery.tmpl.js, knockout-1.2.1.debug.js, argure.js from our github repository, and just simply include them as script on your webpages.
For example, 

```html
<script src="jquery-1.6.js"></script>
<script src="jquery.tmpl.js"></script>
<script src="knockout-1.2.1.debug.js"></script>
<script src="javascripts/argure.js"></script>
```

2.	An introductory example. 

Form: 	

```html
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

```coffeescript
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

To use our system, programmers should specify two different parts, HTML form and a script for specifying the model.

The HTML form is responsible for the appearance of the UI, and should be specified by standard HTML language. Note that the ¡§data-bind¡¨ property is used to connect HTML form elements with JavaScript variable, and is a necessary property for Knockout. Please check Knockout¡¦s webpage for more details.

We suggest CoffeeScript as the language for specifying the model, as it is cleaner and easier to use. To specify the model, programmers should declare a class inheriting Argure.Model, create a class instance, and pass it into ko.applyBindings. The content of the class may consists of some of the following components,

a.	Variable:

```coffeescript
@observable name
```
Programmers can specify the html form elements that should be maintained by system by declaring variable. Note that the names here should be the same as the ones specified on the html form.
b.	Constraint:

```coffeescript
@relate (c) -> 
	c.method relationship # unconditional method
	c.when(condition).method relationship # conditional method
```

Programmers can specify the relationship between variables with constraints. Each constraint represent a relationship to be maintained, and should consist of one or more constraint satisfaction methods (CSM). It is programmer¡¦s responsibility to guarantee after executed one of these methods, the relationship will be satisfied. When the UI is running, our system will maintain the relationship by executing the most appropriate CSM for each constraint.
c.	Validation: 

```coffeescript
@validate name, validation function, message
```

Programmers can trace the value of variable and provide corresponding message to users by specifying validations. When the return value of the validation function is false, our system will output the message to users.
d.	Callback function:

```coffeescript
@preCall name, function // pre-callback function
@postCall name, function // post-callback function
```

Programmers can specify additional actions when users change the value of a variable by specifying callback functions. Our system provides two types of callback functions. Pre-callback function will work before the automatic update of the system and post-callback function will work after the automatic update.

e.	Other components:
We also implement other components that provide more specific operation. Please check appendix and examples for more details.

