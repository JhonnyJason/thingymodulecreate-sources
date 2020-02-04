Modules = require "./allmodules.js"

global.allModules = Modules

run = ->
    promises = (m.initialize() for n,m of Modules)
    await Promise.all(promises) 
    Modules.startupmodule.cliStartup()
    return

run()
