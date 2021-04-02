----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App is able to receive 'WARNINGS' response with appropriate 'info'
-- for 'SetGlobalProperties' request in case if a certain special character is not supported by HMI
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with non-supported special character in 'customKeys' parameter
-- in 'KeyboardProperties'
-- SDL does:
--  - Transfer request to HMI
-- 4. HMI responds with successful 'WARNINGS' message
-- SDL does:
--  - Respond with 'WARNINGS', success:true to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Functions ]]
local function sendSetGlobalProperties()
  local sgpParams = {
    keyboardProperties = {
      keyboardLayout = "NUMERIC",
      customKeys = { "^" } -- special character that is not supported by HMI
    }
  }
  local dataToHMI = common.cloneTable(sgpParams)
  dataToHMI.appID = common.getHMIAppId()
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties", sgpParams)
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "WARNINGS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated)
common.Step("App sends SetGlobalProperties warnings", sendSetGlobalProperties)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
