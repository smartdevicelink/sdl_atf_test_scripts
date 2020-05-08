---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/3
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Exceptions: 7.2
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
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

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function isModuleDataCorrect(pModuleType, actualModuleData)
  local isFalse = false
  for param_readonly, _ in pairs(commonRC.getModuleParams(commonRC.getReadOnlyParamsByModule(pModuleType))) do
    for param_actual, _ in pairs(commonRC.getModuleParams(actualModuleData)) do
      if param_readonly == param_actual then
        isFalse = true
        commonRC.cprint(36, "Unexpected read-only parameter: " .. param_readonly)
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
  local moduleDataSettable = { moduleType = pModuleType, moduleId = commonRC.getModuleId(pModuleType) }
  for k, v in pairs(pParams) do
    commonRC.getModuleParams(moduleDataCombined)[k] = v
    commonRC.getModuleParams(moduleDataSettable)[k] = v
  end

  local cid = commonRC.getMobileSession():SendRPC("SetInteriorVehicleData", {
    moduleData = moduleDataCombined
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", { appID = commonRC.getHMIAppId() })
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = moduleDataSettable
      })
    end)
  :ValidIf(function(_, data)
      if not isModuleDataCorrect(pModuleType, data.params.moduleData) then
        return false, "Test step failed, see prints"
      end
      return true
    end)

  commonRC.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
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
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

-- one settable parameter
for _, mod in pairs(commonRC.modules)  do
  local settableParams = commonRC.getModuleParams(commonRC.getSettableModuleControlData(mod))
  for param, value in pairs(settableParams) do
    runner.Step("SetInteriorVehicleData " .. mod .. "_one_settable_param_" .. param, setVehicleData, { mod, { [param] = value } })
  end
end

-- all settable parameters
for _, mod in pairs(commonRC.modules)  do
  local settableParams = commonRC.getModuleParams(commonRC.getSettableModuleControlData(mod))
  runner.Step("SetInteriorVehicleData " .. mod .. "_all_settable_params", setVehicleData, { mod, settableParams })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
