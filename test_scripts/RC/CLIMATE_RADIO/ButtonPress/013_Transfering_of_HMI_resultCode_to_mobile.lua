---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/9
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/button_press_emulation.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Button press event emulation
--
-- Description:
-- In case:
-- 1) Application is registered with REMOTE_CONTROL appHMIType
-- 2) and sends valid ButtonPress RPC with valid parameters
-- SDL must:
-- 1) Transfer this request to HMI
-- 2) Respond with <result_code> received from HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local success_codes = { "WARNINGS" }
local error_codes = { "GENERIC_ERROR", "INVALID_DATA", "OUT_OF_MEMORY", "REJECTED" }

--[[ Local Functions ]]
local function stepSuccessfull(pModuleType, pResultCode)
	local cid = commonRC.getMobileSession():SendRPC("ButtonPress", {
    moduleType = pModuleType,
    buttonName = commonRC.getButtonNameByModule(pModuleType),
    buttonPressMode = "SHORT"
  })

  EXPECT_HMICALL("Buttons.ButtonPress", {
    appID = commonRC.getHMIAppId(),
    moduleType = pModuleType,
    buttonName = commonRC.getButtonNameByModule(pModuleType),
    buttonPressMode = "SHORT"
  })
	:Do(function(_, data)
			commonRC.getHMIConnection():SendResponse(data.id, data.method, pResultCode, {
				moduleData = commonRC.getSettableModuleControlData(pModuleType)
			})
		end)

	commonRC.getMobileSession():ExpectResponse(cid, { success = true, resultCode = pResultCode })
end

local function stepUnsuccessfull(pModuleType, pResultCode)
  local cid = commonRC.getMobileSession():SendRPC("ButtonPress", {
    moduleType = pModuleType,
    buttonName = commonRC.getButtonNameByModule(pModuleType),
    buttonPressMode = "SHORT"
  })

  EXPECT_HMICALL("Buttons.ButtonPress", {
    appID = commonRC.getHMIAppId(),
    moduleType = pModuleType,
    buttonName = commonRC.getButtonNameByModule(pModuleType),
    buttonPressMode = "SHORT"
  })
  :Do(function(_, data)
      commonRC.getHMIConnection():SendError(data.id, data.method, pResultCode, "Error error")
    end)

  commonRC.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

for _, mod in pairs(commonRC.modules) do
  runner.Title("Module: " .. mod)
  for _, code in pairs(success_codes) do
    runner.Step("ButtonPress with " .. code .. " resultCode", stepSuccessfull, { mod, code })
  end
end

for _, mod in pairs(commonRC.modules) do
  runner.Title("Module: " .. mod)
  for _, code in pairs(error_codes) do
    runner.Step("ButtonPress with " .. code .. " resultCode", stepUnsuccessfull, { mod, code })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
