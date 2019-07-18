---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check successfull cases of using SetGlobalProperties RPC to set user location for RC modules allocation purposes
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) Mobile is connected to SDL
-- 3) App1 registered from Mobile
--    HMI level of App1 is FULL
--
-- Steps:
-- 1) Send SetGlobalProperties RPC with userLocation: <full grid with App1 location> from App1
--    HMI responds on RC.SetGlobalProperties request with SUCCESS
--   Check:
--    SDL sends RC.SetGlobalProperties request with userLocation: <grid with App1 location> to HMI
--    SDL responds on SetGlobalProperties RPC with resultCode: SUCCESS
-- 2) Send SetGlobalProperties RPC with userLocation: <only mandatory params grid with App1 location> from App1
--    HMI responds on RC.SetGlobalProperties request with SUCCESS
--   Check:
--    SDL sends RC.SetGlobalProperties request
--     with userLocation: <only mandatory params grid with App1 location> to HMI
--    SDL responds on SetGlobalProperties RPC with resultCode: SUCCESS
-- 3) Send SetGlobalProperties RPC without userLocation but other valid parameters from App1
--    HMI responds on UI.SetGlobalProperties request with SUCCESS
--   Check:
--    SDL does not send RC.SetGlobalProperties request to HMI
--    SDL sends UI.SetGlobalProperties request with other valid parameters to HMI
--    SDL responds on SetGlobalProperties RPC with resultCode: SUCCESS
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local grids = {
  full = { col = 2, colspan = 1, row = 0, rowspan = 1, level = 0, levelspan = 1 },
  mandatory = { col = 0, row = 1 }
}

--[[ Local Functions ]]
local function setGlobalPropertiesWithoutUserLocation()
  local mobileSession = common.getMobileSession(1)
  local hmi = common.getHMIConnection()
  local cid = mobileSession:SendRPC("SetGlobalProperties", { menuTitle = "Menu Title" })
  hmi:ExpectRequest("UI.SetGlobalProperties", { appID = common.getHMIAppId(1) })
  :Do(function(_, data)
        hmi:SendResponse(data.id, data.method, "SUCCESS")
      end)
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })

runner.Title("Test")
runner.Step("Send SetGlobalProperties with valid userLocation", common.setUserLocation, { 1, grids.full })
runner.Step("Send SetGlobalProperties with userLocation with only mandatory in grid",
    common.setUserLocation, { 1, grids.mandatory })
runner.Step("Send SetGlobalProperties without optional userLocation parameter", setGlobalPropertiesWithoutUserLocation)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
