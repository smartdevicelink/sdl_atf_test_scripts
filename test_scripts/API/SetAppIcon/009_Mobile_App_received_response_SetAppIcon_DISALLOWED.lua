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
-- 2) SetAppIcon does not exist in app's assigned policies.
-- 3) Mobile app is registered. Sends  PutFile and valid SetAppIcon requests.
-- 4) Mobile app received response SetAppIcon(DISALLOWED)
-- 5) Mobile app is re-registered.
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
    value = common.getPathToFileInStorage(requestParams.syncFileName
  }
}
local allParams = {
  requestParams = requestParams,
  requestUiParams = requestUiParams
}

--[[ Local Functions ]]
local function setAppIcon_DISALLOWED(params, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = common.getMobileSession(pAppId)
  local cid = mobSession:SendRPC("SetAppIcon", params.requestParams)
  params.requestUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("UI.SetAppIcon", params.requestUiParams)
  :Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

local function updatePTU(tbl)
  tbl.policy_table.app_policies[config.application.registerAppInterfaceParams.appID]. ImageFieldName = { "appIcon" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App registration with iconresumed = true", common.registerApp, { 1, true })
runner.Step("Upload icon file", common.putFile)
runner.Step("SetAppIcon", setAppIcon, { allParams } )
runner.Step("Mobile App received response SetAppIcon(DISALLOWED)", setAppIcon_DISALLOWED, { allParams } )
runner.Step("App unregistration", common.unregisterAppInterface, { 1 })
runner.Step("App registration with iconresumed = false", common.registerApp, { 1, false })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
