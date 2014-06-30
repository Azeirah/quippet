{EditorView, Editor, View} = require 'atom'
fs = require 'fs'
snippets = require atom.packages.resolvePackagePath('snippets')

module.exports =
class QuippetView extends View
  @content: ->
    @div class: 'quippet overlay from-top', =>
      @h1 "Create a quick snippet here!", class: "message"
      @textarea "snippetField", class: "snippet native-key-bindings editor-colors", rows: 8, outlet: "snippet"
      @subview "tabName", new EditorView(mini:true, placeholderText: 'Snippet tab activation')
      @subview "snippetName", new EditorView(mini:true, placeholderText: 'Snippet name')
      @subview "activationSource", new EditorView(mini:true, placeholderText: 'Snippet selector (ex: `.source.js`)')
      @button "Done", class: "createSnippetButton"

  initialize: (serializeState) ->
    @handleEvents()
    atom.workspaceView.command "quippet:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  handleEvents: ->
    @find('.createSnippetButton').on 'click', => @createSnippet()

  # Tear down any state and detach
  destroy: ->
    @detach()

  populateSnippetField: (text) ->
    @snippet.text text

  createSnippet: ->
    tabname = @tabName.getText()
    snippetName = @snippetName.getText()
    source = @activationSource.getText()
    snippet = @snippet.val()
    if @validateSnippet()
      console.log "snippet is valid"
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
    @tabName.setText('')
    @snippetName.setText('')
    @activationSource.setText('')
    @snippet.val('')
    @detach()

  validateSnippet: ->
    tabname = @tabName.getText().length
    snippetName = @snippetName.getText().length
    source = @activationSource.getText().length
    snippet = @snippet.val().length
    if tabname is 0
      @tabName.css border: "1px solid red"
    else
      @tabName.css border: "inherit"
    if snippetName is 0
      @snippetName.css border: "1px solid red"
    else
      @snippetName.css border: "inherit"
    if snippet is 0
      @snippet.css border: "1px solid red"
    else
      @snippet.css border: "inherit"
    if source is 0
      @activationSource.css border: "1px solid red"
    else
      @activationSource.css border: "inherit"
    return tabname > 0 and snippetName > 0 and snippet > 0 and source > 0

  toggle: ->
    editor = atom.workspace.activePaneItem
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
      selection = editor.getSelection().getText()
      console.log(selection)
      if selection.length > 0
        @populateSnippetField(selection)
        @snippet.focus()
