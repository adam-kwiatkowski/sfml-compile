{CompositeDisposable} = require 'atom'
{BufferedProcess} = require 'atom'
SfmlCompileView = require './sfml-compile-view'
{CompositeDisposable} = require 'atom'

module.exports = SfmlCompile =
  sfmlCompileView: null
  modalPanel: null
  subscriptions: null
  config:
    regularFiles:
      title: 'Files settings'
      type: 'object'
      properties:
        sameAsMain:
          title: 'Include resources from same directory as main.cpp'
          type: 'boolean'
          default: true
        resourcesDir:
          title: 'Resources directory'
          type: 'string'
          default: "Leave blank if resources have same directory as main.cpp"
        dllsDir:
          title: 'Directory of dlls that should be included'
          type: 'string'
          default: "c:\\dlls\\"
    deleteBat:
      title: 'Delete compile.bat after compilation'
      type: 'boolean'
      default: true

  activate: (state) ->
    @sfmlCompileView = new SfmlCompileView(state.sfmlCompileViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @sfmlCompileView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'sfml-compile:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @sfmlCompileView.destroy()

  serialize: ->
    sfmlCompileViewState: @sfmlCompileView.serialize()

  toggle: ->
    console.log 'Compiling SFML'

    atom.workspace.observeTextEditors (editor) ->
      editor.save();

    fs = require "fs"

    command = "compile_sfml.exe"
    justDie = atom.project.getPaths()[0]
    args = [justDie]
    resourceFiles = atom.config.get("sfml-compile.regularFiles.resourcesDir")
    if atom.config.get("sfml-compile.regularFiles.sameAsMain") == true
      resourceFiles = justDie
    dllFiles = atom.config.get("sfml-compile.regularFiles.dllsDir")
    deleteDatBatM8 = "\ndel "+justDie+"\\compile.bat"
    if atom.config.get("sfml-compile.deleteBat") == false
      deleteDatBatM8 = "\nREM DO IT! COME ON! KILL ME NOW! I'M HERE!"

    someStuff = "@RD /S /Q \""+justDie+"\\build"+"\"\n"+"mkdir "+justDie+"\\build\n"+"cd "+justDie+"\n"+"g++ -Wall -g -IC:\\SFML\\include -c \""+justDie+"\\main.cpp\""+" -o build\\main.o\n"+"g++ -LC:\\SFML\\lib -o \"build\\main.exe\" build\\main.o   -lsfml-graphics -lsfml-window -lsfml-system -lsfml-audio -lsfml-network\n"+"xcopy /s "+dllFiles+"*.dll "+justDie+"\\build\n"+"copy "+resourceFiles+"\\*.png "+justDie+"\\build"+"\ncopy "+resourceFiles+"\\*.ttf "+justDie+"\\build"+"\ncopy "+resourceFiles+"\\*.mp3 "+justDie+"\\build\n"+"cd "+justDie+"\\build\n"+"main.exe"+deleteDatBatM8

    fs.writeFile atom.project.getPaths()[0]+"\\compile.bat", someStuff

    # Default to where the user opened atom
    options =
      cwd: atom.project.getPaths()[0]
      env: process.env

    stdout = (output) -> console.log(output)
    stderr = (output) -> console.error(output)

    exit = (return_code) ->
      if return_code is 0
        console.log("Exited with 0")
      else
        console.log("Exited with " + return_code)

    # Run process
    new BufferedProcess({command, args, options, stdout, stderr, exit})
