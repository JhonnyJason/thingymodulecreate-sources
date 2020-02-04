configmodule = {name: "configmodule"}

#region exposedProperties
configmodule.cli =
    name: "thingymodulegen"
    userRelativeConfigPath: ".config/thingyBubble/userConfig.json"
    userConfigPath: ""
#endregion

#region node_modules
pathModule = require "path"
os = require "os"
#endregion

#region pre-init
homedir = os.homedir()
userRelativeConfigPath = configmodule.cli.userRelativeConfigPath
userConfigPath = pathModule.resolve(homedir, userRelativeConfigPath)  
configmodule.cli.userConfigPath = userConfigPath
configmodule.userConfig = null
try
    configmodule.userConfig = require(configmodule.cli.userConfigPath)
catch err
#endregion

#region internalProperties
userConfigModule = null
#endregion

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["configmodule"]?  then console.log "[configmodule]: " + arg
    return
#endregion
##############################################################################
configmodule.initialize = () ->
    log "configmodule.initialize"
    userConfigModule = allModules.userconfigmodule
    return

#region exposed functions
configmodule.checkUserConfig = (configure) ->
    log "configmodule.checkUserConfig"
    if configmodule.userConfig then await userConfigModule.checkProcess(configure)
    else await userConfigModule.userConfigurationProcess()
#endregion

module.exports = configmodule