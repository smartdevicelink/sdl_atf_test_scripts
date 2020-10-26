---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1384
--
-- Description: SDL doesn't check result code in VehicleInfo.IsReady response from HMI
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) SDL receives VehicleInfo.IsReady (error_result_code, available=true)
-- or with error code but without available parameter from the HMI
-- 3) App is registered and activated
-- In case:
-- 1) App requests GetVehicleData RPC
-- SDL does:
-- 1) respond with 'UNSUPPORTED_RESOURCE, success:false,' + 'info: VehicleInfo is not supported by system'
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
-- local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/7_0/1384/common')

--[[ Local Variables ]]
local interface = "VehicleInfo"

--[[ Local Functions ]]
local function getVehicleData()
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { gps = true })
  common.getMobileSession():ExpectResponse(cid,
    { success = false, resultCode = "UNSUPPORTED_RESOURCE", info = "VehicleInfo is not supported by system" })
end

--[[ Test ]]
for k, v in pairs(common.hmiExpectResponse) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session, HMI sends " ..tostring(k), common.start, { interface, v })
  common.Step("Register App", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)

  common.Title("Test")
  common.Step("Sends GetVehicleData", getVehicleData)

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
