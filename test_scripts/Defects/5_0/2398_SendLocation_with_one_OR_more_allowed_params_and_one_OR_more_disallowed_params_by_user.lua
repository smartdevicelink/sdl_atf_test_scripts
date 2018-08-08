---------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2398
--
-- Precondition:
-- In case
-- SendLocation exists at:
-- <functional_grouping_1> with <param_1>, <param_2>
-- <functional_grouping_2> with <param_3>, <param_4>
-- and <functional_grouping_1> is disallowed by user
-- and mobile app sends SendLocation with <param_1>, <param_2>, <param_3>, <param_4>
--
-- Expected:
-- SDL must:
-- transfer SendLocation with <param_3>, <param_4> only to HMI
-- respond with <received_resultCode_from_HMI> to mobile app + "info: <param_1>, <param_2> are disallowed by user" (only in case of successfull reponse from HMI)
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local test = require("user_modules/dummy_connecttest")
local events = require('events')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

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
 tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups =
 { "Base-4", "SendLocationGroup1", "SendLocationGroup2" }
end

-- Delay without expectation
-- @tparam number pTime time to wait
local function delayedExp(pTime)
  local event = events.Event()
  event.matches = function(e1, e2) return e1 == e2 end
  EXPECT_HMIEVENT(event, "Delayed event")
  :Timeout(pTime + 5000)
  local function toRun()
    event_dispatcher:RaiseEvent(actions.getHMIConnection(), event)
  end
  RUN_AFTER(toRun, pTime)
end

-- Perform user consent of "Location" group
local function makeConsent()
  -- Send GetListOfPermissions request from HMI side
  local request_id = actions.getHMIConnection():SendRequest("SDL.GetListOfPermissions")
  -- expect GetListOfPermissions response on HMI side with "Location" group
  actions.getHMIConnection():EXPECT_HMIRESPONSE(request_id,{
      result = {
        code = 0,
        method = "SDL.GetListOfPermissions",
        allowedFunctions = {{name = "Location", allowed = nil}},
        externalConsentStatus = {}
      }
    })
  :Do(function(_,data)
      -- after receiving GetListOfPermissions response on HMI side get id of "Location" group
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
        -- Sending OnAppPermissionConsent notification from HMI to SDL wit info about allowed group
        actions.getHMIConnection():SendNotification("SDL.OnAppPermissionConsent", {
            appID = actions.getHMIAppId(),
            consentedFunctions = {{name = "SendLocationAllowed", id = groupIdAllowed, allowed = true}},
            source = "GUI"
          })
      end
      if groupIdDisallowed then
        -- Sending OnAppPermissionConsent notification from HMI to SDL wit info about allowed group
        actions.getHMIConnection():SendNotification("SDL.OnAppPermissionConsent", {
            appID = actions.getHMIAppId(),
            consentedFunctions = {{name = "SendLocationNotAllowed", id = groupIdDisallowed, allowed = false}},
            source = "GUI"
          })
      else
        -- Fail test case in case GetListOfPermissions response from SDL does not contain id of group
        test:FailTestCase("GroupId for Location was not found")
      end
    end)
  -- delay in 1 sec
  delayedExp(1000)
end

local function sendLocation()
  local cid = actions.getMobileSession():SendRPC("SendLocation", requestParams)
  allowedParams.appID = actions.getHMIAppId()
  --hmi side: request, response
  EXPECT_HMICALL("Navigation.SendLocation", 
    allowedParams)
  :Do(function(_,data)
        actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
   :ValidIf(function(_,data)
        local isError = true
        local errorMessage = "locationName and locationDescription are not nil"
        if data.params.locationName ~= nil then
          errorMessage = "locationName is nil"
          isError = false
        end
        if data.params.locationDescription ~= nil then
          if isError == false then
            errorMessage = errorMessage + "and locationDescription is nil"
          else
            errorMessage = "locationDescription is nil"
            isError = false
          end
        end
        print (errorMessage)
        return isError
     end)
  --response on mobile side
  actions.getMobileSession():ExpectResponse(cid,
    { info = "'locationDescription', 'locationName' are disallowed by user", success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", actions.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", actions.start)
runner.Step("Register App", actions.registerApp)
runner.Step("Activate App", actions.activateApp)
runner.Step("PolicyTableUpdate", actions.policyTableUpdate, { ptuForApp })

runner.Title("Test")
runner.Step("Make consent for Location group", makeConsent)
runner.Step("Send Location", sendLocation)

runner.Title("Postconditions")
runner.Step("Stop SDL", actions.postconditions)
