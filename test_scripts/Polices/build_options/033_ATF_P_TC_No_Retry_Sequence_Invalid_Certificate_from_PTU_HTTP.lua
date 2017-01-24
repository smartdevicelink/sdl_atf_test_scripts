-- UNREADY - Securuty is not implemented in ATF according to
-- https://github.com/smartdevicelink/sdl_atf_test_scripts/pull/291/
-- function not implemented 
---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PTU]: SDL must NOT perform retry sequence in case 
-- PTU does not bring the valid certificate
--
-- Description:
-- In case the "24 hours" trigger worked, but valid PTU does not bring a certificate, 
-- SDL should not perform a retry sequence for getting the PTU with a certificate.
-- 1. Used preconditions:
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- SDL and HMI are started and running
-- App is registered
-- Current date is "24 hours prior to module's certificate expiration date
-- Trigger for certificate expiration status check is IGN_ON 
-- SDL: Checks expiration date of certificate against current date 
-- PTU sequence is waiting for SystemRequest from mobile app_ID
-- 2. Performed steps:
-- app->SDL:SystemRequest (PTU in binary data doesn't contain certificate)
-- Expected result:
-- regular sequence of PTU (no retry sequence observed)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--TODO(mmihaylova): Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]

commonFunctions:newTestCasesGroup("Preconditions")

--[[ Test ]]

function Test.TestStep_PTU_Without_Certificate()
  return false
end

--[[ Postconditions ]]

commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
