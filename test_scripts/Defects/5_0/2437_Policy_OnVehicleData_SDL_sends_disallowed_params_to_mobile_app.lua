---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2437
--
-- Precondition:
-- 1) Core, HMI started.
-- 2) App registered and activated on HMI.
-- 3) SubscribeVehicleData(all parameters): SUCCESS
-- 4) OnVehicleData with "speed", "rpm","fuelLevel", "fuelLevel_State", "driverBraking" is presented in Group1. Group1 has userConsent.
-- 5) OnVehicleData with "airbagStatus", "beltStatus", "driverBraking" is presented in Base-4
-- 6) Group1 and Base-4 are assigned to app.
--
-- Steps to reproduce:
-- 1) User answers "Yes" for Consent.
-- 2) Send OnVehicleData with params below:
--    (Disallowed param) instantFuelConsumption = 0.000000,
--    (Disallowed param) externalTemperature = -40.000000,
--    (Allowed param)speed = 0.0,
--    (Allowed param)fuelLevel = -6.000000,
--    (Allowed param)driverBraking = "NO_EVENT"
--
-- Expected result:
-- 1) SDL should send OnVehicleData notification with allowed params to mobile app.
--    {"driverBraking":"NO_EVENT","speed":0,"fuelLevel":-6}
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local variables ]]
local onVDNotificationFromHMI = {
  speed = 0.0,
  fuelLevel = -6.000000,
  instantFuelConsumption = 0.000000,
  externalTemperature = -40.000000,
  rpm = 0,
  fuelLevel_State = "UNKNOWN",
  driverBraking = "NO_EVENT"
}

local validResponseOnVDnotification = {
  speed = 0.0,
  fuelLevel = -6.000000,
  rpm = 0,
  fuelLevel_State = "UNKNOWN",
  driverBraking = "NO_EVENT"
}

local VDValues = {
    driverBraking = "VEHICLEDATA_BRAKING",
    speed = "VEHICLEDATA_SPEED",
    rpm = "VEHICLEDATA_RPM",
    fuelLevel = "VEHICLEDATA_FUELLEVEL",
    fuelLevel_State = "VEHICLEDATA_FUELLEVEL_STATE"
}

local responseUiParams = { }
local requestParams = { }

--[[ Local Functions ]]
local function ptuForApp(tbl)
 local AppGroup1 = {
   user_consent_prompt = "SubscribeVDAllowed",
   rpcs = {
    SubscribeVehicleData = {
       hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
       parameters = { "speed", "rpm", "fuelLevel", "fuelLevel_State", "driverBraking" }
    },
     OnVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "speed", "rpm", "fuelLevel", "fuelLevel_State", "driverBraking" }
    }
   }
 }
 tbl.policy_table.functional_groupings.Group1 = AppGroup1
 tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
   { "Base-4", "Group1" }
end

local function makeConsent()
    -- Send GetListOfPermissions request from HMI side
    local request_id = common.getHMIConnection():SendRequest("SDL.GetListOfPermissions")
    -- expect GetListOfPermissions response on HMI side with "Location" group
    common.getHMIConnection():EXPECT_HMIRESPONSE(request_id,{
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
        for i = 1, #data.result.allowedFunctions do
          if(data.result.allowedFunctions[i].name == "SubscribeVDAllowed") then
            groupIdAllowed = data.result.allowedFunctions[i].id
          end
        end
        if groupIdAllowed then
          -- Sending OnAppPermissionConsent notification from HMI to SDL wit info about allowed group
          common.getHMIConnection():SendNotification("SDL.OnAppPermissionConsent", {
              appID = common.getHMIAppId(),
              consentedFunctions = {{name = "SubscribeVDAllowed", id = groupIdAllowed, allowed = true}},
              source = "GUI"
            })
        end
      end)
    -- delay in 1 sec
    utils.wait(1000)
end

local function setVDRequest()
    local tmp = {}
    for k, _ in pairs(VDValues) do
      tmp[k] = true
    end
    return tmp
end

local function setVDResponse()
    local temp = { }
    local vehicleDataResultCodeValue = "SUCCESS"
    for key, value in pairs(VDValues) do
      local paramName = "clusterModeStatus" == key and "clusterModes" or key
        temp[paramName] = {
          resultCode = vehicleDataResultCodeValue,
          dataType = value
        }
    end
    return temp
end

local function subscribeVD()
    requestParams = setVDRequest()
    local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", requestParams)
    responseUiParams = setVDResponse()
    common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", requestParams)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", responseUiParams)
    end)
    local MobResp = responseUiParams
    MobResp.success = true
    MobResp.resultCode = "SUCCESS"
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession():ExpectNotification("OnHashChange")
end

local function sendOnVehicleData()
    common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", onVDNotificationFromHMI)
    common.getMobileSession():ExpectNotification("OnVehicleData", validResponseOnVDnotification)
    :ValidIf(function()
        if (onVDNotificationFromHMI == validResponseOnVDnotification) then
            return false, "Unexpected parameters in VehicleInfo.OnVehicleData notification from SDL"
        else
            return true, "Expected parameters in VehicleInfo.OnVehicleData notification from SDL"
        end
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("RAI, PTU", common.policyTableUpdate, { ptuForApp })
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Make consent for group1", makeConsent)
runner.Step("SubscribeVehicleData", subscribeVD)
runner.Step("Send OnVehicleData ", sendOnVehicleData)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
