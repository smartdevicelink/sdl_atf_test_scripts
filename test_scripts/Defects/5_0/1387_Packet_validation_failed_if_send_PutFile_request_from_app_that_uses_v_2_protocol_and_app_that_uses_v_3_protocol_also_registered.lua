---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1387
--
-- Description:
--
-- Precondition:
-- 1) "MaximumPayloadSize" = 1488 in smartDeviceLink.ini file
-- 2) SDL and HMI are started
-- 3) App1 is registered over v.2 protocol, app2 is registered over v.3 protocol
-- 4) App1 is activated
-- Step:
-- 1) Send PutFile from app1 png_20kb.png.
-- SDL does:
-- 1) request processed successfully
-- 2) respond with success resultCode
-- Note: There is no defect if only app1 (over v.2 protocol) registered
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local test = require("user_modules/dummy_connecttest")
local mobile_session = require('mobile_session')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local pMaxPayloadSize = 1488

local putFileParams = {
  requestParams = {
    syncFileName = 'png_20kb.png',
    fileType = "GRAPHIC_PNG"
  },
  filePath = "files/png_20kb.png"
}

--[[ Local Functions ]]
local function updateINIFile()
  commonPreconditions:BackupFile("smartDeviceLink.ini")
  commonFunctions:write_parameter_to_smart_device_link_ini("MaximumPayloadSize", pMaxPayloadSize)
end

local function createdSession1()
  config.defaultProtocolVersion = 2
  test.mobileSession[1] = mobile_session.MobileSession(
  test,
  test.mobileConnection,
  config.application1.registerAppInterfaceParams)
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

local function putFile(params)
  local cid = common.getMobileSession():SendRPC("PutFile", params.requestParams, params.filePath)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

local function restoreINIFile()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update INI file", updateINIFile)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Mobile session for app1", createdSession1)
runner.Step("Register App1", common.registerApp, { 1 })
runner.Step("Mobile session for app2", createdSession2)
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App1", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Upload Icon File from the App1", putFile, { putFileParams })

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore .ini file", restoreINIFile)
