remotehandlermodule = {name: "remotehandlermodule"}

#region modulesFromEnvironment
#region node_modules imports
CLI         = require('clui')
Spinner     = CLI.Spinner
request     = require("request-promise")
c           = require("chalk")
#endregion

#region localModules
cloud = null
userConfig = null
globalScope = null
urlHandler = null
#endregion
#endregion

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["remotehandlermodule"]?  then console.log "[remotehandlermodule]: " + arg
    return
olog = (o) -> log "\n" + ostr(o)
ostr = (o) -> JSON.stringify(o, null, 4)
printSuccess = (arg) -> console.log(c.green(arg))
printError = (arg) -> console.log(c.red(arg))
#endregion
###############################################################################
remotehandlermodule.initialize = () ->
    log "remotehandlermodule.initialize"
    cloud = allModules.cloudservicemodule
    userConfig = allModules.userconfigmodule
    globalScope = allModules.globalscopemodule
    urlHandler = allModules.urlhandlermodule
    return

#region classes
class RemoteObject
    constructor: (@service, @repoName) ->
        log "RemoteObject.constructor"
        if @repoName.lastIndexOf(".git") == (@repoName.length - 4)
            @repoName = @repoName.substring(0, (@repoName.length - 4))
        
        httpsBase = cloud.getHTTPSBaseForService(@service)
        @httpsURL = httpsBase + "/" + @repoName + ".git"
        log "constructed httpsURL: " + @httpsURL
        
        sshBase = cloud.getSSHBaseForService(@service)
        @sshURL = sshBase + "/" + @repoName + ".git"
        log "constructed sshURL: " + @sshURL
        
        @reachability = false
        @reachabilityChecked = false

    checkReachability: ->
        if globalScope.repoIsInScope(@repoName) then return true
        options =
            method: 'HEAD',
            uri: this.httpsURL
        status = new Spinner("Checking if " + this.httpsURL + " is reachable...")
        try
            status.start()
            await request(options)
            printSuccess "Reachable!"
            @reachability = true
            return true
        catch err
            printError "Not Reachable!"
            @reachability = false
            return false
        finally
            status.stop()
            @reachabilityChecked = true

    getRepo: -> @repoName

    getHTTPS: -> @httpsURL

    getSSH: -> @sshURL

    isReachable: ->
        if !@reachabilityChecked
            console.log(c.yellow("warning! reachability has not been checked yet!"))
        return @reachability
#endregion

#region exposedFunctions
remotehandlermodule.getRemoteObject = (repoName) ->
    log "remotehandlermodule.getRemoteObject"
    service = globalScope.serviceForRepo(repoName)
    if service then return new RemoteObject(service, repoName)
    throw "No Service in globalScope for: " + repoName     
    # service = userConfig.getMasterService()
    # return new RemoteObject(service, repoName)

remotehandlermodule.createNewRemote = (repoName) ->
    log "remotehandlermodule.createNewRemote"
    service = userConfig.getMasterService()
    return new RemoteObject(service, repoName)
    
remotehandlermodule.createRemote = (serviceOrURL, repoName) ->
    log "remotehandlermodule.createRemote"
    if typeof serviceOrURL is "string" and !repoName
        return remotehandlermodule.createRemoteFromURL(serviceOrURL)
    if typeof service is "object" and repoName?
        return new RemoteObject(service, repoName)
    throw "remotehandlermodule.createRemote invalid argument variation"

remotehandlermodule.createRemoteFromURL = (url) ->
    log "remotehandlermodule.createRemoteFromURL"
    info = cloud.serviceAndRepoFromURL(url)
    return new RemoteObject(info.service, info.repoName)

remotehandlermodule.createRemoteFromUserInput = (value) ->
    log "remotehandlermodule.createRemoteFromUserInput"
    if urlHandler.isURL(value)
        if value.substr(0, 8) != "https://" then return null
        return remotehandlermodule.createRemoteFromURL(value)
    else return remotehandlermodule.getRemoteObject(value)

remotehandlermodule.checkIfRemoteIsAvailable = (value) ->
    try
        remote = remotehandlermodule.createRemoteFromUserInput(value)
        if remote then return await remote.checkReachability()
        else return "Cannot Create Remote!"
    catch err then return "Cannot Create Remote!"
#endregion

module.exports = remotehandlermodule