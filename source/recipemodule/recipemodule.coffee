recipemodule = {name: "recipemodule"}

#region modulesFromEnvironment
#region node_modules
CLI = require 'clui'
Spinner = CLI.Spinner
c = require "chalk"
fs = require "fs-extra"
camelcase = require "camelcase"
exec = require("child_process").exec
#endregion

#region localModules
git = null
user = null
pathHandler = null
globalScope = null
userConfig = null
remoteHandler = null
#endregion
#endregion

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["recipemodule"]?  then console.log "[recipemodule]: " + arg
    return
olog = (o) -> log "\n" + ostr(o)
ostr = (o) -> JSON.stringify(o, null, 4)
printError = (arg) -> console.log(c.red(arg))
print = (arg) -> console.log(arg)
#endregion
##############################################################################
recipemodule.initialize = () ->
    log "recipemodule.initialize"
    git = allModules.gitmodule
    user = allModules.userinquirermodule
    userConfig = allModules.userconfigmodule
    globalScope = allModules.globalscopemodule
    remoteHandler = allModules.remotehandlermodule
    pathHandler = allModules.pathhandlermodule
    return

#region internalProperties
temporaryRecipes = {}

wildcardContentThingyModule = [
    ["submodule", "directory"]
    ["merge", "use", "create"]
    {
        merge:["*"]
        use: ["*"]
        create: ["*"]
    }
]
wildcardContentStaticBase = [
    ["merge"]
    {
        merge:["*"]
    }
]
#endregion

#region internalFunctions
getArbitraryConstructionChoices = ->
    log "getArbitraryConstructionChoices"
    choices = []
    choices.push {name:"merge staticBase", value:"mergeBase"}
    choices.push {name:"add thingyModule", value:"addModule"}    
    choices.push {name:"skip", value:"skip"}
    return choices

addArbitraryConstructions = (constructionPlan) ->
    log "addArbitraryConstructions"
    userChoices = getArbitraryConstructionChoices()
    loop
        userChoice = await user.inquireUserDecision(userChoices, "recipe * >")
        switch userChoice
            when "mergeBase"
                constructionPlan.push await getStaticBaseConstructionBehaviour(wildcardContentStaticBase)
            when "addModule"
                label = await user.inquireString("label for thingyModule: ", "")
                constructionPlan.push await getThingyModuleConstructionBehaviour(label, wildcardContentThingyModule)
            when "skip" then return
            else throw "unexpected userChoice: " + userChoice

getRecipeChoice = (thingyType) ->
    choice = 
        name: thingyType + " recipe"
        value: thingyType

getCheckedRecipeChoice = (element,index) ->
    choice = 
        name: element
        checked: true 

cloneAndStoreRecipe = (remote, basePath, type) ->
    log "cloneAndStoreRecipe"
    await git.clone(remote, basePath)
    localPath = pathHandler.resolve(basePath, remote.getRepo())
    recipePath = pathHandler.resolve(localPath, "recipe.json")
    individualizePath = pathHandler.resolve(localPath, "individualize.js")
    storePath = pathHandler.recipesPath
    destDir = pathHandler.resolve(storePath, type)
    pathHandler.ensureDirectoryExists(destDir)
    recipeDest = pathHandler.resolve(destDir, "recipe.json")
    individualizeDest = pathHandler.resolve(destDir, "individualize.js")
    try
        await fs.move(recipePath, recipeDest, {overwrite:true})
        await fs.move(individualizePath, individualizeDest, {overwrite:true})
    catch err then log err
    await fs.remove(localPath)
    return

loadRecipe = (type) ->
    log "loadRecipe"
    storeDir = pathHandler.resolve(pathHandler.recipesPath, type)
    recipePath = pathHandler.resolve(storeDir, "recipe.json")
    try
        recipeString = await fs.readFile(recipePath, 'utf8')
        recipe = JSON.parse(recipeString)
        return recipe
    catch err then log err
    return {}

cloneAndLoadRecipe = (remote, basePath) ->
    log "cloneAndLoadRecipe"
    thingyType = repoNameToThingyType(remote.getRepo())
    await cloneAndStoreRecipe(remote, basePath, thingyType)
    recipe = await loadRecipe(thingyType)
    return recipe

loadRecipeFromRepo = (repo) ->
    log "loadRecipeFromRepo"
    remote = remoteHandler.getRemoteObject(repo)
    basePath = pathHandler.temporaryFilesPath
    statusMessage = "Loading recipe " + repo + "..."
    status = new Spinner(statusMessage);
    status.start()
    try return await cloneAndLoadRecipe(remote, basePath)
    catch err then log err
    finally status.stop()
    return

importRecipeFromRepo = (repo) ->
    log "importRecipeFromRepo"
    thingyType = repoNameToThingyType(repo)
    remote = remoteHandler.getRemoteObject(repo)
    olog remote
    basePath = pathHandler.temporaryFilesPath
    try
        await cloneAndStoreRecipe(remote, basePath, thingyType)
        userConfig.addThingyRecipe(thingyType)
    catch err then log err
    return

