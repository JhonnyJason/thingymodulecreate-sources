createprocessmodule = {name: "createprocessmodule"}

#region modulesFromEnvironment
pathHandler = null
construction = null
transformation = null
cfg = null
#endregion

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["createprocessmodule"]?  then console.log "[createprocessmodule]: " + arg
    return
olog = (o) -> log "\n" + ostr(o)
ostr = (o) -> JSON.stringify(o, null, 4)
print = (arg) -> console.log(arg)
#endregion
##############################################################################
createprocessmodule.initialize = () ->
    log "createprocessmodule.initialize"
    pathHandler = allModules.pathhandlermodule
    construction = allModules.constructionmodule
    transformation = allModules.transformationmodule
    cfg = allModules.configmodule
    return 

#region internalFunctions
#endregion

#region exposedFunctions
createprocessmodule.execute = (e) ->
    log "createprocessmodule.execute"
    await cfg.checkUserConfig(e.configure)
    await pathHandler.prepare()

    name = await pathHandler.getParentThingyName()
    basePath = pathHandler.thingyModuleBase
    thingy = {name, basePath}

    step = construction.instructionLineToConstructionStep(e.instructionLine)

    if !step then return

    if step.length == 2 then await transformation.step(step, thingy)
    if step.length == 4 then await construction.constructStep(step, thingy)
    
    return
#endregion

module.exports = createprocessmodule
