constructionmodule = {name: "constructionmodule"}

#region modulesFromEnvironment
#region node_modules
CLI = require 'clui'
Spinner = CLI.Spinner
fs = require "fs-extra"
#endregion

#region localModules
git = null
user = null
cloud = null
recipe = null
pathHandler = null
thingyModule = null
remoteHandler = null
#endregion
#endregion

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["constructionmodule"]?  then console.log "[constructionmodule]: " + arg
    return
olog = (o) -> log "\n" + ostr(o)
ostr = (o) -> JSON.stringify(o, null, 4)
print = (arg) -> console.log(arg)
#endregion
##############################################################################
constructionmodule.initialize = () ->
    log "constructionmodule.initialize"
    git = allModules.gitmodule
    user = allModules.userinquirermodule
    cloud = allModules.cloudservicemodule
    recipe = allModules.recipemodule
    thingyModule = allModules.thingymodule
    pathHandler = allModules.pathhandlermodule
    remoteHandler = allModules.remotehandlermodule
    return
    
#region internalProperties
stepProxy = {}
stepProxy.merge = (step, thingy, d) -> mergeStep(step, thingy, d)
stepProxy.directory = (step, thingy, d) -> directoryStep(step, thingy, d)
stepProxy.submodule = (step, thingy, d) -> submoduleStep(step, thingy, d)

moduleStepProxy = {}
moduleStepProxy.merge = (step, thingy, d) -> moduleMergeStep(step, thingy, d)
moduleStepProxy.create = (step, thingy, d) -> moduleCreateStep(step, thingy, d)
moduleStepProxy.use = (step, thingy, d) -> moduleUseStep(step, thingy, d)
#endregion

#region internalFunctions
#region proxyStepFunctions
submoduleStep = (step, thingy, d) ->
    log "submoduleStep"
    await moduleStepProxy[step[2]](step, thingy, d)
    return

directoryStep = (step, thingy, d) ->
    log "mergeStep"
    await moduleStepProxy[step[2]](step, thingy, d)
    return
#endregion

#region helperFunctions
move = (src, dest, file) ->
    sourcePath = pathHandler.resolve(src, file)
    destinationPath = pathHandler.resolve(dest, file)
    await fs.move(sourcePath, destinationPath, {overwrite: true})

merge = (repo, dest) ->
    remote = remoteHandler.createRemoteFromUserInput(repo)
    repoName = remote.getRepo()
    base = pathHandler.temporaryFilesPath
    statusMessage = "Merging " + remote.getRepo() + "..."
    status = new Spinner(statusMessage);
    status.start()
    try
        await git.clone(remote, base)
        repoPath = pathHandler.resolve(base, repoName)
        gitDir = pathHandler.resolve(repoPath, ".git")
        await fs.remove(gitDir)
        files = await fs.readdir(repoPath)
        promises = files.map((el) -> move(repoPath, dest, el))
        await Promise.all(promises)
        await fs.remove(repoPath)
    catch err then log err
    finally status.stop()
    return

createTemporaryModulePath = (moduleName) ->
    tmp = pathHandler.temporaryFilesPath
    modulePath = pathHandler.resolve(tmp, moduleName)
    await fs.mkdirp(modulePath)
    return modulePath

createNewRemote = (repoName) ->
    message = "Make module " + repoName + " public?"
    visible = await user.inquireYesNoDecision(message, true)
    statusMessage = "Creating remote " + repoName + "..."
    status = new Spinner(statusMessage);
    status.start()
    try await cloud.createRepository(repoName, visible)
    catch err then log err
    finally status.stop()
    return remoteHandler.getRemoteObject(repoName)

initPush = (path, remote) ->
    statusMessage = "initialize and push " + remote.getRepo() + "..."
    status = new Spinner(statusMessage)
    status.start()
    try await git.initPush(path, remote)
    catch err then log err
    finally status.stop()
    return
        
addSubmodule = (path, remote, label) ->
    statusMessage = "add submodule to " + label + "..."
    status = new Spinner(statusMessage)
    status.start()
    try await git.addSubmodule(path, remote, label)
    catch err then log err
    finally status.stop()
    return

clone = (remote, base) ->
    statusMessage = "cloning " + remote.getRepo() + "..."
    status = new Spinner(statusMessage)
    status.start()
    try await git.clone(remote, base)
    catch err then log err
    finally status.stop()
    return
#endregion

