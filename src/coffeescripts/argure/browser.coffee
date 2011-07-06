# TODO: Modify to stick additional code into compiled set

# Activate CoffeeScript in the browser by having it compile and evaluate
# all script tags with a content-type of `text/coffeescript`.
# This happens on page load.
runScripts = ->
  scripts = document.getElementsByTagName 'script'
  coffees = (s for s in scripts when s.type is 'text/coffeescript')
  index = 0
  length = coffees.length
  do execute = ->
    script = coffees[index++]
    if script?.type is 'text/coffeescript'
      if script.src
        CoffeeScript.load script.src, execute
      else
        CoffeeScript.run script.innerHTML
        execute()
  null

# Listen for window load, both in browsers and in IE.
if window.addEventListener
  addEventListener 'DOMContentLoaded', runScripts, no
else
  attachEvent 'onload', runScripts

