---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md 
-- User story: 
-- Use case: 
-- Item
--
-- Description:
-- In case:
-- 1) Application sends valid SetInteriorVehicleData with read-only parameters
-- 2) and one or more settable parameters in "seatControlData" struct, for moduleType: SEAT,   --Changed
-- SDL must:
-- 1) Cut the read-only parameters off and process this RPC as assigned
-- (that is, check policies, send to HMI, and etc. per existing requirements)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local function isModuleDataCorrect(pModuleType, actualModuleData)
	local isFalse = false
	for param_readonly, _ in pairs(commonRC.getModuleParams(commonRC.getReadOnlyParamsByModule(pModuleType))) do
		for param_actual, _ in pairs(commonRC.getModuleParams(actualModuleData)) do
			if param_readonly == param_actual then
				isFalse = true
				commonFunctions:userPrint(36, "Unexpected read-only parameter: " .. param_readonly)
			end
		end
	end
	if isFalse then
		return false
	end
	return true
end

local function setVehicleData(pModuleType, pParams)
	local moduleDataCombined = commonRC.getReadOnlyParamsByModule(pModuleType)
	local moduleDataSettable = { moduleType = pModuleType }
	for k, v in pairs(pParams) do
		commonRC.getModuleParams(moduleDataCombined)[k] = v
		commonRC.getModuleParams(moduleDataSettable)[k] = v
	end

	local mobSession = commonRC.getMobileSession()
	local cid = mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = moduleDataCombined
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{ appID = commonRC.getHMIAppId()]	})
	:Do(function(_, data)
			commonRC.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = moduleDataSettable
			})
		end)
	:ValidIf(function(_, data)
			if not isModuleDataCorrect(pModuleType, data.params.moduleData) then
				return false, "Test step failed, see prints"
			end
			return true
		end)

	mobileSessionkj:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
	:ValidIf(function(_, data)
			if not isModuleDataCorrect(pModuleType, data.payload.moduleData) then
				return false, "Test step failed, see prints"
			end
			return true
		end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

-- one settable parameter
for _, mod in pairs(modules) do
	local settableParams = commonRC.getModuleParams(commonRC.getSettableModuleControlData("SEAT"))
	for param, value in pairs(settableParams) do
	  runner.Step("SetInteriorVehicleData SEAT_one_settable_param_" .. param, setVehicleData, { "SEAT", { [param] = value } })
	end
end

-- all settable parameters
for _, mod in pairs(modules) do
	local settableParams = commonRC.getModuleParams(commonRC.getSettableModuleControlData("SEAT"))
	runner.Step("SetInteriorVehicleData SEAT_all_settable_params", setVehicleData, { "SEAT", settableParams })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)