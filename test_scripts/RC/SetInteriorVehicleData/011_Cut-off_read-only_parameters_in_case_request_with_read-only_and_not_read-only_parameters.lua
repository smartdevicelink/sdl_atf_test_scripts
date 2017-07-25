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

local function getModuleParams(pModuleData)
	if pModuleData.climateControlData then
		return pModuleData.climateControlData
	elseif pModuleData.radioControlData then
		return pModuleData.radioControlData
	end
end

local function getNonReadOnlyParams(pModuleType)
	local params_all = getModuleParams(commonRC.getModuleControlData(pModuleType))
	local params_read_only = getModuleParams(commonRC.getReadOnlyParamsByModule(pModuleType))
	local params_settable = { }
	for p, v in pairs(params_all) do
		local isSettable = true
		for p_read_only, _ in pairs(params_read_only) do
			if p == p_read_only then
				isSettable = false
			end
		end
		if isSettable then
			params_settable[p] = v
		end
	end
	return params_settable
end

local function setVehicleData(pModuleType, pParams, self)
	local moduleDataReadOnly = commonRC.getReadOnlyParamsByModule(pModuleType)
	local moduleDataCombined = commonFunctions:cloneTable(moduleDataReadOnly)

	for k, v in pairs(pParams) do
		getModuleParams(moduleDataCombined)[k] = v
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
			for param_readonly, _ in pairs(getModuleParams(commonRC.getReadOnlyParamsByModule(pModuleType))) do
				for param_actual, _ in pairs(getModuleParams(data.params.moduleData)) do
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
	for param, value in pairs(getNonReadOnlyParams(mod)) do
	  runner.Step("SetInteriorVehicleData " .. mod .. "_one_settable_param_" .. param, setVehicleData, { mod, { [param] = value } })
	end
end

-- all settable parameters
for _, mod in pairs(modules) do
	runner.Step("SetInteriorVehicleData " .. mod .. "_all_settable_params", setVehicleData, { mod, getNonReadOnlyParams(mod) })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
