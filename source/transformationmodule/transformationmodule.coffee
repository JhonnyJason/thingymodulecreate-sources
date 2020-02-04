transformationmodule = {name: "transformationmodule"}

#region modulesFromEnvironment
#region node_modules
CLI = require 'clui'
Spinner = CLI.Spinner
fs = require "fs-extra"
gitmodulesHandler = require "gitmodules-file-handler"
#endregion

#retion localModules
git = null
user = null
cloud = null
pathHandler = null
remoteHandler = null
#endregion
#endregion

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["transformationmodule"]?  then console.log "[transformationmodule]: " + arg
    return
print = (arg) -> console.log(arg)
#endregion
##############################################################################
transformationmodule.initialize = () ->
    log "transformationmodule.initialize"
    git = allModules.gitmodule
    user = allModules.userinquirermodule
    cloud = allModules.cloudservicemodule
    pathHandler = allModules.pathhandlermodule
    remoteHandler = allModules.remotehandlermodule
    return
    
#region internalFunctions
#region helperFunctions
moduleToTempDir = (tmp, module) ->
    log "moduleToTempDir"
    await fs.move(module, tmp)
    gitDir = pathHandler.resolve(tmp, ".git")
    await fs.remove(gitDir)
    return

reintroduceDirectory = (tmp, module) ->
    log "reintroduceAsDirectory"
    await fs.remove(module)
    await fs.move(tmp, module)
    return

removeFromGit = (modulePath) ->
    log "removeFromGit"
    base = pathHandler.thingyModuleBase
    try await git.rmCached(base, modulePath)
    catch err 
        log err
        log await git.stash(base)
        try log await git.rmCached(base, modulePath)
        catch err
            log "Error after stashing wtf has happened!?!?"
            log err
        log await git.stashPop(base)
    return

removeFromStaged = (modulePath) ->
    log "removeFromStaged"
    base = pathHandler.thingyModuleBase
    gitmodulesPath = pathHandler.resolve(pathHandler.parentPath, ".gitmodules")
    try await git.restoreStaged(base, gitmodulesPath)
    catch err then log err
    try await git.restoreStaged(base, modulePath)
    catch err then log err
    return

deinitSubmodule = (base, module) ->
    log "deinitSubmodule"
    try await git.deinitSubmodule(base, module)
    catch err then log err
    return

removeLinesFromGitmodules = (modulePath) ->
    log "removeLinesFromGitmodules"
    gitmodulesFile = pathHandler.resolve(pathHandler.parentPath, ".gitmodules")
    gitmodulesObject = await gitmodulesHandler.readNewGitmodulesFile(gitmodulesFile)
    relativeDir = pathHandler.relative(pathHandler.parentPath, modulePath)
    submodule = gitmodulesObject.getModule(relativeDir)
    if submodule then submodule.remove()
    await gitmodulesObject.writeToFile()
    return

deleteModulesReferences = (modulePath) ->
    log "deleteModulesReferences"
    gitDir = pathHandler.resolve(pathHandler.parentPath, ".git")
    relativeDir = pathHandler.relative(pathHandler.parentPath, modulePath)
    refDir = pathHandler.resolve(gitDir, "modules", relativeDir)
    await fs.remove(refDir)

initPush = (path, remote) ->
    statusMessage = "initialize and push " + remote.getRepo() + "..."
    status = new Spinner(statusMessage)
    status.start()
    try await git.initPush(path, remote)
    catch err then log err
    finally status.stop()
    return

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

commitChanges = (base, module) ->
    log "commitChanges"
    statusMessage = "commit changes of " + module + "..."
    status = new Spinner(statusMessage)
    status.start()
    try 
        await git.add(base, module)
        await git.commit(base, statusMessage)
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
#endregion

transformToDirectory = (name, thingy) ->
    log "transformToDirectory"
    base = pathHandler.thingyModuleBase
    modulePath = pathHandler.resolve(pathHandler.thingyModuleBase, name)
    tmpPath = pathHandler.resolve(pathHandler.temporaryFilesPath, name)
    await moduleToTempDir(tmpPath, modulePath)
    await deinitSubmodule(base, modulePath)
    await deleteModulesReferences(modulePath)
    await removeLinesFromGitmodules(modulePath)
    await removeFromStaged(modulePath)
    await removeFromGit(modulePath)
    await reintroduceDirectory(tmpPath, modulePath)
    return

transformToSubmodule = (name, thingy) ->
    log "transformToSubmodule"
    repoName = thingy.name + "-" + name
    remote = await createNewRemote(repoName)
    modulePath = pathHandler.resolve(pathHandler.thingyModuleBase, name)
    exists = await pathHandler.directoryExists(modulePath)
    if !exists then throw "Module to transform does not exist!"
    tmpPath = pathHandler.temporaryFilesPath
    destinationPath = pathHandler.resolve(tmpPath, name)
    await fs.move(modulePath, destinationPath)
    await commitChanges(pathHandler.thingyModuleBase, modulePath)
    await initPush(destinationPath, remote)
    await fs.remove(destinationPath)
    await addSubmodule(pathHandler.thingyModuleBase, remote, name)
    return
#endregion

#region exposedFunctions
transformationmodule.step = (step, thingy) ->
    log "transformationsmodule.step"
    log step

    if step[0] == "directory"
        await transformToDirectory(step[1], thingy)
    if step[0] == "submodule"
        await transformToSubmodule(step[1], thingy)
    
    return

#endregion

module.exports = transformationmodule