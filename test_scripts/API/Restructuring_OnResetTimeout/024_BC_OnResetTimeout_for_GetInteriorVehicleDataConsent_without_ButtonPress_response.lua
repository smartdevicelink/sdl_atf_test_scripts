------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL postpones response to a specific Remote Control RPCs until user consent is received
--  and respond with GENERIC_ERROR:false to Mobile app in case HMI hasn't responded
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
-- 8) HMI does not respond to 'Buttons.ButtonPress' request
-- SDL does:
--  - wait for the response from HMI within 'default timeout'
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunctionConsent = {
  respTime = 23000,
  notificationTime = 0,
  resetPeriod = 25000
}

local RespParams = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Local Functions ]]
local function ButtonPress()
  local cid = common.getMobileSession(2):SendRPC(common.getAppEventName("ButtonPress"),
    common.getAppRequestParams("ButtonPress", "CLIMATE"))
  local requestTime = timestamp()
  local delay
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(common.getHMIEventName(consentRPC), common.getHMIRequestParams(consentRPC, "CLIMATE", 2))
  :Do(function(_, data)
      delay = timestamp() - requestTime
      paramsForRespFunctionConsent.respParams = common.getHMIResponseParams(consentRPC, true)
      common.responseWithOnResetTimeout(data, paramsForRespFunctionConsent)

      EXPECT_HMICALL(common.getHMIEventName("ButtonPress"),
      common.getHMIRequestParams("ButtonPress", "CLIMATE", 2))
      :Do(function()
          -- no response
        end)
      :Timeout(24000)
    end)

  common.getMobileSession(2):ExpectResponse(cid, RespParams)
  :Timeout(34000)
  :ValidIf(function()
      return common.responseTimeCalculationFromMobReq(33000 + delay, nil, requestTime)
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
common.Step("Send ButtonPress with Consent" , ButtonPress)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
