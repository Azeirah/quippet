{EditorView, Editor, View} = require 'atom'
fs = require 'fs'
snippets = require atom.packages.resolvePackagePath('snippets')
SourceHelpView = require './sourceHelp-view'

module.exports =
class QuippetView extends View
  @sourceHelpView = null

  @content: ->
    @div class: 'quippet overlay from-top', =>
      @div class: "panel", =>
        @h1 "Create a quick snippet here!", class: "panel-heading"
      @textarea "", class: "snippet native-key-bindings editor-colors", rows: 8, outlet: "snippet", placeholder: "Snippet body goes here"
      @subview "tabName", new EditorView(mini:true, placeholderText: 'Snippet tab activation')
      @subview "snippetName", new EditorView(mini:true, placeholderText: 'Snippet name')
      @div "", class: "input-group snippetScopeGroup", =>
        @subview "activationSource", new EditorView(mini:true, placeholderText: 'Snippet scope selector (ex: `.source.js`)')
        @span "", class: "input-group-btn", =>
          @button "?", class:"btn", outlet:"sourceHelp"
      @button "Done", class: "createSnippetButton btn btn-primary"

  initialize: (serializeState) ->
    @handleEvents()
    atom.workspaceView.command "quippet:toggle", => @toggle()
    # Sets the maximum height of the snippet input field to prevent users from pulling it down too far, which would hide the other input fields
    # and the done button
    @maxSnippetHeight()
    @sourceHelpView = new SourceHelpView()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  handleEvents: ->
    # Makes sure that the snippet field can't be resized too large, so that it won't push the lower inputs and done button offscreen
    window.addEventListener 'resize', =>
      @maxSnippetHeight()
    # Close on escape
    enterKeyCode = 13
    escapeKeyCode = 27
    @on 'keydown', (event) =>
      if event.which == escapeKeyCode
        @detach()
    @find('.createSnippetButton').on 'click', => @createSnippet()
    # Add the input validation and confirm event to all fields.
    fields = [@tabName, @snippetName, @activationSource, @snippet]
    for field in fields
      field.on 'core:confirm', (event) =>
        @createSnippet()
      field.on 'keyup', =>
        @validateFields()
    @sourceHelp.click =>
      @sourceHelpView.toggle()

  # Tear down any state and detach
  destroy: ->
    @detach()

  populateSnippetField: (text) ->
    @snippet.text text

  populateSourceField: ->
    # If a file is opened, take its extension and populate the source input field with it.
    # Ex: when quippet-view.coffee is opened, and you open quippet, the 'source' input field will contain '.source.coffee'
    editor = atom.workspace.getActiveEditor()
    if editor
      filename = editor.getTitle()
      if filename.contains '.'
        @activationSource.setText '.source.' + filename.split('.').pop()

  createSnippet: ->
    tabname = @tabName.getText()
    snippetName = @snippetName.getText()
    source = @activationSource.getText()
    snippet = @snippet.val()
    if @validateFields()
      console.log "New snippet is valid"
      filepath = __dirname + '/../snippets/' + snippetName + '.json'
      snippetJSON = {}

      # creating a literal is not possible, since
      # source:
      #   snippetName:
      #     'prefix': tabname
      #     'body': snippet
      # would result in a json file with
      # {
      #   "snippetName": blablabla
      # }
      # instead of what we actually want,
      # {
      #   "TheValueOfTheSnippetNameVariable": blablabla
      # }
      snippetJSON[source] = {}
      snippetJSON[source][snippetName] = {
        'prefix': tabname
        'body': snippet
      }
      fs.writeFile(filepath, JSON.stringify(snippetJSON, null, '\t'), (error) ->
        if error
          console.log error
        else
          console.log 'the snippet was succesfully saved to ' + filepath
      )
      # Normally, you'd have to reload atom to load in new snippets, by calling loadAll, reloading snippets goes automatically :)
      snippets.loadAll()
      @cleanup()
    else
      console.log 'snippet is invalid'

  cleanup: ->
    # After a snippet has been saved, empty the input fields
    @tabName.setText('')
    @snippetName.setText('')
    @activationSource.setText('')
    @snippet.val('')
    @detach()

  validateFields: ->
    tabname = @tabName.getText().length
    snippetName = @snippetName.getText().length
    source = @activationSource.getText().length
    snippet = @snippet.val().length
    validate = (input, el) ->
      if input is 0
        el.addClass "invalid"
        el.removeClass "valid"
      else
        el.removeClass "invalid"
        el.addClass "valid"
    validate snippet, @snippet
    validate snippetName, @snippetName
    validate source, @activationSource
    validate tabname, @tabName
    return tabname > 0 and snippetName > 0 and snippet > 0 and source > 0

  showPane: ->
    atom.workspaceView.append(this)
    editor = atom.workspace.getActiveEditor()
    if editor
      selection = editor.getSelection().getText()
      @populateSourceField()
      if selection.length > 0
        @populateSnippetField(selection)
    @snippet.focus()

  maxSnippetHeight: ->
    @snippet.css "max-height", (window.innerHeight * 0.8) + "px"

  toggle: ->
    if @hasParent()
      @detach()
    else
      @showPane()
