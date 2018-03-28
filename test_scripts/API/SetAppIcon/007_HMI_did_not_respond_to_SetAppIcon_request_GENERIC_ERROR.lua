---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0041-appicon-resumption.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
-- Description:
-- In case:
-- 1) SDL, HMI are started.
-- 2) Mobile app is registered. Sends  PutFile and SetAppIcon requests.
-- 3) HMI is not respond to SetAppIcon request. Mobile App received response SetAppIcon(GENERIC_ERROR).
-- 4) App is re-registered.
-- SDL does:
-- 1) Registers an app successfully, responds to RAI with result code "SUCCESS", "iconResumed" = false.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SetAppIcon/comSetApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  syncFileName = "icon.png"
}
local requestUiParams = {
  syncFileName = {
    imageType = "DYNAMIC",
    value = common.getPathToFileInStorage(requestParams.syncFileName)
  }
}
local allParams = {
  requestParams = requestParams,
  requestUiParams = requestUiParams
}

local function setAppIcon_GENERIC_ERROR(params, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local cid = mobSession:SendRPC("SetAppIcon", params.requestParams)
  params.requestUiParams.appID = m.getHMIAppId()
  EXPECT_HMICALL("UI.SetAppIcon", params.requestUiParams)
  :Do(function(_, _)
      -- HMI does not respond
    end)
  
  mobSession:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App registration with iconresumed = true", common.registerApp, { 1, true, true })
runner.Step("Upload icon file", common.putFile)
runner.Step("SetAppIcon", common.setAppIcon, { allParams } )
runner.Step("HMI does not respond", setAppIcon_GENERIC_ERROR, { 1, false })
runner.Step("App unregistration", common.unregisterAppInterface, { 1 })
runner.Step("App registration with iconresumed = false", common.registerApp, { 1, false, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
