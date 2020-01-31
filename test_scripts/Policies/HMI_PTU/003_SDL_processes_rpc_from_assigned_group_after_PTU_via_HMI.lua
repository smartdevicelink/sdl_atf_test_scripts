---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
--
-- Description: Check that SDL correctly processes RPC after PTU via HMI was performed
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. App is registered
-- 3. PTU via HMI was performed successfully
-- 4. App is activated
--
-- Steps:
-- 1) App sends GetVehicleData request from the allowed group according to PTU
-- SDL does:
--   a) send VehicleInfo.GetVehicleData request to the HMI
-- 2) HMI sends successful response VehicleInfo.GetVehicleData to the SDL
-- SDL does:
--   a) send GetVehicleData( resultCode = SUCCESS ) response to the App
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[Local Variables]]
local requestData = { fuelLevel = true }
local responseData = { fuelLevel = 34 }

--[[Local Functions]]
local function sendAllowedRPC(pRequestData, pResponseData)
  local cid = common.mobile():SendRPC("GetVehicleData", pRequestData)
  common.hmi():ExpectRequest("VehicleInfo.GetVehicleData", pRequestData)
  :Do(function(_, data)
      common.hmi():SendResponse(data.id, data.method, "SUCCESS", pResponseData)
    end)

  common.mobile():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", fuelLevel = pResponseData.fuelLevel })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU via HMI", common.ptuViaHMI, { common.PTUfuncWithNewGroup })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send allowed GetVehicleData RPC from the App", sendAllowedRPC, { requestData, responseData })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
