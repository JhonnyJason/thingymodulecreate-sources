urlhandlermodule = {name: "urlhandlermodule"}

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["urlhandlermodule"]?  then console.log "[urlhandlermodule]: " + arg
    return
#endregion
##############################################################################
urlhandlermodule.initialize = ->
    log "urlhandlermodule.initialize"
    return
    
#region internalFunctions
analyseURL = (url) ->
    log "analyseURLForUnknownService"
    result = {}
    ## Standard result contains
    ## https only if we have https
    ## hostURL
    ## ressourceScope 
    ## repoName 
    result.repoName = getRepoFromURL(url)
    if (url.lastIndexOf(".git") == (url.length - 4))
        url = url.slice(0, -4)    
    url = url.slice(0, -result.repoName.length)
    
    if "https://" == url.substr(0,8)
        result.https = true 
        result.hostURL = getHTTPSHostFromURL(url)
    else
        result.hostURL = getSSHHostFromURL(url)

    url = url.slice(result.hostURL.length)
    if url.charAt(0) == "/" then url = url.slice(1)
    if url.charAt(url.length - 1) == "/" then url = url.slice(0, url.length - 1)
    result.ressourceScope = url
    return result

getSSHHostFromURL = (url) ->
    log "getHostFromURL"
    end = url.lastIndexOf(":") + 1
    return url.slice(0, end)

getHTTPSHostFromURL = (url) ->
    log "getHTTPSHostFromURL"
    end = url.indexOf("/", 8)
    if end == -1 then return url
    else return url.slice(0, end)

getRepoFromURL = (url) ->
    log "getRepoFromURL"
    if (url.lastIndexOf(".git") != (url.length - 4))
        url += ".git"
    endPoint = url.lastIndexOf(".")
    if endPoint < 0
        throw new Error("Unexpectd URL: " + url)
    lastSlash = url.lastIndexOf("/")
    if lastSlash < 0
        throw new Error("Unexpectd URL: " + url)
    return url.substring(lastSlash + 1, endPoint)
#endregion

#region exposedFunctions
urlhandlermodule.isURL = (url) ->
    log "urlhandlermodule.isURL"
    if !url or typeof url != "string" then return false
    if url.length < 4 then return false
    if url.substr(0, 4) == "git@" then return true
    if url.length < 8 then return false
    if url.substr(0, 8) == "https://" then return true
    return false

urlhandlermodule.analyze = (url) ->
    log "urlhandlermodule.analyze"
    return analyseURL(url)

urlhandlermodule.getServerName = (url) ->
    log "urlhandlermodule.getServerName"
    # 8 = "https://".length
    if "https://" == url.substr(0,8)
        hostURL = getHTTPSHostFromURL(url)
        log "hostURL: " + hostURL
        return hostURL.slice(8)
    else
        hostURL = getSSHHostFromURL(url)
        log "hostURL: " + hostURL
        start = hostURL.lastIndexOf("@")
        if start > 0 then return hostURL.slice(start)
        else return hostURL 

urlhandlermodule.getHostURL = (url) ->
    log "urlhandlermodule.getServerName"
    if "https://" == url.substr(0,8)
        return getHTTPSHostFromURL(url)
    else
        return getSSHHostFromURL(url)

urlhandlermodule.getRessourceScope = (url) ->
    log "urlhandlermodule.getRessourceScope"
    result = analyseURL(url)
    return result.ressourceScope

urlhandlermodule.getRepo = (url) ->
    log "urlhandlermodule.getRepo"
    return getRepoFromURL(url)
#endregion

module.exports = urlhandlermodule