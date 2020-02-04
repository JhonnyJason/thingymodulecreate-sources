useractionmodule = {name: "useractionmodule"}

#region internalProperties
user = null
cloud = null
recipe = null
userConfig = null
#endregion

#region userActions
allUserActions =

    editDeveloperName:
        userChoiceLabel: "edit developerName"
        execute: ->
            log "execution of editDeveloperNameAction"
            await userConfig.editDeveloperName()

    newService: 
        userChoiceLabel: "new cloudService"
        execute: ->
            log "execution of newServiceAction"
            await cloud.createConnection()

    editService: 
        userChoiceLabel: "edit cloudService" 
        execute: ->
            log " execution of editServiceAction"
            await cloud.editAnyService()

    selectMasterService: 
        userChoiceLabel: "select master cloudService" 
        execute: ->
            log " execution of selectMasterServiceAction"
            await cloud.selectMasterService()

    removeService: 
        userChoiceLabel: "remove cloudService"
        execute: ->
            log "execution of removeServiceAction"
            await cloud.removeAnyService()

    importRecipe:
        userChoiceLabel: "import thingyRecipe"
        execute: ->
            log "execution of newRecipeAction"
            await recipe.import()

    removeRecipe: 
        userChoiceLabel: "remove thingyRecipe"
        execute: ->
            log "execution of removeRecipeAction"
            await recipe.removeAnyRecipe()

    editRecipesPath:
        userChoiceLabel: "edit recipes path"
        execute: ->
            log "execution of editRecipesPathAction"
            await userConfig.editRecipesPath()

    editDefaultThingyRootPath:
        userChoiceLabel: "edit defaultThingyRoot path"
        execute: ->
            log "execution of editDefaultThingyRootPathAction"
            await userConfig.editDefaultThingyRootPath()

    editTemporaryFilesPath:
        userChoiceLabel: "edit temporaryFiles path"
        execute: ->
            log "execution of editDefaultThingyRootPathAction"
            await userConfig.editTemporaryFilesPath()

    skip:
        userChoiceLabel: "skip"
        execute: -> throw false

allActions = Object.keys(allUserActions)
# 7 = "Service".length 
allServiceActions = allActions.filter((action) -> "Service" == action.substr(-7))
# 6 = "Recipe".length 
allRecipeActions = allActions.filter((action) -> "Recipe" == action.substr(-6))
# 4 = "Path".length 
allPathActions = allActions.filter((action) -> "Path" == action.substr(-4))
#endregion

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["useractionmodule"]?  then console.log "[useractionmodule]: " + arg
    return
olog = (o) -> log "\n" + JSON.stringify(o, null, 4)
#endregion
##############################################################################
useractionmodule.initialize = () ->
    log "useractionmodule.initialize"
    user = allModules.userinquirermodule
    cloud = allModules.cloudservicemodule
    recipe = allModules.recipemodule
    userConfig = allModules.userconfigmodule
    return

#region internalFunctions
getActionChoice = (action) ->
    log "getActionChoice"
    choice = 
        name: action.userChoiceLabel
        value: action
    return choice
#endregion

#region exposedFunctions
useractionmodule.doAction = (action) ->
    log "useractionmodule.doAction"
    # log action
    # olog allUserActions[action]
    # allUserActions[action].execute()
    await action.execute()

#region addChoices
useractionmodule.addEditDeveloperNameChoice = (choices) ->
    log "useractionmodule.addEditDeveloperNameChoice"
    choices.push getActionChoice(allUserActions.editDeveloperName)
    return choices

useractionmodule.addImportRecipeChoice = (choices) ->
    log "useractionmodule.addNewRecipeChoice"
    choices.push getActionChoice(allUserActions.importRecipe)
    return choices

useractionmodule.addRecipeChoices = (choices) ->
    log "useractionmodule.addRecipeChoices"
    for action in allRecipeActions
        choices.push getActionChoice(allUserActions[action])
    return choices

useractionmodule.addNewServiceChoice = (choices) ->
    log "useractionmodule.addNewServiceChoice"
    choices.push getActionChoice(allUserActions.newService)
    return choices

useractionmodule.addServiceChoices = (choices) ->
    log "useractionmodule.addServiceChoices"
    for action in allServiceActions
        choices.push getActionChoice(allUserActions[action])
    return choices

useractionmodule.addPathEditChoices = (choices) ->
    log "useractionmodule.addServiceChoices"
    for action in allPathActions
        choices.push getActionChoice(allUserActions[action])
    return choices

useractionmodule.addSkipChoice = (choices) ->
    log "useractionmodule.addSkipChoice"
    choices.push getActionChoice(allUserActions.skip) 
    return choices
#endregion
#endregion

module.exports = useractionmodule