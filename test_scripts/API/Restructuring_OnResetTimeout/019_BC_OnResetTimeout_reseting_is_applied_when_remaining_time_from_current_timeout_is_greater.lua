------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to reset period received in 'OnResetTimeout()' notification even in case
--  if it's lower than default timeout
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification to SDL with 'resetPeriod=6s' right after receiving request from SDL
-- 4) HMI doesn't provide a response
-- SDL does:
--  - wait for the response from HMI within 'defined timeout' (6s)
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
  notificationTime = 0,
  resetPeriod = 6000
}

local RespParams = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Send SendLocation" , common.rpcs.SendLocation,
  { 7000, 6000, common.onResetTimeoutOnly,
    paramsForRespFunction, RespParams, common.responseTimeCalculationFromNotif })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
