---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/964
--
-- Precondition:
-- SDL Core and HMI are started. App is registered, HMI level = FULL
-- Description:
-- Steps to reproduce:
-- 1) Send PutFile with file name =\syncFileName
--    SDL returns SUCCESS result, success:true
-- 2) Send SetAppIcon with file name =\syncFileName
-- 3) Send from HMI INVALID_DATA to SDL.
-- Expected:
-- 1) SDL should send to mobile result code which was sent to SDL by HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require("user_modules/utils")
local actions = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Functions ]]
local function getPathToFileInStorage(pFileName, pAppId)
  if not pAppId then pAppId = 1 end
  return commonPreconditions:GetPathToSDL() .. "storage/"
    .. actions.getConfigAppParams(pAppId).appID .. "_"
    .. utils.getDeviceMAC() .. "/" .. pFileName
end

local function putFile(self)
  local paramsSend = {
    syncFileName = "icon.png",
    fileType = "GRAPHIC_PNG"
  }
  local cid = self.mobileSession1:SendRPC( "PutFile", paramsSend, "files/icon.png")
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

local function setAppIcon_INVALID_DATA(pParams, self)
  local cid = self.mobileSession1:SendRPC("SetAppIcon", pParams.requestParams)
  pParams.requestUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("UI.SetAppIcon")
  :Do(function(_, data)
      self.hmiConnection:SendError(data.id, data.method, "INVALID_DATA", "Image does not exist!")
    end)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA", info = "Image does not exist!" })
end

--[[ Local Variables ]]
local requestParams = { syncFileName = "icon.png" }

local requestUiParams = {
  syncFileName = {
    imageType = "DYNAMIC",
    value = getPathToFileInStorage(requestParams.syncFileName)
  }
}

local allParams = {requestParams = requestParams, requestUiParams = requestUiParams }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu_n)
runner.Step("Activate App", common.activate_app)
runner.Step("Upload icon file", putFile)

runner.Title("Test")
runner.Step("SetAppIcon with INVALID_DATA response from HMI", setAppIcon_INVALID_DATA, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
