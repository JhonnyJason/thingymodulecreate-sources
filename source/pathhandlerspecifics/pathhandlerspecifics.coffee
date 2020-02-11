pathhandlerspecifics = {name: "pathhandlerspecifics"}
############################################################
print = (arg) -> console.log(arg)

### FYI:
This module is to be injected into the pathhandlermodule
At best keep it most minimal to the specifics of this cli
We may use everything off the pathhandlermodule using @
as @ = this. and this will be the pathhandlermodule
###

pathModule = require "path"

############################################################
pathhandlerspecifics.thingyModuleBase = "" #direcotry
pathhandlerspecifics.parentPath = "" #directory

############################################################
pathhandlerspecifics.getParentThingyName = ->
    git = allModules.gitmodule
    urlHandler = allModules.urlhandlermodule

    base = @thingyModuleBase
    @parentPath = await git.getGitRoot(base)
    @parentPath = @parentPath.replace(/\s/g, "")

    url = await git.getOriginURL(base)
    url = url.replace(/\s/g, "")
    return urlHandler.getRepo(url)

pathhandlerspecifics.prepare = ->
    cfg = allModules.configmodule

    basePath = @resolveHomeDir(cfg.userConfig.defaultThingyRoot)    
    if !pathModule.isAbsolute(basePath)
        throw "unexpected path in userConfig: " + basePath
    @basePath = basePath
    exists = await @checkDirectoryExists(basePath)
    if !exists
        throw new Error("Our basePath (" + basePath + ") does not exist!")
    @thingyModuleBase = process.cwd()
    return

module.exports = pathhandlerspecifics