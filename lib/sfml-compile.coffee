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
    createLog:
      title: 'Create compiling_error.txt after unsuccesful compilation'
      type: 'boolean'
      default: true
    hideTerminal:
      title: 'Get rid of console'
      description: 'You can see changes if you launch your app manually'
      type: 'boolean'
      default: true
    sfmlLocation:
      title: 'Location of SFML\\include'
      type: 'string'
      default: 'C:\\SFML\\include'
    compilerOptions:
      title: 'Compiler options'
      type: 'string'
      default: ''

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

    command = "compile.bat"
    justDie = atom.project.getPaths()[0]
    args = [justDie]
    doLog = " 2> compiling_error.txt"
    resourceFiles = atom.config.get("sfml-compile.regularFiles.resourcesDir")
    if atom.config.get("sfml-compile.regularFiles.sameAsMain") == true
      resourceFiles = justDie
    dllFiles = atom.config.get("sfml-compile.regularFiles.dllsDir")
    deleteDatBatM8 = "\nREM DO IT! COME ON! KILL ME NOW! I'M HERE!\ndel "+justDie+"\\compile.bat"
    if atom.config.get("sfml-compile.deleteBat") == false
      deleteDatBatM8 = ""
    if atom.config.get("sfml-compile.createLog") == false
      doLog = ""
    hideCMD = ""
    if atom.config.get("sfml-compile.hideTerminal") == true
      hideCMD = " -mwindows"

    # Kill me, please
    someStuff = "@RD /S /Q \""+justDie+"\\build"+"\"\n"+"mkdir "+justDie+"\\build\n"+"cd "+justDie+"\n"+"g++ -Wall -g "+atom.config.get("sfml-compile.compilerOptions")+" -I"+atom.config.get("sfml-compile.sfmlLocation")+" -c \""+justDie+"\\main.cpp\""+" -o build\\main.o"+doLog+"\n"+"findstr \"^\" \"compiling_error.txt\" || del \"compiling_error.txt\"\n"+"g++ -LC:\\SFML\\lib -o \"build\\main.exe\" build\\main.o   -lsfml-graphics -lsfml-window -lsfml-system -lsfml-audio -lsfml-network"+hideCMD+"\n"+"xcopy /s "+dllFiles+"*.dll "+justDie+"\\build\n"+"copy "+resourceFiles+"\\*.png "+justDie+"\\build"+"\ncopy "+resourceFiles+"\\*.ttf "+justDie+"\\build"+"\ncopy "+resourceFiles+"\\*.mp3 "+justDie+"\\build\n"+"cd "+justDie+"\\build\n"+"main.exe"+deleteDatBatM8

    fs.writeFile atom.project.getPaths()[0]+"\\compile.bat", someStuff

    # Default to where the user opened atom
    options =
      cwd: atom.project.getPaths()[0]+"\\"
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

    setTimeout ->
      fs.exists justDie+"\\compiling_error.txt", (exists) ->
        log = fs.readFileSync justDie+'\\compiling_error.txt', 'utf8'
        atom.notifications.addError(log)
    , 1000
