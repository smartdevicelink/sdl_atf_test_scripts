---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that application will be disallowed to register with WEB_VIEW HMI type
-- if the application has no record in policies. WEB_VIEW is one of HMI types in AppHmiType parameter of RAI
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL
-- 3. PT contains record for App1 and no record for App2
--
-- Sequence:
-- 1. Application1 tries to register with WEB_VIEW appHMIType
--  a. SDL rejects registration of application (resultCode: "DISALLOWED", success: false)
---------------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.defaultMobileAdapterType = "WS"

-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appNotInPTSessionId = 2
local appHMIType = { "MEDIA", "WEB_VIEW" }

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType
config.application2.registerAppInterfaceParams.appHMIType = appHMIType

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Prepare preloaded policy table", common.updatePreloadedPT,
  { appSessionId, appHMIType })
common.Step("Start SDL, HMI, connect Mobile", common.start)

common.Title("Test")
common.Step("Registration of App2, no record in policy", common.expectRegistrationDisallowed,
  { appNotInPTSessionId })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
