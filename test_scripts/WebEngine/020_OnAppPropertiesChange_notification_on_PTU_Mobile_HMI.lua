---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the OnAppPropertiesChange notification on update from (PTU, Mobile, HMI) to HMI
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered
--
-- Sequence:
-- 1. PTU is performed, the update contains app properties of the policyAppID
--  a. SDL sends BC.OnAppPropertiesChange notification with appropriate app properties parameters to HMI
-- 2. MobileApp sends BC.SetAppProperties request with application properties of the policyAppID to SDL
--  a. SDL sends successful response to MobileApp
--  b. SDL sends BC.OnAppPropertiesChange notification with appropriate app properties parameters to HMI
-- 3. HMI sends BC.SetAppProperties request with application properties of the policyAppID to SDL
--  a. SDL sends successful response to HMI
--  b. SDL sends BC.OnAppPropertiesChange notification with appropriate app properties parameters to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appPropPTU = {
  nicknames = { "Test Web Application_11", "Test Web Application_12" },
  enabled = true,
  auth_token = "ABCD1111",
  cloud_transport_type = "WS",
  hybrid_app_preference = "MOBILE",
  endpoint = "ws://127.0.0.1:8080/",
  keep_context = false,
  steal_focus = false,
  priority = "NONE",
  default_hmi = "NONE",
  groups = { "Base-4" }
}

local appPropPTUExpect = {
  nicknames = appPropPTU.nicknames,
  policyAppID = "0000002",
  enabled = appPropPTU.enabled,
  authToken = appPropPTU.auth_token,
  transportType =  appPropPTU.cloud_transport_type,
  hybridAppPreference = appPropPTU.hybrid_app_preference,
  endpoint = appPropPTU.endpoint
}

local appPropMobile = {
  properties = {
    nicknames = { "Test Web Application_21", "Test Web Application_22" },
    appID = "0000002",
    enabled = true,
    authToken = "ABCD2222",
    cloudTransportType = "WSS",
    hybridAppPreference = "BOTH",
    endpoint = "ws://127.0.0.1:8080/"
  }
}

local appPropMobileExpect = {
  nicknames = appPropMobile.properties.nicknames,
  policyAppID = appPropMobile.properties.appID,
  enabled = appPropMobile.properties.enabled,
  authToken = appPropMobile.properties.authToken,
  transportType = appPropMobile.properties.cloudTransportType,
  hybridAppPreference = appPropMobile.properties.hybridAppPreference,
  endpoint = appPropMobile.properties.endpoint
}

local appPropHMI = {
  nicknames = { "Test Web Application_31", "Test Web Application_32" },
  policyAppID = "0000002",
  enabled = true,
  authToken = "ABCD3333",
  transportType = "WS",
  hybridAppPreference = "CLOUD",
  endpoint = "ws://127.0.0.1:8080/"
}

--[[ Local Variables ]]
local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = appPropPTU;
end

local function onAppPropertiesChangePTU()
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
  common.onAppPropertiesChange(appPropPTUExpect)
end

local function onAppPropertiesChangeMobile()
  common.processRPCSuccess(1, "SetCloudAppProperties", appPropMobile)
  common.onAppPropertiesChange(appPropMobileExpect)
end

local function onAppPropertiesChangeHMI(pData)
  common.setAppProperties(pData)
  common.onAppPropertiesChange(pData)
end

local function updatePreloadedPT()
  local pt = common.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = common.null
  pt.policy_table.functional_groupings["Base-4"].rpcs.SetCloudAppProperties = {
    hmi_levels = { "FULL", "NONE", "LIMITED", "BACKGROUND" }
  }
  common.setPreloadedPT(pt)
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Back-up/update PPT", updatePreloadedPT)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
common.Step("RAI", common.registerApp)

common.Title("Test")
common.Step("App activation", common.activateApp)
common.Step("OnAppPropertiesChange notification: on PTU", common.policyTableUpdate,
  { PTUfunc, onAppPropertiesChangePTU })
common.Step("OnAppPropertiesChange notification: on MobileApp", onAppPropertiesChangeMobile )
common.Step("OnAppPropertiesChange notification: on HMI", onAppPropertiesChangeHMI, { appPropHMI, appPropHMI })

common.Step("Stop SDL", common.postconditions)
