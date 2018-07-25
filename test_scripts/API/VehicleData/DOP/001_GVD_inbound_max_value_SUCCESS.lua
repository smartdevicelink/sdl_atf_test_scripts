---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0175-Updating-DOP-value-range-for-GPS-notification.md
---------------------------------------------------------------------------------------------------
-- In case:
-- 1. App sends 'GetVehicleData' request with gps=true
-- 2. And SDL transfer this request to HMI
-- 3. And HMI respond with gps data with one of the following parameters set to inbound max value (1000):
-- "pdop", "hdop", "vdop"
-- SDL does:
-- 1. Process this response and transfer it to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/DOP/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local value = 1000

--[[ Local Functions ]]
local function sendGetVehicleData(pParam)
	local gpsData = common.getGPSData()
	gpsData[pParam] = value
	local cid = common.getMobileSession():SendRPC("GetVehicleData", { gps = true })
	common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { gps = true })
	:Do(function(_, data)
			common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = gpsData	})
		end)
	common.getMobileSession():ExpectResponse(cid, {	success = true,	resultCode = "SUCCESS",	gps = gpsData	})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate, { common.ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, p in pairs(common.params) do
  runner.Step("Send GetVehicleData param " .. p .. "=" .. tostring(value), sendGetVehicleData, { p })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

