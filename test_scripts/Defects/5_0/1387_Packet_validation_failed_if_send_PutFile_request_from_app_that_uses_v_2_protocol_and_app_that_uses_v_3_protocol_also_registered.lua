---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1387
--
-- Description:
--
-- Precondition:
-- 1) "MaximumPayloadSize" = 1488 in smartDeviceLink.ini file
-- 2) SDL and HMI are started
-- 3) app1 is registered over v.2 protocol, app2 is registered over v.3 protocol
-- 4) app1 is activated
-- In case:
-- 1) Send PutFile from app1 png_20kb.png.
-- Expected result:
-- 1) Request processed successfully
--    SDL respond with success resultcode
--    Note: There is no defect if only app1 (over v.2 protocol) registered
-- Actual result:
-- Packet validation failed
-- SDL does't send any response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local test = require("user_modules/dummy_connecttest")
local mobile_session = require('mobile_session')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local count_of_requests = 1488

local putFileParams = {
	requestParams = {
	    syncFileName = 'png_20kb.png',
	    fileType = "GRAPHIC_PNG",
	    persistentFile = false,
	    systemFile = false
	},
	filePath = "files/png_20kb.png"
}

--[[ Local Functions ]]
local function updateINIFile()
    commonFunctions:write_parameter_to_smart_device_link_ini("MaximumPayloadSize", count_of_requests)
end

local function createdSession1()
    config.defaultProtocolVersion = 2
  test.mobileSession[1] = mobile_session.MobileSession(
  test,
  test.mobileConnection,
  config.application2.registerAppInterfaceParams)
  common.getMobileSession(1).version = 2
  common.getMobileSession(1).answerHeartbeatFromSDL = true
  common.getMobileSession(1).sendHeartbeatToSDL = true
end

local function createdSession2()
    config.defaultProtocolVersion = 3
  test.mobileSession[2] = mobile_session.MobileSession(
  test,
  test.mobileConnection,
  config.application2.registerAppInterfaceParams)
  common.getMobileSession(2).version = 3
  common.getMobileSession(2).answerHeartbeatFromSDL = true
  common.getMobileSession(2).sendHeartbeatToSDL = true
end

local function putFile(params, pAppId)
    if not pAppId then pAppId = 1 end
    local cid = common.getMobileSession():SendRPC("PutFile", params.requestParams, params.filePath)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("updateINIFile", updateINIFile)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Created mobile session for app1", createdSession1)
runner.Step("Register App1", common.registerApp, {1})
runner.Step("Created mobile session for app2", createdSession2)
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Step("Upload icon file", putFile, {putFileParams })

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
