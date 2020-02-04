thingymodule = {name: "thingymodule"}

#region modulesFromEnvironment
#region node_modules
CLI = require 'clui'
Spinner = CLI.Spinner
c = require "chalk"
fs = require "fs-extra"
#endregion

#region localModules
git = null
user = null
cloud = null
recipe = null
globalScope = null
pathHandler = null
constructor = null
remoteHandler = null
#endregion
#endregion

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["thingymodule"]?  then console.log "[thingymodule]: " + arg
    return
print = (arg) -> console.log(arg)
printSuccess = (arg) -> print c.green(arg)
printError = (arg) -> pring c.red(arg)
olog = (o) -> log "\n" + ostr(o)
ostr = (o) -> JSON.stringify(o, null, 4)
#endregion
##############################################################################
thingymodule.initialize = () ->
    log "thingymodule.initialize"
    git = allModules.gitmodule
    pathHandler = allModules.pathhandlermodule
    cloud = allModules.cloudservicemodule
    user = allModules.userinquirermodule
    recipe = allModules.recipemodule
    globalScope = allModules.globalscopemodule
    constructor = allModules.constructionmodule
    remoteHandler = allModules.remotehandlermodule
    return

#region internalFunctions
addPushThingy  = (path, remote) ->
    statusMessage = "initialize and push " + remote.getRepo() + "..."
    status = new Spinner(statusMessage)
    status.start()
    try await git.addPush(path, remote)
    catch err then log err
    finally status.stop()
    return

saveThingyStateToThingy = (thingyPath, thingy) ->
    log "saveThingyStateToThingy"
    await addStaticProperties(thingy, thingyPath)
    await saveThingyFile(thingy, thingyPath)
    return

saveThingyFile = (thingy, thingyPath) ->
    log "saveThingyFile"
    ## TODO maybe create and use this file later
    # fileString = ostr(thingy)
    # filePath = pathHandler.resolve(thingyPath, ".thingy")
    # await fs.writeFile(filePath, fileString)
    return

createRepositoryForThingy = (thingy) ->
    log "createRepositoryForThingy"
    message = "Make thingy " + thingy.name + " public?"
    visible = await user.inquireYesNoDecision(message, true)
    await cloud.createRepository(thingy.name, visible)
    thingyPath = pathHandler.resolve(thingy.basePath, thingy.name)
    await fs.mkdir(thingyPath)

    return

#region manageThingyProperties
addStaticProperties = (thingy, basePath) ->
    log "addStaticProperties"
    map = {}
    list = []

    ## TODO add all the properties

    thingy.staticMap = map
    thingy.staticProperties = list

addVirtualProperties = (thingy) ->
    log "addVirtualProperties"
    map = {}
    list = []

    await addThingyTypeProperty(thingy.type, list, map)
    await addThingyNameProperty(thingy.name, list, map)
    await addDeveloperProperty(list, map)
    await addOwnRemoteURLProperty(list, map)
    await addRelatedRemotesProperty(list, map)

    thingy.virtualMap = map
    thingy.virtualProperties = list

#region virtualProperties
addThingyTypeProperty = (type, list, map) ->
    property = {thingyType:type}
    addProperty(property, list, map)

addThingyNameProperty = (name, list, map) ->
    property = {thingyName:name}
    addProperty(property, list, map)

addDeveloperProperty = (list, map) ->
    developer = await retrieveDeveloperProperty()
    property = {developer}
    addProperty(property, list, map)

addOwnRemoteURLProperty = (list, map) ->
    url = await retrieveOwnRemoteURLProperty()
    property = {ownRemoteURL:url}
    addProperty(property, list, map)

addRelatedRemotesProperty = (list, map) ->
    remotes = await retrieveRelatedRemotesProperty()
    property = {relatedRemotes:remotes}
    addProperty(property, list, map)
#endregion

addProperty = (property, list, map) ->
    Object.assign(map, property)
    list.push property

#region retrievalFunctions
retrieveRemote = (options) ->
    if wildcardIsOnlyOption(options)
        return "" # await user.retrieveRemote("", message)
    return "" # await user.retrieveRemote(options[0], message)

retrieveDeveloperProperty = ->
    return "Deplemento" ##TODO implement

retrieveOwnRemoteURLProperty = ->
    return "" ##TODO implement

retrieveRelatedRemotesProperty = ->
    relatedRemote =
        relation: "origin"
        remoteURL: await retrieveOwnRemoteURLProperty()
    return [relatedRemote]
#endregion
#endregion
#endregion

#region exposedFunctions
thingymodule.checkThingyName = (name) ->
    log "thingymodule.checkThingyName"
    if !name then name = await user.inquireString("thingyName: ", "")
    exists = await pathHandler.somethingExistsAtBase(name)
    isInScope = globalScope.repoIsInScope(name) 
    ## does exist ->
    ##   # and has no content -> remove dir -> does not exist
    if exists
        ## TODO implement desired behaviour
        message = "That thingy(" + name + ") already exists in your localScope!"
        message += "\nYou might just want to use that :-)"
        message += "\nOr consider a new name."
        throw message
    ## does not exist -> 
    ##   # and no repo "name" is in scope -> name ok, continue regularily
    if !exists and !isInScope then return name
    ## does not exist -> 
    ##   # and repo "name" exists in scope -> clone that repo -> done!
    if !exists and isInScope
        ## TODO implement desired behaviour
        message = "That thingy(" + name + ") already exists in your globalScope!"
        message += "\nYou might just want to just clone that :-)"
        message += "\nOr consider a new name."
        throw message
    
    ## does exist ->        
    ##   # and has .thingy.json -> done!
    ## does exist ->
    ##   # and is git repo -> generate .thingy.json -> done!
    ## does exist ->
    ##   # and has other content -> create typeless thingy and merge: ["./"]
    throw new Error("Unhandled case in thingymodule.checkThingyName!")

thingymodule.createVersionless = (name, type, constructionPlan, basePath) ->
    log "thingymodule.createVersionless"
    thingy = {name, type, constructionPlan, basePath}
    await addVirtualProperties(thingy)
    await constructor.constructVersionless(thingy)
    await recipe.executeIndividualize(type, basePath)
    return

thingymodule.create = (name, type, constructionPlan, basePath) ->
    log "thingymodule.create"
    thingy = {name, type, constructionPlan, basePath}
    await addVirtualProperties(thingy)
    await createRepositoryForThingy(thingy)
    thingyPath = pathHandler.resolve(thingy.basePath, thingy.name)
    remote = remoteHandler.getRemoteObject(thingy.name)
    await git.init(thingyPath, remote)
    await constructor.construct(thingy)
    await recipe.executeIndividualize(type, thingyPath)
    await saveThingyStateToThingy(thingyPath, thingy)    
    await addPushThingy(thingyPath, remote)
    return
#endregion

module.exports = thingymodule