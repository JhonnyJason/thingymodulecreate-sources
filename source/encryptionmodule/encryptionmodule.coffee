encryptionmodule = {name: "encryptionmodule"}

#region node_modules
crypto = require "crypto"
#endregion

#region logPrintFunctions
##############################################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["encryptionmodule"]?  then console.log "[encryptionmodule]: " + arg
    return
#endregion
##############################################################################
encryptionmodule.initialize = () ->
    log "encryptionmodule.initialize"
    return

#region internalProperties
algorithm = 'aes-256-cbc'
hexIV = "5183222c72eec9e5"
#endregion

#region internalFunctions
hexHashPassword = (password) ->
    log "hexHashPassword"
    hash = crypto.createHash('sha1')
    hash.update(password)
    return hash.digest("hex").substring(0, 32)  
#endregion

#region exposedFunctions
encryptionmodule.decrypt = (gibbrish, password) ->
    log "encryptionmodule.decrypt"
    hexHash = hexHashPassword(password)
    decipher = crypto.createDecipheriv(algorithm, hexHash, hexIV)
    content = decipher.update(gibbrish, 'base64', 'utf8')
    content += decipher.final('utf8')
    return content

encryptionmodule.encrypt = (content, password) ->
    log "encryptionmodule.encrypt"
    hexHash = hexHashPassword(password)
    cipher = crypto.createCipheriv(algorithm, hexHash, hexIV)
    gibbrish = cipher.update(content, 'utf8', 'base64')
    gibbrish += cipher.final('base64')
    return gibbrish
#endregion

module.exports = encryptionmodule