repoNameToThingyType = (repo) ->
    log "repoNameToThingyType"
    repo = camelcase(repo)
    # 6 = "Recipe".length
    recipeString = repo.substr(-6)
    if recipeString != "Recipe" then throw "Invalid RepoName for Recipe!"
    return repo.substring(0, repo.length - 6)

executeScript = (script, cwd) ->
    log "executeScript"
    return new Promise (resolve, reject) ->
        callback = (error, stdout, stderr) ->
            if error then reject(error)
            if stderr then reject(new Error(stderr))
            return resolve(stdout)
        return exec("node " + script, {cwd}, callback)
  
#region constructionPlanGenerationHelper
isStaticBase = (content) ->
    if !Array.isArray(content) then return false
    arrayOptionsCount = 0
    for options in content
        ++arrayOptionsCount if Array.isArray(options)
    if arrayOptionsCount == 1 then return true
    return false

getStaticBaseConstructionBehaviour = (content) ->
    behaviour = []
    optionMap = getOptionMap(content)
    options = getStaticBaseOptions(content)
    choices = getChoicesForStaticBase(options, optionMap)
            
    if choices.length == 1
        behaviour = await evaluateUserChoiceForStaticBase(choices[0])
    else
        userChoices = createUserChoices(choices)
        userChoice = await user.inquireUserDecision(userChoices, "integrate staticBase:")
        behaviour = await evaluateUserChoiceForStaticBase(userChoice)
    return behaviour

getThingyModuleConstructionBehaviour = (label, content) ->
    behaviour = []
    optionMap = getOptionMap(content)

    options = getMountOptions(content)
    result = await getMountBehaviour(options, label)
    behaviour = behaviour.concat(result)

    options = getIntegrationOptions(content)
    result = await getIntegrationBehaviour(options, optionMap, label)
    behaviour = behaviour.concat(result)
    # log "construcion Behaviour:"
    # olog behaviour
    return behaviour

getOptionMap = (recipePropertyContent) ->
    optionMap = {}
    for options in recipePropertyContent when !Array.isArray(options)
        continue if typeof options != "object"
        Object.assign(optionMap, options)
    return optionMap

#region constructionPlanGenerationHelperForStaticBase
getStaticBaseOptions = (staticBaseContent) ->
    for options in staticBaseContent when Array.isArray(options)
        return options

getChoicesForStaticBase = (options, optionMap) ->
    # log "getChoicesForStaticBase"
    choices = []
    for option in options
        if option == "createEmpty"
            choices.push ["createEmpty"]
        if option == "merge"
            for mergeOption in optionMap.merge
                choices.push ["merge", mergeOption]
    # olog choices
    return choices

evaluateUserChoiceForStaticBase = (choice) ->
    # log "evaluateUserChoiceForStaticBase"
    if choice[0] == "createEmpty"
        return []
    choice = await destroyImpossibleChoice(choice)
    if choice[0] == "merge" and choice[1] == "*"
        message = "staticBase: merge with:"
        choice[1] = await user.inquireExistingRemote(message, "")
    return choice
#endregion

createUserChoices = (choices) ->
    # log "createUserChoices"
    # olog choices
    userChoices = []
    for choice in choices
        userChoice = {}
        userChoice.value = choice
        if Array.isArray(choice)
            userChoice.name = choice.join(" ")
        else if typeof choice == "string"
            userChoice.name = choice
        else
            throw new Error("choice to create UserChoice from is of unexpected type.")
        userChoices.push userChoice
    # log "generated userChoices"
    # olog userChoices
    return userChoices

#region constructionPlanGenerationHelperForThingyModules
getMountOptions = (content) ->
    return content[0]

getMountBehaviour = (options, label) ->
    if options.length == 1
        return [options[0], label]
    userChoices = createUserChoices(options)
    message = "add thingyModule " + label + " as: "
    choice =  await user.inquireUserDecision(userChoices, message)
    return [choice, label]

getIntegrationOptions = (content) ->
    return content[1]

getIntegrationBehaviour = (options, optionMap, label) ->
    behaviour = []
    choices = getChoicesForThingyModule(options, optionMap)
    if choices.length == 1
        behaviour = await evaluateUserChoiceForThingyModule(choices[0], label)
    else
        userChoices = createUserChoices(choices)
        message = "construct thingyModule " + label + ": "
        userChoice = await user.inquireUserDecision(userChoices, message)
        behaviour = await evaluateUserChoiceForThingyModule(userChoice, label)
    return behaviour

