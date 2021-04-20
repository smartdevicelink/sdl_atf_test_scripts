
---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Variables ]]
local m = actions

--[[ @getPathToFileInStorage: Get path of app icon from storage
--! @parameters:
--! pFileName - Name of file
--! pAppId - application number (1, 2, etc.)
--! @return: app icon path
--]]
function m.getPathToFileInStorage(pFileName, pAppId)
  if not pAppId then pAppId = 1 end
  return commonPreconditions:GetPathToSDL() .. "storage/"
    .. m.getConfigAppParams(pAppId).fullAppID .. "_"
    .. utils.getDeviceMAC() .. "/" .. pFileName
end

function m.putFileParams()
  local temp = {
    syncFileName = "icon.png",
    fileType = "GRAPHIC_PNG",
  }
  return temp
end

function m.getCheckSum(pFile)
  local cmd = "cat " .. pFile .. " | gzip -1 | tail -c 8 | head -c 4"
  local handle = io.popen(cmd)
  local crc = handle:read("*a")
  handle:close()
  local function bytesToInt(pStr)
    local t = { string.byte(pStr, 1, -1) }
    local n = 0
    for k = 1, #t do
      n = n + t[k] * 2 ^ ((k - 1) * 8)
    end
    return n
  end
  return bytesToInt(crc)
end

function m.putFile(pParams, pFile, pResult)
  if not pResult then pResult = { success = true, resultCode = "SUCCESS" } end
  local mobSession = m.getMobileSession()
  local cid = mobSession:SendRPC("PutFile", pParams, pFile)
  mobSession:ExpectResponse(cid, pResult)
  if pResult.success then
    EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile", {syncFileName = m.getPathToFileInStorage(pParams.syncFileName, 1), fileType = pParams.fileType})
  else
    EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile", {syncFileName = m.getPathToFileInStorage(pParams.syncFileName, 1), fileType = pParams.fileType}):Times(0)
  end
end

return m
