---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3906
---------------------------------------------------------------------------------------------------
-- Description: SDL does not apply PTU provided via PutFile from mobile app during PTU sequence
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered and activated
-- SDL does:
--  - start PTU and sends SDL.OnStatusUpdate(UPDATE_NEEDED, UPDATING) to HMI
-- 3. SDL sends OnSystemRequest(PROPRIETARY) request to App
-- Steps:
-- 1. App sends PutFile request with updated policy table includes "HapticGroup" functional group
-- SDL does:
-- - not send SDL.OnStatusUpdate notification to HMI
-- - not send SDL.OnPermissionsChange notification to HMI
-- - not send SDL.OnAppPermissionChanged notification to HMI
-- - send BasicCommunication.OnPutFile notification to HMI
-- - respond PutFile(success = true, resultCode = "SUCCESS") to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/8_2/3906/common_3906")

--[[ Test Configuration ]]
common.testSettings.restrictions.sdlBuildOptions = {{ extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" }}}

--[[ Local Functions ]]
local function policyTableUpdateProprietary(pPTUpdateFunc)
  local requestId = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
    { policyType = "module_config", property = "endpoints" })
  common.getHMIConnection():ExpectResponse(requestId)
  :Do(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = common.getPTSFilePath() })
      local event = common.createEvent()
      common.getHMIConnection():ExpectEvent(event, "PTU event")
      common.getMobileSession():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          common.putFile(pPTUpdateFunc)
          common.getHMIConnection():RaiseEvent(event, "PTU event")
        end)
        :Times(AtMost(1))
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends PutFile with updated policy table", policyTableUpdateProprietary, { common.ptuFuncHapticGroup })
common.Step("App sends SendHapticData DISALLOWED", common.sendHapticDataDisallowed)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
