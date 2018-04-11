
---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Variables ]]
local m = actions

function m.putFileParams()
  local temp = {
    syncFileName = "icon.png",
    fileType = "GRAPHIC_PNG",
  }
  return temp
end

function m.CheckSum(pFile)
  local getCRCinHex = 'crc32 ' .. pFile
  local handle = io.popen(getCRCinHex)
  local checkSumHex = handle:read("*a")
  handle:close()
  local checkSumDec = tonumber(checkSumHex, 16)
  return checkSumDec
end

function m.putFile(pParams, pFile, pResult)
  if not pResult then pResult = { success = true, resultCode = "SUCCESS" } end
  local mobSession = m.getMobileSession()
  local cid = mobSession:SendRPC("PutFile", pParams, pFile)
  mobSession:ExpectResponse(cid, pResult)
end

return m
