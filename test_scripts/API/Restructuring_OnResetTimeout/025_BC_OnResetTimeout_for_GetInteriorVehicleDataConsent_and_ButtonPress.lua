---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RC access mode is set to 'ASK_DRIVER'
-- 2) RC <module> is allocated by mobile App_1
-- 3) App_2 sends 'ButtonPress' with button related to RC <module>
-- 4) SDL sends RC.GetInteriorVehicleDataConsent
-- 5) HMI sends BC.OnResetTimeout(resetPeriod = 25000) to SDL for RC.GetInteriorVehicleDataConsent
--  right after receiving requests on HMI
-- 6) HMI responds to RC.GetInteriorVehicleDataConsent with SUCCESS resultCode in 23 seconds
--  after receiving HMI requests
-- 7) SDL sends Buttons.ButtonPress to HMI
-- 8) HMI sends BC.OnResetTimeout(resetPeriod = 15000) to SDL Buttons.ButtonPress
--  right after receiving requests on HMI
-- 9) HMI responds to Buttons.ButtonPress with SUCCESS resultCode in 13 seconds after receiving HMI requests
-- SDL does:
--  - Respond in 36 seconds with SUCCESS resultCode to mobile App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
  respTime = 13000,
  notificationTime = 0,
  resetPeriod = 15000
}

local paramsForRespFunctionConsent = {
  respTime = 23000,
  notificationTime = 0,
  resetPeriod = 25000
}

local RespParams = { success = true, resultCode = "SUCCESS" }

--[[ Local Functions ]]
local function ButtonPressWithConsentResetToBoth()
  local cid = common.getMobileSession(2):SendRPC(common.getAppEventName("ButtonPress"),
    common.getAppRequestParams("ButtonPress", "CLIMATE"))
  local requestTime = timestamp()
  local delay
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(common.getHMIEventName(consentRPC), common.getHMIRequestParams(consentRPC, "CLIMATE", 2))
  :Do(function(_, data)
      paramsForRespFunctionConsent.respParams = common.getHMIResponseParams(consentRPC, true)
      common.responseWithOnResetTimeout(data, paramsForRespFunctionConsent)

      EXPECT_HMICALL(common.getHMIEventName("ButtonPress"),
      common.getHMIRequestParams("ButtonPress", "CLIMATE", 2))
      :Do(function(_, dataSet)
          paramsForRespFunction.respParams = common.getHMIResponseParams("ButtonPress", "CLIMATE")
          delay = timestamp() - requestTime - paramsForRespFunctionConsent.respTime
          common.responseWithOnResetTimeout(dataSet, paramsForRespFunction)
        end)
      :Timeout(24000)
    end)

  common.getMobileSession(2):ExpectResponse(cid, RespParams)
  :Timeout(37000)
  :ValidIf(function()
      return common.responseTimeCalculationFromMobReq(36000 + delay, nil, requestTime)
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
