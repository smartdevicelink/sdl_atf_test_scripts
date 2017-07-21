---------------------------------------------------------------------------------------------------
-- RPC: ButtonPress
-- Script: 012
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

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
      self.hmiConnection:SendError(data.id, data.method, "READ_ONLY", "Read only parameters received")
    end)

  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("ButtonPress " .. mod, getDataForModule, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
