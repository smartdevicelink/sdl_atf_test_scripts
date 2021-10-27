---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2398
---------------------------------------------------------------------------------------------------
-- Description: Processing of 'SendLocation' with multiple parameters
-- in case some of them are disallowed by policies
--
-- Steps:
-- 1. In Policy DB SendLocation exists at:
--  - <functional_grouping_1> with <param_1>, <param_2>
--  - <functional_grouping_2> with <param_3>, <param_4>
-- 2. <functional_grouping_1> is disallowed by user
-- 3. App sends 'SendLocation' with <param_1>, <param_2>, <param_3>, <param_4>
--
-- SDL does:
--  - transfer 'SendLocation' only with <param_3>, <param_4> to HMI
--  - respond to App with <received_resultCode_from_HMI>  + "info: <param_1>, <param_2> are disallowed by user"
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local requestParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  locationName = "location Name",
  locationDescription = "location Description"
}

local allowedParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1
}

--[[ Local Functions ]]
local function ptuForApp(tbl)
  local AppGroup1 = {
    user_consent_prompt = "SendLocationAllowed",
    rpcs = {
      SendLocation = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "longitudeDegrees", "latitudeDegrees" }
      }
    }
  }
  local AppGroup2 = {
    user_consent_prompt = "SendLocationNotAllowed",
    rpcs = {
      SendLocation = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "locationName", "locationDescription" }
      }
    }
 }
 tbl.policy_table.functional_groupings.SendLocationGroup1 = AppGroup1
 tbl.policy_table.functional_groupings.SendLocationGroup2 = AppGroup2
 tbl.policy_table.app_policies[common.app.getParams().fullAppID].groups = {
   "Base-4", "SendLocationGroup1", "SendLocationGroup2" }
end

local function makeConsent()
  local cid = common.getHMIConnection():SendRequest("SDL.GetListOfPermissions")
  common.getHMIConnection():ExpectResponse(cid, {
      result = {
        code = 0,
        method = "SDL.GetListOfPermissions",
        allowedFunctions = {
          { name = "SendLocationAllowed", allowed = nil },
          { name = "SendLocationNotAllowed", allowed = nil }
        },
        externalConsentStatus = {}
      }
    })
  :Do(function(_,data)
      local groupIdAllowed
      local groupIdDisallowed
      for i = 1, #data.result.allowedFunctions do
        if(data.result.allowedFunctions[i].name == "SendLocationAllowed") then
          groupIdAllowed = data.result.allowedFunctions[i].id
        end
        if(data.result.allowedFunctions[i].name == "SendLocationNotAllowed") then
          groupIdDisallowed = data.result.allowedFunctions[i].id
        end
      end
      if groupIdAllowed then
        common.getHMIConnection():SendNotification("SDL.OnAppPermissionConsent", {
            appID = common.getHMIAppId(),
            consentedFunctions = {{ name = "SendLocationAllowed", id = groupIdAllowed, allowed = true }},
            source = "GUI"
          })
      end
      if groupIdDisallowed then
        common.getHMIConnection():SendNotification("SDL.OnAppPermissionConsent", {
            appID = common.getHMIAppId(),
            consentedFunctions = {{ name = "SendLocationNotAllowed", id = groupIdDisallowed, allowed = false }},
            source = "GUI"
          })
      else
        common.run.fail("GroupId for Location was not found")
      end
    end)
  common.run.wait(1000)
end

local function sendLocation()
  local cid = common.getMobileSession():SendRPC("SendLocation", requestParams)
  allowedParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("Navigation.SendLocation", allowedParams)
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_,data)
      if data.params.locationName ~= nil then
        return false, "Unexpected 'locationName' received by HMI"
      end
      if data.params.locationDescription ~= nil then
        return false, "Unexpected 'locationDescription' received by HMI"
      end
      return true
    end)
  common.getMobileSession():ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    info = "'locationDescription', 'locationName' are disallowed by user"
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate, { ptuForApp })

runner.Title("Test")
runner.Step("Make consent for Location group", makeConsent)
runner.Step("Send Location", sendLocation)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
