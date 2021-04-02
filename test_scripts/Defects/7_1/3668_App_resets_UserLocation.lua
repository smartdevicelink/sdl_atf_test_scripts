----------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3668
----------------------------------------------------------------------------------------------------
-- Description: Check App is able to reset previously defined 'UserLocation' to default values
--
-- Steps:
-- 1. App is registered
-- 2. App sends 'SetGlobalProperties' with some non-default values for 'UserLocation'
-- 3. App sends 'ResetGlobalProperties' for 'USER_LOCATION'
-- SDL does:
--  - Send default values for 'USER_LOCATION' to HMI within 'RC.SetGlobalProperties' request
--  - By receiving successful response from HMI transfer it to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local grids = {
  DRIVER = { col = 0, colspan = 1, row = 0, rowspan = 1, level = 0, levelspan = 1 },
  FRONT_PASSENGER = { col = 2, colspan = 1, row = 0, rowspan = 1, level = 0, levelspan = 1 }
}

--[[ Local Functions ]]
local function setUserLocation(pGrid)
  local mobileSession = common.mobile.getSession()
  local hmi = common.hmi.getConnection()
  local cid = mobileSession:SendRPC("SetGlobalProperties", { userLocation = { grid = pGrid }})
  hmi:ExpectRequest("RC.SetGlobalProperties", {
    userLocation = { grid = pGrid },
    appID = common.app.getHMIId()
  })
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS")
    end)
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", {} })
end

local function sendResetGlobalProperties(pGrid)
  local mobileSession = common.mobile.getSession()
  local hmi = common.hmi.getConnection()
  local params = { properties = { "USER_LOCATION" } }
  local dataToHMI = {
    userLocation = { grid = pGrid },
    appID = common.app.getHMIId()
  }
  local cid = mobileSession:SendRPC("ResetGlobalProperties", params)
  hmi:ExpectRequest("RC.SetGlobalProperties", dataToHMI)
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("Send SetGlobalProperties with userLocation (Front Passenger)",
  setUserLocation, { grids.FRONT_PASSENGER })
runner.Step("Send ResetGlobalProperties with 'USER_LOCATION'",
  sendResetGlobalProperties,  { grids.DRIVER })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
