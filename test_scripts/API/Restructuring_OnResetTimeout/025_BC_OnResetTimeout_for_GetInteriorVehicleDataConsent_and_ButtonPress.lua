------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL postpones response to a specific Remote Control RPCs until user consent is received
--  and respond with SUCCESS:true to Mobile app in case HMI has responded
-- Applicable RPCs: 'SetInteriorVehicleData', 'ButtonPress'
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) RC access mode is set to 'ASK_DRIVER'
-- 2) RC <module> is allocated by mobile App_1
-- 3) App_2 sends 'ButtonPress' RPC for the RC <module>
-- 4) SDL sends 'RC.GetInteriorVehicleDataConsent' to HMI
-- 5) HMI sends 'BC.OnResetTimeout' to SDL with 'resetPeriod=25s' for 'RC.GetInteriorVehicleDataConsent'
--  right after receiving request
-- 6) HMI responds to 'RC.GetInteriorVehicleDataConsent(allow)' with SUCCESS resultCode in 23s
-- 7) SDL sends 'Buttons.ButtonPress' request to HMI
-- 8) HMI sends 'BC.OnResetTimeout' to SDL with 'resetPeriod=15s' for 'Buttons.ButtonPress'
--  right after receiving request
-- 9) HMI responds to 'Buttons.ButtonPress' request with SUCCESS resultCode in 13s
-- SDL does:
--  - wait for the response from HMI within 'reset period'
--  - respond with SUCCESS:true to Mobile app once response is received
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Apps configuration ]]
common.getConfigAppParams(1).appHMIType = { "REMOTE_CONTROL" }
common.getConfigAppParams(2).appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local paramsForRespFunction = {
  respTime = common.defaultTimeout + 3000,
  notificationTime = 0,
  resetPeriod = common.defaultTimeout + 5000
}

local paramsForRespFunctionConsent = {
  respTime = common.defaultTimeout + 13000,
  notificationTime = 0,
  resetPeriod = common.defaultTimeout + 15000
}

local RespParams = { success = true, resultCode = "SUCCESS" }

--[[ Local Functions ]]
local function ButtonPressWithConsentResetToBoth()
  local cid = common.getMobileSession(2):SendRPC(common.getAppEventName("ButtonPress"),
    common.getAppRequestParams("ButtonPress", "CLIMATE"))
  local requestTime = timestamp()
  local delay
  local consentRPC = "GetInteriorVehicleDataConsent"
  common.getHMIConnection():ExpectRequest(common.getHMIEventName(consentRPC), common.getHMIRequestParams(consentRPC, "CLIMATE", 2))
  :Do(function(_, data)
      paramsForRespFunctionConsent.respParams = common.getHMIResponseParams(consentRPC, true)
      common.responseWithOnResetTimeout(data, paramsForRespFunctionConsent)

      common.getHMIConnection():ExpectRequest(common.getHMIEventName("ButtonPress"),
      common.getHMIRequestParams("ButtonPress", "CLIMATE", 2))
      :Do(function(_, dataSet)
          paramsForRespFunction.respParams = common.getHMIResponseParams("ButtonPress", "CLIMATE")
          delay = timestamp() - requestTime - paramsForRespFunctionConsent.respTime
          common.responseWithOnResetTimeout(dataSet, paramsForRespFunction)
        end)
      :Timeout(common.defaultTimeout + 14000)
    end)

  common.getMobileSession(2):ExpectResponse(cid, RespParams)
  :Timeout(common.defaultTimeout + 27000)
  :ValidIf(function()
      if delay then
        return common.responseTimeCalculationFromMobReq(common.defaultTimeout + 26000 + delay, nil, requestTime)
      else
        return false, "delay calculation is failed"
      end
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App_1 registration", common.registerAppWOPTU)
common.Step("App_2 registration", common.registerAppWOPTU, { 2 })
common.Step("App_1 activation", common.activateApp)
common.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
common.Step("SetInteriorVehicleData CLIMATE", common.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData" })

common.Title("Test")
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("OnResetTimeout to ButtonPress and Consent" , ButtonPressWithConsentResetToBoth)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
