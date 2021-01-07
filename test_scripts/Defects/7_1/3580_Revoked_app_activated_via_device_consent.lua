---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/3580
--
-- Description:
-- HMI responds with UNSUPPORTED_RESOURCE to Speak component of SubtleAlert
--
-- Preconditions:
-- 1) Clean environment
-- 2) SDL, HMI, Mobile session started
-- 3) Registered app
--
-- Steps: 
-- 1) Activate app with consent
--
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local json = require("modules/json")
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require ('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }

--[[ Local Functions ]]
local function PTUfunc(tbl)
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID] = json.null
end

function activateApp(pAppId)
    if not pAppId then pAppId = 1 end
    local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(pAppId) })
    common.getHMIConnection():ExpectResponse(requestId, { result = {
        code = 4,
        isAppRevoked = true,
        method = "SDL.ActivateApp"
    }})
  :Do(function(_,_)
      local RequestId1 = common.getHMIConnection():SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      local RequestId2 = common.getHMIConnection():SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"AppUnsupported"}})

      common.getHMIConnection():ExpectResponse(RequestId1,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
        common.getHMIConnection():SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
        end)

      common.getHMIConnection():ExpectResponse(RequestId2,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
        
    end)
end

--[[ Scenario ]]
runner.Title("Precondition")
runner.Step("Clean environment and Back-up/update PPT", common.preconditions)
runner.Step("Start SDL, HMI", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PTU with empty json in requestSubType section", common.policyTableUpdate, { PTUfunc })

runner.Title("Test")
runner.Step("App activation", activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
