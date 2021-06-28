------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to respond with GENERIC_ERROR:false to Mobile app in case:
--  - App sends request which is being split into 2 interfaces
--  - and HMI provides 'OnResetTimeout(resetPeriod)' for one request
--  - and HMI hasn't responded
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends RPC which is being split into 2 interfaces
-- 2) SDL sends 2 requests to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification to SDL for one request right after receiving it with 'resetPeriod=12s'
-- 4) HMI doesn't provide a response for both requests
-- SDL does:
--  - wait for the 1st response from HMI within 'default timeout' (10s)
--  - wait for the 2nd response from HMI within 'reset period' (12s)
--  - respond with GENERIC_ERROR:false to Mobile app once longest timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Functions ]]
local function addCommand()
  local params = {
    cmdID = 11,
    vrCommands = {
      "VRCommandonepositive",
      "VRCommandonepositivedouble"
    },
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local corId = common.getMobileSession():SendRPC("AddCommand", params)

  common.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function()
      -- HMi did not respond
    end)

  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.onResetTimeoutNotification(data.id, data.method, 12000)
    end)

  common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(13000)
  :ValidIf(function()
      return common.responseTimeCalculationFromNotif(12000)
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Send AddCommand" , addCommand)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
