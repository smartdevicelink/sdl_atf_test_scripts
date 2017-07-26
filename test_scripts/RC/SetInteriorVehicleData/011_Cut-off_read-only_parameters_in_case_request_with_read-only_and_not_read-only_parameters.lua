---------------------------------------------------------------------------------------------------
-- Description
-- In case:
-- 1) Application sends valid SetInteriorVehicleData with read-only parameters
-- 2) and one or more settable parameters in "radioControlData" struct, for moduleType: RADIO,
-- SDL must:
-- 1) Cut the read-only parameters off and process this RPC as assigned
-- (that is, check policies, send to HMI, and etc. per existing requirements)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

local function setVehicleData(pModuleType, pParams, self)
	local moduleDataReadOnly = commonRC.getReadOnlyParamsByModule(pModuleType)
	local moduleDataCombined = commonFunctions:cloneTable(moduleDataReadOnly)

	for k, v in pairs(pParams) do
		commonRC.getModuleParams(moduleDataCombined)[k] = v
	end

	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = moduleDataCombined
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = self.applications["Test Application"],
		moduleData = moduleDataReadOnly
	})
	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = moduleDataReadOnly
			})
		end)
	:ValidIf(function(_, data)
			local isFalse = false
			for param_readonly, _ in pairs(commonRC.getModuleParams(commonRC.getReadOnlyParamsByModule(pModuleType))) do
				for param_actual, _ in pairs(commonRC.getModuleParams(data.params.moduleData)) do
					if param_readonly == param_actual then
						isFalse = true
						commonFunctions:userPrint(36, "Unexpected read-only parameter: " .. param_readonly)
					end
				end
			end
			if isFalse then
				return false, "Test step failed, see prints"
			end
			return true
		end)

	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

-- one settable parameter
for _, mod in pairs(modules) do
	local settableParams = commonRC.getModuleParams(commonRC.getSettableModuleControlData(mod))
	for param, value in pairs(settableParams) do
	  runner.Step("SetInteriorVehicleData " .. mod .. "_one_settable_param_" .. param, setVehicleData, { mod, { [param] = value } })
	end
end

-- all settable parameters
for _, mod in pairs(modules) do
	local settableParams = commonRC.getModuleParams(commonRC.getSettableModuleControlData(mod))
	runner.Step("SetInteriorVehicleData " .. mod .. "_all_settable_params", setVehicleData, { mod, settableParams })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
