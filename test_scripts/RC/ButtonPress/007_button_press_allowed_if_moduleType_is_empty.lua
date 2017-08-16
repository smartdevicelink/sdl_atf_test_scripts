---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/9
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/button_press_emulation.md
-- Item: Use Case 1: Exceptions: 1.2
--
-- Requirement summary:
-- [SDL_RC] Button press event emulation
-- [SDL_RC] Policy support of basic RC functionality
--
-- Description:
-- In case:
-- 1) "moduleType" in app's assigned policies has an empty array
-- 2) and RC app sends ButtonPress request with valid parameters
-- SDL must:
-- 1) Allow this RPC to be processed
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local json = require('modules/json')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function getDataForModule(pModuleType, self)
  local cid = self.mobileSession:SendRPC("ButtonPress", {
    moduleType = pModuleType,
    buttonName = commonRC.getButtonNameByModule(pModuleType),
    buttonPressMode = "SHORT"
  })

  EXPECT_HMICALL("Buttons.ButtonPress", {
    appID = self.applications["Test Application"],
    moduleType = pModuleType,
    buttonName = commonRC.getButtonNameByModule(pModuleType),
    buttonPressMode = "SHORT"
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = json.EMPTY_ARRAY
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("ButtonPress " .. mod, getDataForModule, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
