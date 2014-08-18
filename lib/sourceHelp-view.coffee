{View} = require 'atom'

module.exports =
class sourceHelpView extends View
  @content: ->
    @div class: 'sourceHelpView overlay from-bottom', =>
      @div class: "inset-panel", =>
        @div class: "panel-heading", =>
          @input class: "pull-right btn btn-default", value: "close", type: "button", outlet: "close"
          @h1 "Help for sources"
      @p "A snippet can have multiple sources. These have to be separated by commas,
      just like with css selectors since technically, they are css selectors."
      @pre ".source.c, .source.objc\n.source.js, .source.coffee"
      @p "Some sources have to be escaped, such as the c++ one"
      @pre ".source.c\\+\\+"
      @p "Click the button below to get the source for the file you're currently in.
      Note that it won't escape sources"
      @div class: "block", =>
        @button "Inspector file-source", class: "btn btn-success", outlet: "inspector"
        @div =>
          @pre "", outlet: "inspectorOutput"

  initialize: (serializeState) ->
    @handleEvents()
    @focus()

  handleEvents: ->
    @inspector.click =>
      scopes = atom.workspace.getActiveEditor().getCursorScopes()
      console.log scopes
      @inspectorOutput.text('')
      text = ''
      for scope in scopes
        text += scope + "\n"
      @inspectorOutput.text(text)
    @close.click =>
      @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      @showPane()

  showPane: ->
    atom.workspaceView.append(this)
