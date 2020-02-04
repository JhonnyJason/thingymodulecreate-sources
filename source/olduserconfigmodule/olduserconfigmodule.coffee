userconfigmodule = {name: "userconfigmodule"}

#region modulesFromEnvironment
#region node_modules
fs = require "fs-extra"
CLI = require('clui')
Spinner = CLI.Spinner
chalk = require "chalk"
#endregion

#region localModules
cfg = null
user = null
cloud = null
crypt = null
userAction = null
pathHandler = null
#endregion
#endregion

#region logPrintFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["userconfigmodule"]?  then console.log "[userconfigmodule]: " + arg
    return
olog = (o) -> log "\n" + ostr(o)
ostr = (o) -> JSON.stringify(o, null, 4)
printError = (arg) -> console.log(chalk.red(arg))
#endregion
##############################################################################
userconfigmodule.initialize = () ->
    log "userconfigmodule.initialize"
    cfg = allModules.configmodule
    user = allModules.userinquirermodule
    cloud = allModules.cloudservicemodule
    crypt = allModules.encryptionmodule
    userAction = allModules.useractionmodule
    pathHandler = allModules.pathhandlermodule
    return   

#region internalProperties
thingyRecipes = null
allServices = null
userPwd = ""
#endregion

#region internalFunctions
getDefaultUserConfig = ->
    log "getDefaultUserConfig"
    return {
        developerName: ""
        defaultThingyRoot: "~/thingies"
        recipesPath: "~/.config/thingyBubble/recipes"
        temporaryFiles: "~/.config/thingyBubble/temporaryFiles"
        thingyCloudServices: null
        thingyRecipes: {}
    }

ensureConfigPathsExist = ->
    log "ensureConfigPathsExist"
    if !cfg.userConfig.defaultThingyRoot 
        cfg.userConfig.defaultThingyRoot = "~/thingies"
    await pathHandler.ensureDirectoryExists(cfg.userConfig.defaultThingyRoot)
    if !cfg.userConfig.temporaryFiles
        cfg.userConfig.temporaryFiles = "~/.config/thingyBubble/temporaryFiles"
    await pathHandler.ensureDirectoryExists(cfg.userConfig.temporaryFiles)
    if !cfg.userConfig.recipesPath
        cfg.userConfig.recipesPath = "~/.config/thingyBubble/recipes"
    await pathHandler.ensureDirectoryExists(cfg.userConfig.recipesPath)
    return

saveIndexesForServices = ->
    log "saveIndexesForServices"
    ## TODO check if this is really reasonable to save the Indices
    s.index = i for s, i in allServices
    return

#region checkUserConfigSupport
userConfigIsAcceptable = ->
    log "userConfigIsAcceptable"
    masterService = allServices[0]
    if !masterService? then return false
    if !masterService.isAccessible then return false
    if !recipeExists() then return false
    return true

serviceExists = ->
    log "serviceExists"
    return true if allServices[0]?
    return false

recipeExists = ->
    log "recipeExists"
    entriesNr = Object.entries(thingyRecipes).length
    if entriesNr == 0 then return false
    return true
#endregion

fileWrite = ->
    log "fileWrite"
    encryptAllServices()
    cfg.userConfig.thingyRecipes = thingyRecipes    
    await fs.writeFile(pathHandler.userConfigPath, ostr(cfg.userConfig))
    return

#region userInteraction
topLevelDecision = ->
    log "topLevelDecision"
    actionChoices = []

    #region addUserActionChoices §
    if serviceExists()
        userAction.addServiceChoices(actionChoices)
    else
        userAction.addNewServiceChoice(actionChoices)

    actionChoices.push "separator"
    
    if recipeExists()
        userAction.addRecipeChoices(actionChoices)
    else
        userAction.addImportRecipeChoice(actionChoices)
    
    actionChoices.push "separator"
    userAction.addEditDeveloperNameChoice(actionChoices)
    userAction.addPathEditChoices(actionChoices)
    actionChoices.push "separator"

    if userConfigIsAcceptable()
        userAction.addSkipChoice(actionChoices)
    #endregion
    
    return await user.inquireNextAction(actionChoices)

selectServiceDecision = ->
    log "selectServiceDecision"
    selectableOptions = (getHumanReadableIdentifier(service, i) for service,i in allServices)
    return await user.inquireCloudServiceSelect(selectableOptions)

inquireServiceProperties = (service) ->
    log "inquireServiceProperties"
    properties = cloud.getUserAdjustableStringProperties(service)
    for label, content of properties
        service[label] = await user.inquireString(label, content)
#endregion

#region encryption
encryptAllServices = ->
    log "encryptAllServices"
    content = JSON.stringify(allServices)
    password = pathHandler.homedir + userPwd
    gibbrish = crypt.encrypt(content, password)
    cfg.userConfig.thingyCloudServices = gibbrish

