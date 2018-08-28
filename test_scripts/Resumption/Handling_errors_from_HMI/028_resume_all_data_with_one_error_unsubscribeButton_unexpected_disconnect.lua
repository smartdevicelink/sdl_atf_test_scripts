---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. ButtonSubscription and other resumption data are added by app
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App reregisters with actual HashId
-- 4. OnButtonSubscription(isSubscribed=true) notification is sent from SDL to HMI during resumption
-- 5. Rpc_n is requested from SDL
-- 6. HMI responds with error resultCode to Rpc_n request
-- SDL does:
-- 1. process unsuccess response from HMI
-- 2. remove already restored data and send OnButtonSubscription(isSubscribed=false) to HMI
-- 3. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Common Functions ]]
local function checkResumptionDataWithErrorResponse(pAppId, pErrorResponceRpc, pErrorResponseInterface)
  local rpcsRevertLocal = common.cloneTable(common.rpcsRevert)
  if pErrorResponceRpc == "addCommand" and pErrorResponseInterface == "VR" then
    rpcsRevertLocal.addCommand.VR = nil
    common.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        if data.params.type == "Command" then
          common.sendResponseWithDelay(data)
        else
          common.sendResponse(data)
        end
        if data.params.type == "Choice" then
          common.removeData.DeleteVRCommand(pAppId, data.params.type, 1)
        end
      end)
    :Times(2)
  elseif pErrorResponceRpc == "createIntrerationChoiceSet" then
    rpcsRevertLocal.addCommand.VR = nil
    common.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        if data.params.type == "Choice" then
          common.sendResponseWithDelay(data)
        else
          common.sendResponse(data)
        end
        if data.params.type == "Command" then
          common.removeData.DeleteVRCommand(pAppId, data.params.type, 1)
        end
      end)
    :Times(2)
  else
    rpcsRevertLocal[pErrorResponceRpc][pErrorResponseInterface] = nil
    common.getHMIConnection():ExpectRequest(common.getRpcName(pErrorResponceRpc, pErrorResponseInterface))
    :Do(function(_, data)
        common.sendResponseWithDelay(data, pErrorResponseInterface, pErrorResponseInterface)
      end)
  end

  for k, value in pairs (rpcsRevertLocal) do
    if common.resumptionData[pAppId][k] then
      for interface in pairs (value) do
        rpcsRevertLocal[k][interface](pAppId)
      end
    end
  end

  local isCustomButtonSubscribed = false
  local isOkButtonSubscribed = false
  local isOkButtonUnsubscribed = false
  EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
  :ValidIf(function(_, data)
      if data.params.name == "CUSTOM_BUTTON" and
      isCustomButtonSubscribed == false then
        isCustomButtonSubscribed = true
      elseif
        data.params.name == "OK" and
        data.params.isSubscribed == true and
        isOkButtonSubscribed == false then
          isOkButtonSubscribed = true
      elseif
        data.params.name == "OK" and
        data.params.isSubscribed == false and
        isOkButtonUnsubscribed == false then
          isOkButtonUnsubscribed = true
      else
        return false, "Came unexpected Buttons.OnButtonSubscription notification"
      end
      return true
    end)
  :Times(3)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for k, value in pairs(common.rpcs) do
  for _, interface in pairs(value) do
    runner.Title("Rpc " .. k .. " error resultCode to interface " .. interface)
    runner.Step("Register app", common.registerAppWOPTU)
    runner.Step("Activate app", common.activateApp)
    for rpc in pairs(common.rpcs) do
      runner.Step("Add " .. rpc, common[rpc])
    end
    runner.Step("Add buttonSubscription", common.buttonSubscription)
    runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
    runner.Step("Connect mobile", common.connectMobile)
    runner.Step("Reregister App resumption " .. k, common.reRegisterApp,
      { 1, checkResumptionDataWithErrorResponse, common.resumptionFullHMILevel, k, interface})
    runner.Step("Unregister App", common.unregisterAppInterface)
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
