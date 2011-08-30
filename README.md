This system is a JavaScript library designed for simplifying web-based user interface (UI) programming. We build this system on Knockout, also an open source JavaScript library, to simplify the connection of JavaScript variables and HTML form elements. The goal of this system is to provide a clean and easy-to-use interface for programmers to maintain complicated relationships between UI elements, and thus make UI programming easier.



1. Installation.

Please download jquery-1.6.js, jquery.tmpl.js, knockout-1.2.1.debug.js, argure.js from our github repository, and include them as script on your webpages.

For example, 

```html
<script src="jquery-1.6.js"></script>
<script src="jquery.tmpl.js"></script>
<script src="knockout-1.2.1.debug.js"></script>
<script src="javascripts/argure.js"></script>
```


2. An introductory example.

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

To use our system, programmers should specify two different parts, HTML form and a script that specifies the model.

The HTML form is responsible for the appearance of the UI, and should be specified by the standard HTML language. Note that the ¡§data-bind¡¨ property is used to connect HTML form elements with JavaScript variables, and is a necessary property for Knockout to work. Please check the webpage of Knockout for more details.
  
We suggest CoffeeScript as the language for specifying the model, as it is cleaner and easier to use. To specify the model, programmers should declare a class inheriting 
Argure.Model, create a class instance, and pass it into ko.applyBindings. The content of the class may consists of some of the following components,

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

Programmers can specify the relationships between variables by declaring constraints. Each constraint represent a relationship to be maintained, and should consist of one or more constraint satisfaction methods (CSM). It is programmer¡¦s responsibility to guarantee after executed one of these methods, the relationship will be satisfied. When the UI is running, our system will maintain the relationship by executing the most appropriate CSM for each constraint.

c.	Validation: 

```coffeescript
@validate name, validation function, message
```

Programmers can trace the value of variables and provide corresponding message to users by specifying validations. When the return value of the validation function is false, our system will output the message on the user interface.

d.	Callback function:

```coffeescript
@preCall name, function # pre-callback function
@postCall name, function # post-callback function
```

Programmers can specify additional actions when users change the value of a variable by specifying callback functions. Our system provides two types of callback functions, pre-callback functions that work before the automatic update of the system, and post-callback functions that work after the automatic update.

e.	Other components:

We also implement other components that provide more specific operation. Please check the appendix and examples for more details.

  In the following section, we will explain how our system works in more details.



3. The constraint system

We use multi-way, single-output constraint system to maintain relationships between variables. 

When the UI start to execute, our system will generate a constraint graph corresponding to the variables and constraints declared by programmers. And while the UI is executing, our system will dynamically compute the value on UI elements by solving the constraint graph. 

Generally, multi-way constraint systems usually have multiple solutions, as there are many CSMs to choose in each constraint. But usually the solution that user expects is the one that keeps the value of a set of UI elements that are modified most recently. To generate this particular solution, we add a priority to each variable according to the time it changed by the user, and solve the constraint graph according to the locally-predicate-better criteria. 

To do this, we use a modified version of DeltaBlue algorithm as the constraint solver of our system. This algorithm is capable of generating the locally-predicate- better solution with time complexity linear to the number of variables. Please note that when inconsistencies exist and cause a direct cycle on the constraint graph, the algorithm will not solve it automatically, as we think it may be better to let user decide how to proceed. Instead, our system will halt and prompt a message when cycle is detected, and thus some of the relationships may be temporary unsatisfied. These relationships will be satisfied again after user decide how to deal with the inconsistency.

You can find more details of our algorithm in Algorithm.pdf.


4.	Reference

To learn more about our algorithm and system, you may want to check the following links.

[Knockout]( http://knockoutjs.com/)

[CoffeeScript]( http://jashkenas.github.com/coffee-script/)

[DeltaBlue Algorithm]( http://dl.acm.org/citation.cfm?id=77531)