mergeStep = (step, thingy, direct) ->
    log "mergeStep"
    ## step[0] is "merge"
    ## step[1] is something identifying the repository
    if direct then thingyPath = thingy.basePath
    else thingyPath = pathHandler.resolve(thingy.basePath, thingy.name)
    await merge(step[1], thingyPath)
    return

moduleMergeStep = (step, thingy, direct) ->
    log "moduleMergeStep"
    # step[0] is "directory" or "submodule" 
    # step[1] is label of directory
    # step[2] is "merge"
    # step[3] something identifying the repository
    if direct then thingyPath = thingy.basePath
    else thingyPath = pathHandler.resolve(thingy.basePath, thingy.name)
    if step[0] ==  "directory"
        destPath = pathHandler.resolve(thingyPath, step[1])
        await fs.mkdir(destPath)
        await merge(step[3], destPath)
        return
    else
        repoName = thingy.name + "-" + step[1]
        modulePath = await createTemporaryModulePath(repoName)
        await merge(step[3], modulePath)
        remote = await createNewRemote(repoName)
        await initPush(modulePath, remote)
        await fs.remove(modulePath)

        await addSubmodule(thingyPath, remote, step[1])
        return

moduleCreateStep = (step, thingy, direct) ->
    log "moduleCreateStep"
    # step[0] is "directory" or "submodule" 
    # step[1] is label of directory
    # step[2] is "create"
    # step[3] is thingyModuleType
    if direct then thingyPath = thingy.basePath
    else thingyPath = pathHandler.resolve(thingy.basePath, thingy.name)
    
    if step[0] ==  "directory"
        destPath = pathHandler.resolve(thingyPath, step[1])
        await fs.mkdir(destPath)
        repoName = thingy.name + "-" + step[1]
        rcp = await recipe.getModuleRecipe(step[3])
        print(">> Constructing thingy(versionless) " + repoName + ":")
        constructionPlan = await recipe.toConstructionPlan(rcp)
        await thingyModule.createVersionless(repoName, step[3], constructionPlan, destPath)
        return
    else
        repoName = thingy.name + "-" + step[1]
        rcp = await recipe.getModuleRecipe(step[3])
        print(">> Constructing thingy " + repoName + ":")
        constructionPlan = await recipe.toConstructionPlan(rcp)
        tmp = pathHandler.temporaryFilesPath
        tmpThingyModulePath = pathHandler.resolve(tmp, repoName)        
        await thingyModule.create(repoName, step[3], constructionPlan, tmp, rcp.individualize)
        await fs.remove(tmpThingyModulePath)
        remote = remoteHandler.getRemoteObject(repoName)
        await addSubmodule(thingyPath, remote, step[1])
        return

moduleUseStep = (step, thingy, direct) ->
    log "moduleUseStep"
    # step[0] is "directory" or "submodule" 
    # step[1] is label of directory
    # step[2] is "use"
    # step[3] something identifying the repository
    if direct then thingyPath = thingy.basePath
    else thingyPath = pathHandler.resolve(thingy.basePath, thingy.name)
    remote = remoteHandler.createRemoteFromUserInput(step[3])
    if step[0] ==  "directory"
        linkPath = pathHandler.resolve(thingyPath, step[1])
        base = pathHandler.basePath
        await clone(remote, base)
        realPath = pathHandler.resolve(base, remote.getRepo())
        await fs.ensureSymlink(realPath, linkPath)
        return
    else
        await addSubmodule(thingyPath, remote, step[1])
        return
#endregion

#region exposedFunctions
constructionmodule.instructionLineToConstructionStep = (instructionLine) ->
    log "constructionmodule.instructionLineToConstructionStep"
    instructions = instructionLine.split(",")

    for token in instructions 
        if typeof token != "string"  
            throw "corrupted instructionLine: " + instructionLine
    return instructions

constructionmodule.constructStep = (step, thingy) ->
    log "constructionmodule.constructStep"
    olog thingy
    olog step
    log pathHandler.basePath
    await stepProxy[step[0]](step, thingy, true) if step[0]
    return

constructionmodule.constructVersionless = (thingy) ->
    log "constructionmodule.constructVersionless"
    plan = thingy.constructionPlan
    await stepProxy[step[0]](step, thingy, true) for step in plan when step[0]
    return

constructionmodule.construct = (thingy) ->
    log "constructionmodule.construct"
    plan = thingy.constructionPlan
    await stepProxy[step[0]](step, thingy) for step in plan when step[0]
    return
#endregion

module.exports = constructionmodule