decryptAllServices = ->
    log "decryptAllServices"
    if !cfg.userConfig.thingyCloudServices
        userPwd = await user.inquirePassword("Create new password:")
        allServices = []
        encryptAllServices()
        return

    decrypted = false
    gibbrish = cfg.userConfig.thingyCloudServices
    password = pathHandler.homedir
    
    try
        content = crypt.decrypt(gibbrish, password)
        allServices = JSON.parse(content)
        decrypted = true
    catch err

    while !decrypted
        userPwd = await user.inquirePassword("Password:")
        password = pathHandler.homedir + userPwd
        try
            content = crypt.decrypt(gibbrish, password)
            allServices = JSON.parse(content)
            decrypted = true
        catch err then printError("Wrong password!")
#endregion
#endregion

#region exposed
userconfigmodule.checkProcess = (configure) ->
    log "userconfigmodule.checkProcess"
    await decryptAllServices()
    thingyRecipes = cfg.userConfig.thingyRecipes
    await ensureConfigPathsExist()
    pathHandler.prepareTemporaryFilesPath()
    pathHandler.prepareRecipesPath()
    #region checkCloudServices §
    promises = (cloud.check(service) for service in allServices)    
    statusMessage = 'Checking access to cloudServices... '
    status = new Spinner(statusMessage);
    status.start()
    try await Promise.all(promises)
    finally status.stop()
    #endregion

    await fileWrite()
    if userConfigIsAcceptable() and !configure then return
    else await userconfigmodule.userConfigurationProcess()
    return

userconfigmodule.userConfigurationProcess = ->
    log "userconfigmodule.userConfigurationProcess"
    if !cfg.userConfig? 
        cfg.userConfig = getDefaultUserConfig()
        await decryptAllServices()
        thingyRecipes = cfg.userConfig.thingyRecipes
        await fileWrite()

    loop
        action = await topLevelDecision()
        try await userAction.doAction(action)
        catch err 
            return if !err
            log err

#region userConfigManipulations
userconfigmodule.editDeveloperName = ->
    log "userconfigmodule.editDeveloperName"
    current = cfg.userConfig.developerName
    post = await user.inquireString("developerName", current)
    if post == current then return
    cfg.userConfig.developerName = post
    await fileWrite()

#region serviceManipulation
userconfigmodule.addCloudService = (service) ->
    log "userconfigmodule.addCloudService"
    allServices.push service
    saveIndexesForServices()
    await inquireServiceProperties(service)
    await cloud.check(service)
    await fileWrite()

userconfigmodule.selectMasterCloudService = (index) ->
    log "userconfigmodule.selectMasterCloudService"
    service = allServices[index]
    allServices.splice(index, 1)
    allServices.unshift(service)
    saveIndexesForServices()
    await fileWrite()

userconfigmodule.editCloudService = (index) ->
    log "userconfigmodule.editCloudService"
    service = allServices[index]
    await inquireServiceProperties(service)
    await cloud.check(service)
    await fileWrite()

userconfigmodule.removeCloudService = (index) ->
    log "userconfigmodule.removeCloudService"
    allServices.splice(index, 1)
    saveIndexesForServices()
    await fileWrite()
#endregion

#region recipeManipulation
userconfigmodule.addThingyRecipe = (type) ->
    log "userconfigmodule.addThingyRecipe"
    thingyRecipes[type] = true
    await fileWrite()

userconfigmodule.removeThingyRecipe = (type) ->
    log "userconfigmodule.removeThingyRecipe"
    delete thingyRecipes[type]
    await fileWrite()
#endregion

#region pathManipulation
userconfigmodule.editRecipesPath = ->
    log "userconfigmodule.editRecipesPath"
    current = cfg.userConfig.recipesPath
    post = await user.inquireString("recipesPath", current)
    if post == current then return
    cfg.userConfig.recipesPath = post
    await fileWrite()
    await ensureConfigPathsExist()
    return

userconfigmodule.editDefaultThingyRootPath = ->
    log "userconfigmodule.editDefaultThingyRootPath"
    current = cfg.userConfig.defaultThingyRoot
    post = await user.inquireString("defaultThingyRoot", current)
    if post == current then return
    cfg.userConfig.defaultThingyRoot = post
    await fileWrite()
    await ensureConfigPathsExist()
    return

userconfigmodule.editTemporaryFilesPath = ->
    log "userconfigmodule.editTemporaryFilesPath"
    current = cfg.userConfig.temporaryFiles
    post = await user.inquireString("temporaryFiles", current)
    if post == current then return
    cfg.userConfig.temporaryFiles = post
    pathHandler.prepareTemporaryFilesPath()
    await fileWrite()
    await ensureConfigPathsExist()
    return
#endregion
#endregion

#region exposedData
userconfigmodule.getMasterService = -> allServices[0]
userconfigmodule.getAllServices = -> allServices
userconfigmodule.getService = (index) -> allServices[index]
userconfigmodule.getThingyRecipes = -> thingyRecipes
#endregion
#endregion

module.exports = userconfigmodule