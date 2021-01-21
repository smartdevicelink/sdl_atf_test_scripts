----------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3406
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to proceed with special characters in 'syncFileName' of 'SetAppIcon'
--
-- Steps:
-- 1. App is registered
-- 2. App uploads some icon with special character(s) in 'syncFileName'
-- 3. App sends 'SetAppIcon' with this file
-- SDL does:
--  - Transfer request to HMI
--  - Upon receive successful response from HMI transfers it to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local fileName = "action !#$&'()*+,:;=?@[].png"
local putFileParams = {
  requestParams = {
    syncFileName = fileName,
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local setAppIconParams = {
  syncFileName = fileName
}

--[[ Local Functions ]]
local function sendPutFile(pParams)
  local cid = common.getMobileSession():SendRPC("PutFile", pParams.requestParams, pParams.filePath)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function sendSetAppIcon(pParams)
  local dataToHMI = {
    syncFileName = {
      value = common.sdl.getPathToFileInStorage(pParams.syncFileName),
      imageType = "DYNAMIC"
    },
    appID = common.getHMIAppId()
  }
  local cid = common.getMobileSession():SendRPC("SetAppIcon", pParams)
  common.getHMIConnection():ExpectRequest("UI.SetAppIcon", dataToHMI)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Upload icon file", sendPutFile, { putFileParams })

runner.Title("Test")
runner.Step("App sends SetAppIcon", sendSetAppIcon, { setAppIconParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
