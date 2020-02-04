cliargumentsmodule = {name: "cliargumentsmodule"}

#region node_modules
meow = require("meow")
#endregion

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["cliargumentsmodule"]?  then console.log "[cliargumentsmodule]: " + arg
    return

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
cliargumentsmodule.initialize = () ->
    log "cliargumentsmodule.initialize"

#region internal functions
getHelpText = ->
    log "getHelpText"
    return """
        Usage
            $ thingymodulegen <arg1>
    
        Options
            required:
                arg1, --instruction <instruction-line>, -i <instruction-line>
                    instructionLine (construction instruction for a thingyModule)
            optiona:
                --configure, -c
                    Flag to indicate to trigger the adjustment interface of the userConfig.json
        TO NOTE:
            The flags will overwrite the flagless argument.

        Examples
            $ thingymodulegen submodule,networkmanagermodule,create,sourcessourcemodule
            ...
    """

getOptions = ->
    log "getOptions"
    return {
        flags:
            instructionLine:
                type: "string"
                alias: "i"
            configure:
                type: "boolean"
                alias: "c"
    }

extractMeowed = (meowed) ->
    log "extractMeowed"
    instructionLine = null
    configure = false

    if meowed.input[0]
        instructionLine = meowed.input[0]

    if meowed.flags.instructionLine
        instructionLine = meowed.flags.instructionLine

    if meowed.flags.configure then configure = true

    return {instructionLine, configure}

#endregion

#region exposed functions
cliargumentsmodule.extractArguments = ->
    log "cliargumentsmodule.extractArguments"
    options = getOptions()
    meowed = meow(getHelpText(), getOptions())
    extract = extractMeowed(meowed)
    return extract

#endregion exposed functions

module.exports = cliargumentsmodule