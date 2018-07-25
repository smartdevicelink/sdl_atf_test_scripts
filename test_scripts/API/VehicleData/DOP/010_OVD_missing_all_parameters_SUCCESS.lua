---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0175-Updating-DOP-value-range-for-GPS-notification.md
---------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed to get gps data
-- 2. And HMI sends OnVehicleData without all following parameters:
-- "pdop", "hdop", "vdop"
-- SDL does:
-- 1. Process this notification and transfer it to mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/DOP/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local value = nil

--[[ Local Functions ]]
local function sendOnVehicleData()
		local gpsData = common.getGPSData()
	for _, p in pairs(common.params) do
		gpsData[p] = value
	end
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = gpsData	})
	common.getMobileSession():ExpectNotification("OnVehicleData", { gps = gpsData	})
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
runner.Step("Send OnVehicleData all params", sendOnVehicleData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

