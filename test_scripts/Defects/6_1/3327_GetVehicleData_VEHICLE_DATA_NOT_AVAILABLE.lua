-- User story:
--
-- Precondition:
-- 1) SDL and HMI are running.
-- 2) Application is registered and activated.
-- Description:
-- Steps to reproduce:
-- 1) Send GetVehicleData with speed = true
-- 2) SDL sends to HMI VehicleInfo.GetVehicleData: "params": {"speed":true}
-- 3) Send HMI response with VEHICLE_DATA_NOT_AVAILABLE
--{"error":{"code":9,"data":{"method":"VehicleInfo.GetVehicleData"}, message:"error message" },"id":57,"jsonrpc":"2.0"}
-- Expected result:
-- 1) SDL sends to mobile response of GetVehicleData with
--    {"resultCode":"VEHICLE_DATA_NOT_AVAILABLE", "success":false, info = "error message"}
-- Actual result:
-- 1) SDL sends to mobile response of GetVehicleData with
--    {"resultCode":"GENERIC_ERROR","success":false}
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Local Functions ]]
function common.updatePreloadedPT()
  common.sdl.backupPreloadedPT()
  local pt = common.sdl.getPreloadedPT()
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = { "speed" }
      }
    }
  }
  pt.policy_table.app_policies["default"].groups = { "Base-4", "VDTestCaseGroup" }
  pt.policy_table.functional_groupings["VDTestCaseGroup"] = VDgroup
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null
  common.sdl.setPreloadedPT(pt)
end



local function getVehicleData()
  local cid = common.mobile.getSession():SendRPC("GetVehicleData",{ speed = true })
  common.hmi.getConnection():ExpectRequest("VehicleInfo.GetVehicleData", { speed = true })
  :Do(function(_, data)
    common.hmi.getConnection():SendError(data.id, data.method, "DATA_NOT_AVAILABLE", "error message" )
  end)
  common.mobile.getSession():ExpectResponse(cid,
    { success = false, resultCode = "VEHICLE_DATA_NOT_AVAILABLE", info = "error message" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Back-up/update PPT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration without PTU", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Sends GetVehicleData request", getVehicleData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
