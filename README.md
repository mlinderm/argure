Argure.js
=========

An experiment in using property models and functional reactive programming for
command synthesis.

Background
----------

The role of the user interface is to enable the user to select valid parameter
values for a command or function to be executed in a program (or as the
program). There can be a substantial distance between the interface exposed by
the underlying the command, e.g. its arguments, and the most productive user
interface (UI). Closing this gap will increase producivity and expand the pool
of users who can take advantage of computational tools.

The reader has (hopefully) used applications with intuitive, feature-rich,
defect-free UIs. Qualitatively, these tend to be widely-used commercial
applications built by large corporations with substantial engineering and test
resources (and unsurprisingly UI code comprises some 30-50% of the
applications' code and still a disproportionate share of the
bugs[reference_link][jarvi2008]). The reader has presumably also used
applications with more problematic UIs. Again qualitatively these tend to be
specialized applications with small user bases developed by teams with fewer
engineering resources.  However, these are often the applications we use most.
To improve the state of these UIs we need to reduce the cost (preferrably to
zero) of developing high-quality UIs.

Of particular interest to the authors are scientific workflow systems that
attempt to intergrate multiple discrete tools into cohesive data analysis
pipelines. Such systems might included tens to hundreds of component tools,
each with their own interface. 
 



https://bitbucket.org/galaxy/galaxy-central/wiki/ToolConfigSyntax

We can model the UI with a directed graph that captures the dataflow and
dependency relationships between UI attributes. Nodes can either be:

- Independent: Nodes whose values can be assigned
- Dependent: Nodes whose values are computed from its dependencies 



Dynamic Dependency Graphs

In the presence of arbitrary code it can be difficult to statically determine
the depenency relationships between nodes. Instead of trying to solve this hard
program ananalysis problem, many UI frameworks, like knockout.js, (re)record
dependencies dynamically during graph evaluation. Dependencies are tracked
locally within nodes to avoid maintaining a global graph structure with
uniquely named nodes. The are several tradeoffs, however, for these
simplifications: 
1. Dependent nodes can be evaluated multiple times
1. Independent nodes can be assigned "intermediate" values that result from
incomplete evaluation of the tree
1. The complete graph structure is not available for deriving enablement and other useful properties of the model 


The first two trade-offs can create performance and correctness problems. Even
if the model converges to valid attributes, nodes might see inconsistent
	values.  If node evaluation has side effects, e.g., interacting with an
	external web service, these inconsistent values might "leak" outside the
	model. 

https://github.com/beickhoff/beickhoff.github.com/blob/master/knockoutjs/atomic-updates.md

[jarvi2008]: http://parasol.tamu.edu/~jarvi/papers/gpce08.pdf
