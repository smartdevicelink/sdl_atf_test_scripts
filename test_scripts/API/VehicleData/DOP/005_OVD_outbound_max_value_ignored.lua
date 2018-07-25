---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0175-Updating-DOP-value-range-for-GPS-notification.md
---------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed to get gps data
-- 2. And HMI sends OnVehicleData with outbound max value (1001) for the one of the following parameters:
-- "pdop", "hdop", "vdop"
-- SDL does:
-- 1. Ignore this notification
-- 2. Not send OnVehicleData notification to mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/DOP/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local value = 1001

--[[ Local Functions ]]
local function sendOnVehicleData(pParam)
	local gpsData = common.getGPSData()
	gpsData[pParam] = value
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = gpsData	})
	common.getMobileSession():ExpectNotification("OnVehicleData")
	:Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate, { common.ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Subscribe GPS VehicleData", common.subscribeVehicleData)
for _, p in pairs(common.params) do
  runner.Step("Send GetVehicleData param " .. p .. "=" .. tostring(value), sendOnVehicleData, { p })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

