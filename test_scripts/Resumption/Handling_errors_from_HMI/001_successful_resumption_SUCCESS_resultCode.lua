---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. AddCommand, AddSubMenu, CreateInteractionChoiceSet, SetGlobalProperties, SubscribeButton, SubscribeVehicleData, SubscribeWayPoints are added by app
-- 2. Unexpected disconnect/IGN_OFF and Reconnect/IGN_ON are performed
-- 3. App reregisters with actual HashId
-- 4. HMI responds with SUCCESS resultCode to all requests from SDL
-- SDL does:
-- 1. process success responses from HMI
-- 2. restore all persistent data
-- 3. respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Function ]]
local function checkResumptionData(pAppId)
  common.addSubMenuResumption(pAppId)
  common.setGlobalPropertiesResumption(pAppId)
  common.subscribeVehicleDataResumption(pAppId)
  common.subscribeWayPointsResumption(pAppId)
  common.subscribeButtonResumption(pAppId)
  common.getHMIConnection():ExpectRequest("UI.AddCommand",
    common.resumptionData[pAppId].addCommand.UI)
  :Do(function(_, data)
      common.sendResponse(data)
    end)
  common.getHMIConnection():ExpectRequest("VR.AddCommand",
    common.resumptionData[pAppId].addCommand.VR,
    common.resumptionData[pAppId].createIntrerationChoiceSet.VR)
  :Do(function(_, data)
      common.sendResponse(data)
    end)
  :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app", common.registerAppWOPTU)
runner.Step("Activate app", common.activateApp)

runner.Title("Test")
for k in pairs(common.rpcs) do
  runner.Step("Add " .. k, common[k])
end
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption data", common.reRegisterAppSuccess,
  { 1, checkResumptionData, common.resumptionFullHMILevel})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
