---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3698
---------------------------------------------------------------------------------------------------
-- Description: Check SDL rejects invalid PTU received from App and doesn't crash
--
-- Steps:
-- 1. New app is registered
-- 2. SDL does start PTU sequence
-- 3. App provides invalid PTU during update
-- SDL does:
--  - not crash
--  - reject update
--  - switch to 'UPDATE_NEEDED' state
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.ExitOnCrash = false

--[[ Local Variables ]]
local ptuContent = '"crash"'

--[[ Local Functions ]]
local function expMsgs()
  common.hmi.getConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" })
end

local function policyTableUpdate()
  utils.tableToJsonFile = function(_, pFileName)
    local f = io.open(pFileName, "w")
    f:write(ptuContent)
    f:close()
  end
  common.ptu.policyTableUpdate(nil, expMsgs)
end

local function checkSDLStatus()
  if not common.sdl.isRunning() then common.run.fail("SDL crashed") end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.app.register)

runner.Title("Test")
runner.Step("Policy Table Update", policyTableUpdate)
runner.Step("Check SDL status", checkSDLStatus)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
