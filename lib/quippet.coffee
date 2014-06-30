QuippetView = require './quippet-view'

module.exports =
  quippetView: null

  activate: (state) ->
    @quippetView = new QuippetView(state.quippetViewState)

  deactivate: ->
    @quippetView.destroy()

  serialize: ->
    quippetViewState: @quippetView.serialize()
