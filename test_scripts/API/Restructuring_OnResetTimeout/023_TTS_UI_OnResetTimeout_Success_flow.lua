---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) HMI sends deprecated UI/TTS.OnResetTimeout notification to SDL in 5 seconds after receiving RPC request on HMI
-- 3) HMI sends response in 12 seconds after receiving request
-- SDL does:
-- 1) Respond with SUCCESS resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
	respTime = 12000,
	notificationTime = 5000
}

local RespParams = { success = true, resultCode = "SUCCESS" }

--[[ Local Functions ]]
local function setInterfaceForOnResetTimeout(pInterface)
  function common.onResetTimeoutNotification(_, pMethodName, _)
    common.getHMIConnection():SendNotification(pInterface .. ".OnResetTimeout", {
      appID = common.getHMIAppId(),
      methodName = pMethodName
    })
    common.notificationTime = timestamp()
  end
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Setting TTS interface for OnResetTimeout", setInterfaceForOnResetTimeout, { "TTS" })
common.Step("Speak with deprecated TTS.OnResetTimeout" , common.rpcs.Speak,
  { 13000, 7000, common.responseWithOnResetTimeout, paramsForRespFunction, RespParams, common.responseTimeCalculationFromNotif })
common.Step("Setting UI interface for OnResetTimeout", setInterfaceForOnResetTimeout, { "UI" })
common.Step("Slider with deprecated UI.OnResetTimeout" , common.rpcs.Slider,
  { 13000, 7000, common.responseWithOnResetTimeout, paramsForRespFunction, RespParams, common.responseTimeCalculationFromNotif })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