getChoicesForThingyModule = (options, optionMap) ->
    # log "getChoicesForThingyModule"
    choices = []
    # olog options
    for option in options
        if option == "create"
            for mergeOption in optionMap.create
                choices.push ["create", mergeOption]
        if option == "merge"
            for mergeOption in optionMap.merge
                choices.push ["merge", mergeOption]
        if option == "use"
            for mergeOption in optionMap.use
                choices.push ["use", mergeOption]
    # olog choices
    return choices

destroyImpossibleChoice = (choice) ->
    log "destroyImpossibleChoice"
    if choice[1] == "*" then return choice
    if choice[0] == "create"
        result = await recipemodule.checkIfRecipeExistsForModule(choice[1])
        if result != true 
            printError "choice " + choice[1] + " is impossible!"
            choice[1] = "*" 
    if choice[0] == "merge" or choice[0] == "use"
        try
            result = await remoteHandler.checkIfRemoteIsAvailable(choice[1])
            if result != true then throw "hi!"
        catch err 
            printError "choice " + choice[1] + " is impossible!"
            choice[1] = "*"
    return choice    

evaluateUserChoiceForThingyModule = (choice, label) ->
    # log "evaluateUserChoiceForThingyModule"
    choice = await destroyImpossibleChoice(choice)
    if choice[0] == "create" and choice[1] == "*"
        message = label + ": create thingyModule of type:"
        choice[1] = await user.inquireThingyModuleType(message, "")
    if choice[0] == "merge" and choice[1] == "*"
        message = label + ": merge with"
        choice[1] = await user.inquireExistingRemote(message, "")
    if choice[0] == "use" and choice[1] == "*"
        message = label + ": use:"
        choice[1] = await user.inquireExistingRemote(message, "")
    return choice
#endregion
#endregion
#endregion

#region exposedFunctions
recipemodule.executeIndividualize = (type, path) ->
    log "recipemodule.executeIndividualize"
    storeDir = pathHandler.resolve(pathHandler.recipesPath, type)
    scriptPath = pathHandler.resolve(storeDir, "individualize.js")
    try 
        result = await executeScript(scriptPath, path)
        print result
    catch err then log err
    return

recipemodule.import = ->
    log "recipemodule.import"
    all = globalScope.getAllThingiesInScope()
    recipes = all.filter((el) -> "recipe" == el.substr(-6))
    choices = recipes.map(getCheckedRecipeChoice)
    selection = await user.inquireSelectionSet(choices)
    promises = (importRecipeFromRepo(repo) for repo in selection)
    #region awaitImport §
    statusMessage = "Importing recipes [" + selection + "]..." 
    status = new Spinner(statusMessage);
    status.start()
    try await Promise.all(promises)
    catch err then log err
    finally status.stop()
    #endregion
    return
    
recipemodule.removeAnyRecipe = ->
    log "recipemodule.removeAnyRecipe"
    recipeChoice = await user.inquireThingyRecipeSelect()
    if recipeChoice == -1 then return
    log recipeChoice
    await userConfig.removeThingyRecipe(recipeChoice)
    return

recipemodule.getModuleRecipe = (type) ->
    log "recipemodule.getModuleRecipe"
    repoName = type + "-recipe"
    recipe = await loadRecipeFromRepo(repoName)
    return recipe

recipemodule.getRecipe = (thingyType) ->
    log "recipemodule.getRecipe"
    thingyRecipes = userConfig.getThingyRecipes()
    latestChosenType = thingyType
    if !thingyType or !thingyRecipes[thingyType]?
        if thingyType
            try return await recipemodule.getModuleRecipe(thingyType)
            catch err then log err
        message = "select thingyType: "
        userChoices = Object.keys(thingyRecipes)
        userChoice = await user.inquireUserDecision(userChoices, message)
        latestChosenType = userChoice
        recipe = await loadRecipe(userChoice)
        return recipe
    else 
        recipe = await loadRecipe(thingyType)
        return recipe

recipemodule.toConstructionPlan = (recipe) ->
    log "recipemodule.toConstructionPlan"
    constructionPlan = []
    for label, content of recipe
        if label == "*" and content then await addArbitraryConstructions(constructionPlan)
        continue if !Array.isArray(content)
        if isStaticBase(content) 
            constructionPlan.push await getStaticBaseConstructionBehaviour(content)
        else
            constructionPlan.push await getThingyModuleConstructionBehaviour(label, content)
    return constructionPlan

recipemodule.getAllRecipeChoices = ->
    log "recipemodule.getAllRecipeChoices"
    userChoices = []
    thingyRecipes = userConfig.getThingyRecipes()
    for label, content of thingyRecipes
        userChoices.push getRecipeChoice(label)
    return userChoices

## recipes for thingymodules
recipemodule.checkIfRecipeExistsForModule = (moduleName) ->
    log "recipemodule.checkIfRecipeExistsForModule"
    recipeRepo = moduleName + "-recipe"
    if globalScope.repoIsInScope(recipeRepo) then return true
    else return "We donot have a recipe for that thingyModule..."
#endregion

module.exports = recipemodule