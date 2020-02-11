userinquirermodule = {name: "userinquirermodule"}

#region modulesFromEnvironment
#region node_modules
inquirer = require("inquirer")
#endregion

#region localModules
cloud = null
recipe = null
userConfig = null
remoteHandler = null
#endregion
#endregion

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["userinquirermodule"]?  then console.log "[userinquirermodule]: " + arg
    return
olog = (o) -> log "\n" + ostr(o)
ostr = (o) -> JSON.stringify(o, null, 4)
printSuccess = (arg) -> console.log(c.green(arg))
printError = (arg) -> console.log(c.red(arg))
#endregion
##############################################################################
userinquirermodule.initialize = () ->
    log "userinquirermodule.initialize"
    cloud = allModules.cloudservicemodule
    recipe = allModules.recipemodule
    userConfig = allModules.userconfigmodule
    remoteHandler = allModules.remotehandlermodule
    return

#region internalFunctions
#region utilFunctions
addSeparators = (element) ->
    if element == "separator" then return new inquirer.Separator()
    return element

getSkipChoice = ->
    skipChoice = 
        name: "skip"
        value: -1

appendSkip = (typeChoices) ->
    typeChoices.push getSkipChoice()
    return typeChoices
#endregion

#region promtpFunctions
yesNoPrompt = (message, defaultValue) ->
    return [
        {
            name: "yes"
            type: "confirm"
            message: message
            default: defaultValue
        }
    ]

nextActionPrompt = (actionChoices) ->
    actionChoices = actionChoices.map(addSeparators)
    actionChoices.unshift(new inquirer.Separator())
    return [
        {
            name: "nextAction"
            type: "list"
            message: "Select a userConfigAction >"
            choices: actionChoices
            default: actionChoices[0]
        }
    ]

selectPrompt = (options) ->
    return [
        {
            name: "selection"
            type: "list"
            message: "Select an option >"
            choices: options
            default: options[0]
        }
    ]

choicePrompt = (choices, message) ->
    return [
        {
            name: "choice"
            type: "list"
            message: message
            choices: choices
            default: choices[0]
        }
    ]

cloudServiceTypePrompt = ->
    typeChoices = appendSkip([...cloud.allServiceTypes])
    return [
        {
            name: "cloudServiceType"
            type: "list"
            message: "Select a cloudServiceType >"
            choices: typeChoices
            default: typeChoices[0]
        }
    ]

thingyRecipePrompt = ->
    recipeChoices = appendSkip(recipe.getAllRecipeChoices())
    return [
        {
            name: "selectedThingyRecipe"
            type: "list"
            message: "Select a thingyRecipe >"
            choices: recipeChoices 
            default: recipeChoices[0]
        }
    ]

cloudServicePrompt = ->
    serviceChoices = appendSkip(cloud.getAllServiceChoices())
    return [
        {
            name: "selectedCloudService"
            type: "list"
            message: "Select a cloudService >"
            choices: serviceChoices 
            default: serviceChoices[0]
        }
    ]

multipleSelectionPrompt = (choices) -> 
    return [
        {
            name: "selection",
            type: "checkbox",
            message: "Select your Selection >",
            choices: choices
        }
    ]

stringPrompt = (stringLabel, current) ->
    return [
        {
            name: "userString"
            type: "input"
            message: stringLabel
            default: current
        }
    ]

passwordPrompt = (message) ->
    return [
        {
            name: "password"
            type: "password"
            message: message
        }
    ]

existingRemotePrompt = (message, defaultValue) ->
    return [
        {
            name: "remote"
            type: "input"
            message: message
            default: defaultValue
            validate: (value) ->
                log "validating value: " + value
                if value.length
                    return remoteHandler.checkIfRemoteIsAvailable(value)
                else return 'Please!'
        }
    ]

thingyModuleTypePrompt = (message, defaultValue) ->
    return [
        {
            name: "thingyModule"
            type: "input"
            message: message
            default: defaultValue
            validate: (value) ->
                if value.length
                    return recipe.checkIfRecipeExistsForModule(value)
                else return 'Please!'
        }
    ]
#endregion
#endregion

#region exposedFunctions
userinquirermodule.inquireYesNoDecision = (message, defaultValue) ->
    log "userinquirermodule.inquireYesNoDecision"
    prompt = yesNoPrompt(message, defaultValue)
    answer = await  inquirer.prompt(prompt)
    return answer.yes

userinquirermodule.inquireThingyModuleType = (message, defaultValue) ->
    log "userinquirermodule.inquireThingyModuleType"
    prompt = thingyModuleTypePrompt(message, defaultValue)
    answer = await  inquirer.prompt(prompt)
    return answer.thingyModule

userinquirermodule.inquireExistingRemote = (message, defaultValue) ->
    log "userinquirermodule.inquireExistingRemote"
    prompt = existingRemotePrompt(message, defaultValue)
    answer = await  inquirer.prompt(prompt) 
    return answer.remote

userinquirermodule.inquireUserDecision = (choices, message) ->
    log "userinquirermodule.inquireUserDecision"
    prompt = choicePrompt(choices, message)
    answer = await inquirer.prompt(prompt)
    return answer.choice

userinquirermodule.inquireSelectFrom = (options) ->
    log "userinquirermodule.inquireSelectFrom"
    question = selectPrompt(options)
    answer = await inquirer.prompt(question)
    return answer.selection

userinquirermodule.inquireNextAction = (actions) ->
    log "userinquirermodule.inquireNextAction"
    prompt = nextActionPrompt(actions)
    answer = await inquirer.prompt(prompt)
    return answer.nextAction

userinquirermodule.inquireCloudServiceType = ->
    log "userinquirermodule.inquireCloudServiceType"
    prompt = cloudServiceTypePrompt()
    answer = await inquirer.prompt(prompt)
    return answer.cloudServiceType

userinquirermodule.inquireCloudServiceSelect = ->
    log "userinquirermodule.inquireCloudServiceSelect"
    prompt = cloudServicePrompt()
    answer = await inquirer.prompt(prompt)
    return answer.selectedCloudService

userinquirermodule.inquireThingyRecipeSelect = ->
    log "userinquirermodule.inquireThingyRecipeSelect"
    prompt = thingyRecipePrompt()
    answer = await inquirer.prompt(prompt)
    return answer.selectedThingyRecipe

userinquirermodule.inquireSelectionSet = (choices) ->
    log "userinquirermodule.inquireSelectionSet"
    prompt = multipleSelectionPrompt(choices)
    answer = await inquirer.prompt(prompt)
    return answer.selection

userinquirermodule.inquireString = (stringLabel, current) ->
    log "userinquirermodule.inquireUserString"
    prompt = stringPrompt(stringLabel, current)
    answer = await inquirer.prompt(prompt)
    return answer.userString

userinquirermodule.inquirePassword = (message) ->
    log "userinquirermodule.inquirePassword"
    prompt = passwordPrompt(message)
    answer = await inquirer.prompt(prompt)
    return answer.password
#endregion

module.exports = userinquirermodule