---------------------------------------------------------------------------------------------------
-- Issues:
--  https://github.com/smartdevicelink/sdl_core/issues/2451
--  https://github.com/smartdevicelink/sdl_core/issues/3934
---------------------------------------------------------------------------------------------------
-- Description: SDL does not provide the invalid values of supportedDiagModes parameter in RAI response from .ini file
--
-- Steps:
-- 1. New value in hex with out of bound size is defined in .ini file for supportedDiagModes parameter
-- 2. SDL and HMI are started
-- 3. Mobile app requests RAI
-- SDL does:
--  - not send supportedDiagModes parameter in RAI response in case value is out of min size
--  - send supportedDiagModes value with cutted off elements number to allowed size in RAI response
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local maxValue = "0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x21," ..
  "0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x41,0x42,0x43,0x44,0x45," ..
  "0x46,0x47,0x48,0x49,0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x61,0x62,0x63,0x64,0x65,0x66,0x67,0x68,0x69," ..
  "0x71,0x72,0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x81,0x82,0x83,0x84,0x85,0x86,0x87,0x88,0x89,0x91,0x92,0x93,0x94," ..
  "0x95,0x96,0x97,0x98,0x99,0x10,0x20,0x30,0x40,0x50,0x60,0x70,0x80,0x90,0x9A"

local tcs = {
  [01] = { name = "out of min size", value = "", expected = nil },
  [02] = { name = "out of max size", value = maxValue .. ",0x9B", expected = maxValue }
}

--[[ Local Functions ]]
local function getDecimalValues(pValue)
  local out = utils.splitString(pValue, ",")
  for i in pairs(out) do
    out[i] = tonumber(out[i])
  end
  return out
end

local function appRegistration(pValue)
  if pValue then pValue = getDecimalValues(pValue) end
  local session = common.mobile.createSession()
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", common.app.getParams())
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.app.getParams().appName } })
      session:ExpectResponse(corId, {
        success = true,
        resultCode = "SUCCESS",
        supportedDiagModes = pValue
      })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        end)
      :ValidIf(function(_, data)
          if not pValue and data.payload.supportedDiagModes then
            return false, "RAI response contains unexpected supportedDiagModes parameter"
          end
          return true
        end)
    end)
end

--[[ Scenario ]]
for id, tc in utils.spairs(tcs) do
  runner.Title("Test Case [" .. id .. "] check: " .. tc.name)
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Update ini file with new SupportedDiagModes value", common.sdl.setSDLIniParameter,
    { "SupportedDiagModes", tc.value })
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

  runner.Title("Test")
  runner.Step("Register App", appRegistration, { tc.expected })

  runner.Title("Postconditions")
  runner.Step("Stop SDL", common.postconditions)
end
