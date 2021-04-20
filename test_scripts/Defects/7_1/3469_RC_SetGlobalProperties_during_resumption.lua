---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3469
---------------------------------------------------------------------------------------------------
-- Description: Check SDL sends RC.SetGlobalProperties during resumption if app defines global properties
-- with 'userLocation' parameter
--
-- Steps:
-- 1. App is registered
-- 2. App sends SetGlobalProperties with 'userLocation' parameter
-- 3. App unexpectedly disconnects and reconnects
-- SDL does:
--  - Start resumption process
--  - Send RC.SetGlobalProperties with 'userLocation' parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local params = {
  userLocation = { grid = { col = 2, colspan = 1, row = 0, rowspan = 1, level = 0, levelspan = 1 } }
}
local hashId

--[[ Local Functions ]]
local function unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(common.mobile.getAppsCount())
  common.mobile.disconnect()
  utils.wait(1000)
end

local function sendSetGlobalProperties()
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties", params)
  common.getHMIConnection():ExpectRequest("RC.SetGlobalProperties", params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
end

local function reRegisterApp()
  common.app.getParams().hashID = hashId
  common.app.registerNoPTU()
  common.getHMIConnection():ExpectRequest("RC.SetGlobalProperties", params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.app.registerNoPTU)
runner.Step("Set RC Global Properties", sendSetGlobalProperties)

runner.Title("Test")
runner.Step("Unexpected disconnect", unexpectedDisconnect)
runner.Step("Connect mobile", common.mobile.connect)
runner.Step("Re-register App", reRegisterApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
