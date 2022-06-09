---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3906
---------------------------------------------------------------------------------------------------
-- Description: SDL does not apply PTU provided via PutFile from mobile app
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered and activated
-- 3. PTU is performed with "HapticGroup" group
-- Steps:
-- 1. App sends PutFile request with updated policy table without "HapticGroup" functional group
-- SDL does:
-- - not send SDL.OnStatusUpdate notification to HMI
-- - not send SDL.OnPermissionsChange notification to HMI
-- - not send SDL.OnAppPermissionChanged notification to HMI
-- - send BasicCommunication.OnPutFile notification to HMI
-- - respond with PutFile(success = true, resultCode = "SUCCESS") to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/8_2/3906/common_3906")

--[[ Local Functions ]]
local function ptuFunc(tbl)
  tbl.policy_table.app_policies[common.getParams().fullAppID].groups = { "Base-4" }
end

local function sendHapticData()
  local hapticDataParam = { hapticRectData = {{ id = 1, rect = { x = 1, y = 1.5, width = 1, height = 1.5 }}}}
  local cid = common.getMobileSession():SendRPC("SendHapticData", hapticDataParam)
  hapticDataParam.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.SendHapticData", hapticDataParam)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("Policy Table Update", common.policyTableUpdate, { common.ptuFuncHapticGroup })
common.Step("App sends SendHapticData SUCCESS", sendHapticData)

common.Title("Test")
common.Step("App sends PutFile with updated policy table", common.putFile, { ptuFunc })
common.Step("App sends SendHapticData SUCCESS", sendHapticData)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
