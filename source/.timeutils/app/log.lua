local love = require("love")
local os = require("os")
local Config = require("config")

log = {}

function log.clear()
    os.execute("rm "  .. Config.LOGFILE)
end

function log.write(message)
    os.execute("echo " .. os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message .. " >> " .. Config.LOGFILE)
end

return log