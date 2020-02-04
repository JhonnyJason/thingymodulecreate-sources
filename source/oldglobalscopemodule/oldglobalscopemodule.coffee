globalscopemodule = {name: "globalscopemodule"}

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["globalscopemodule"]?  then console.log "[globalscopemodule]: " + arg
    return
olog = (o) -> log "\n" + ostr(o)
ostr = (o) -> JSON.stringify(o, null, 4)
#endregion
##############################################################################
globalscopemodule.initialize = () ->
    log "globalscopemodule.initialize"
    return

#region internalProperties
serviceScopePairs = []
globalScope = {}
#endregion

#region internalFunctions
updateGlobalScope = ->
    log "updateGlobalScope"
    # olog serviceScopePairs
    # olog globalScope
    globalScope = {}
    addToGlobalScope(p.service, p.scope) for p in serviceScopePairs
    # olog serviceScopePairs
    # olog globalScope
    return

addToGlobalScope = (service, scope) ->
    log "addToGlobalScope"
    for repo in scope
        if !globalScope[repo]? then globalScope[repo] = service
        else if globalScope[repo].index > service.index
            globalScope[repo] = service
#endregion

#region exposedFunctions
globalscopemodule.removeRepoFromServiceScope = (repo, service) ->
    log "globalscopemodule.removeRepoFromServiceScope"
    for pair in serviceScopePairs
        if Object.is(pair.service, service)
            index = pair.scope.indexOf(repo)
            pair.scope.splice(index, 1)
            updateGlobalScope()
            return

    throw "globalscopemodule.removeRepoFromServiceScope: not implemented yet!"

globalscopemodule.addRepoToServiceScope = (repo, service) ->
    log "globalscopemodule.addRepoToServiceScope"
    for pair in serviceScopePairs
        if Object.is(pair.service, service)
            pair.scope.push repo
            updateGlobalScope()
            return

globalscopemodule.addServiceScope = (scope, service) ->
    log "cloudservicemodule.addReposToScope"
    serviceScopePair = {service, scope}
    
    ## for the case when we already have the service in a pair
    for pair, index in serviceScopePairs
        if Object.is(pair.service, service)
            serviceScopePairs[index] = serviceScopePair
            updateGlobalScope()
            return

    serviceScopePairs.push serviceScopePair
    updateGlobalScope()

globalscopemodule.removeServiceFromScope = (service) ->
    log "cloudservicemodule.removeServiceFromScope"
    for pairs, index in serviceScopePairs
        if Object.is(pairs.service, service)
            serviceScopePairs.splice(index, 1)
            updateGlobalScope()
            return ## we just altered the array
            ## to continue to loop is not a good idea

globalscopemodule.resetScope = updateGlobalScope

#region checkGlobalScope
globalscopemodule.getAllThingiesInScope = ->
    log "clourservicemodule.getAllThingiesInScope"
    return Object.keys(globalScope)

globalscopemodule.assertUserHasNotThatRepo = (repo) ->
    log "cloudservicemodule.assertUserHasNotThatRepo"
    if allReposInScope[repo]? then throw "user has that repo!"

globalscopemodule.repoIsInScope = (repo) ->
    log "cloudservicemodule.repoIsInScope"
    return globalScope[repo]?

globalscopemodule.serviceForRepo = (repo) ->
    olog globalScope
    return globalScope[repo]
#endregion
#endregion

module.exports = globalscopemodule