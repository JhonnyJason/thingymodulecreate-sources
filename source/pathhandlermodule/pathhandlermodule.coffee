pathhandlermodule = {name: "pathhandlermodule"}

#region modulesFromEnvironment
#region node_modules
inquirer    = require("inquirer")
git         = require("simple-git") 
c           = require('chalk');
CLI         = require('clui');
Spinner     = CLI.Spinner;
fs          = require("fs-extra")
pathModule  = require("path")
os = require "os"
exec = require("child_process").exec
#endregion

#region localModules
utl = null
cfg = null
git = null
urlHandler = null
#endregion
#endregion

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["pathhandlermodule"]?  then console.log "[pathhandlermodule]: " + arg
    return
print = (arg) -> console.log(arg)
#endregion
##############################################################################
pathhandlermodule.initialize = () ->
    log "pathhandlermodule.initialize"
    utl = allModules.utilmodule
    cfg = allModules.configmodule
    git = allModules.gitmodule
    urlHandler = allModules.urlhandlermodule
    await prepareUserConfigPath()
    return

#region internalProperties
homedir = os.homedir()

thingyName = ""
#endregion

#region internalFunctions
execGitCheckPromise = (path) ->
    options = 
        cwd: path
    
    return new Promise (resolve, reject) ->
        callback = (error, stdout, stderr) ->
            if error then reject(error)
            if stderr then reject(new Error(stderr))
            resolve(stdout)
        exec("git rev-parse --is-inside-work-tree", options, callback)

prepareUserConfigPath = ->
    log "prepareUserConfigPath"
    filePath = resolveHomeDir(cfg.cli.userConfigPath)
    dirPath = pathModule.dirname(filePath)
    await fs.mkdirp(dirPath)
    pathhandlermodule.userConfigPath = filePath
    return

resolveHomeDir = (path) ->
    log "resolveHomeDir"
    if !path then return
    if path[0] == "~"
        path = path.replace("~", homedir)
    return path

checkSomethingExists = (something) ->
    try
        await fs.lstat(something)
        return true
    catch err then return false

checkDirectoryExists = (path) ->
    try
        stats = await fs.lstat(path)
        return stats.isDirectory()
    catch err
        # console.log(c.red(err.message))
        return false

checkDirectoryIsInGit = (path) ->
    try
        await execGitCheckPromise(path)
        return true
    catch err
        # console.log(c.red(err.message))
        return false
#endregion

#region exposed
#region exposedProperties
pathhandlermodule.homedir = homedir #directory
pathhandlermodule.userConfigPath = "" #file
pathhandlermodule.basePath = "" #directory
pathhandlermodule.thingyModuleBase = "" #direcotry
pathhandlermodule.parentPath = "" #directory
pathhandlermodule.thingyPath = "" #directory
pathhandlermodule.temporaryFilesPath = "" #directory
pathhandlermodule.recipesPath = "" #directory
#endregion

#region exposedFunctions
pathhandlermodule.getParentThingyName = ->
    log "pathhandlermodule.getThingyName"
    base = pathhandlermodule.thingyModuleBase
    pathhandlermodule.parentPath = await git.getGitRoot(base)
    pathhandlermodule.parentPath = pathhandlermodule.parentPath.replace(/\s/g, "")
    url = await git.getOriginURL(base)
    url = url.replace(/\s/g, "")
    return urlHandler.getRepo(url)

pathhandlermodule.prepare = ->
    log "pathhandlermodule.checkBase"
        
    basePath = resolveHomeDir(cfg.userConfig.defaultThingyRoot)    
    if !pathModule.isAbsolute(basePath)
        throw "unexpected path in userConfig: " + basePath
    
    pathhandlermodule.basePath = basePath
    exists = await checkDirectoryExists(pathhandlermodule.basePath)
    if !exists
        throw new Error("Our basePath (" + basePath + ") does not exist!")
    pathhandlermodule.thingyModuleBase = process.cwd()

    return

pathhandlermodule.prepareTemporaryFilesPath = ->
    log "pathhandlermodule.prepareTemporaryFilesPath"
    pathhandlermodule.temporaryFilesPath = resolveHomeDir(cfg.userConfig.temporaryFiles)
    return

pathhandlermodule.prepareRecipesPath = ->
    log "pathhandlermodule.prepareRecipesPath"
    if !cfg.userConfig.recipesPath then cfg.userConfig.recipesPath = "~/.config/thingyBubble/recipes"
    pathhandlermodule.recipesPath = resolveHomeDir(cfg.userConfig.recipesPath)
    return

pathhandlermodule.ensureDirectoryExists = (directory) ->
    log "pathhandlermodule.ensureDirectoryExists"
    directory = resolveHomeDir(directory)
    result = await fs.mkdirp(directory)
    return

pathhandlermodule.somethingExistsAtBase = (name) ->
    something = pathModule.resolve(pathhandlermodule.basePath, name)
    return await checkSomethingExists(something)

pathhandlermodule.directoryExistsAtBase = (dirName) ->
    dirPath = pathModule.resolve(pathhandlermodule.basePath, dirName)
    return await checkDirectoryExists(dirPath)

pathhandlermodule.directoryExists = (dir) ->
    log "pathhandlermodule.direcotryExists"
    return await checkDirectoryExists(dir)

pathhandlermodule.resolve = pathModule.resolve

pathhandlermodule.relative = pathModule.relative
#endregion
#endregion
module.exports = pathhandlermodule