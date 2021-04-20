---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1218
--
-- Precondition:
-- 1) SDL is built with EXTERNAL_PROPRIETARY flag.
-- 2) SDL and HMI are started. First ignition cycle.
-- 3) Connect device
-- 4) Register new application

-- Description:
-- Steps to reproduce:
-- 1) App sends valid "PutFile" request
-- Expected:
-- 1) Successful process PutFile{ success = true, resultCode = "SUCCESS", spaceAvailable=xxx}.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Functions ]]
local function putFileSUCCESS(self)
  local paramsSend = {
    syncFileName = "icon.png",
    fileType = "GRAPHIC_PNG"
  }
  local cid = self.mobileSession1:SendRPC( "PutFile", paramsSend, "files/icon.png")
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  :ValidIf(function(_, data)
  	if data.payload.spaceAvailable ~= nil then
  		return true
  	else
  		return false, "PutFile response does not contain spaceAvailable parameter."
  	end
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu_n)
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("Successful processing PutFile", putFileSUCCESS)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
