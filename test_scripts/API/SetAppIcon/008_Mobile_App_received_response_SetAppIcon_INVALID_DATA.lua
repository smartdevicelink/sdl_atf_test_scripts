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
-- 2) Mobile app is registered. Sends  PutFile and invalid SetAppIcon requests.
-- 3) Mobile App received response SetAppIcon(INVALID_DATA). Custom Icon is not set.
-- 4) App is re-registered.
-- SDL does:
-- 1) Successfully registers application.
-- 2) Registers an app successfully, responds to RAI with result code "SUCCESS", "iconResumed" = false.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SetAppIcon/comSetApp')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  syncFileName = "icon.pngd" -- -- invalid type of parameter
}
local requestUiParams = {
  syncFileName = {
    imageType = "DYNAMIC",
    value = common.getPathToFileInStorage(requestParams.syncFileName
  }
}
local allParams = {
  requestParams = requestParams,
  requestUiParams = requestUiParams
}

local function setAppIcon_INVALID_DATA(params, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = common.getMobileSession(pAppId)
  local cid = mobSession:SendRPC("SetAppIcon", params.requestParams)
  params.requestUiParams.appID = common.getHMIAppId()

  EXPECT_HMICALL("UI.SetAppIcon", params.requestUiParams)
  :Times(0)
  
  mobSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App registration with iconresumed = false", common.registerApp, { 1, false })
runner.Step("Upload icon file", common.putFile)
runner.Step("SetAppIcon", common.setAppIcon, { allParams } )
runner.Step("Gets_INVALID_DATA", setAppIcon_INVALID_DATA, { allParams } )
runner.Step("App unregistration", common.unregisterAppInterface, { 1 })
runner.Step("App registration with iconresumed = false", common.registerApp, { 1, false })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
