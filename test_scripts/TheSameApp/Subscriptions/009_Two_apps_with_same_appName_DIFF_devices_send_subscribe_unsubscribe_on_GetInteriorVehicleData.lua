---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- Two mobile applications with the same appNames and different appIds from different mobiles send
-- GetInteriorVehicleData(RADIO and CLIMATE modules) requests and receive OnInteriorVehicleData notifications.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobiles №1 and №2 are connected to SDL
-- 3) Mobile №1 App1 is already Subscribed on GetInteriorVehicleData (RADIO, CLIMATE modules)
-- 4) Mobile №2 App2 is already Subscribed on GetInteriorVehicleData (RADIO, CLIMATE modules)
--
-- Steps:
-- 1) Mobile №1 App1 requested Unsubscribe from GetInteriorVehicleData("RADIO" module, subscribe = false)
--   Check:
--    SDL sends GetInteriorVehicleData("SUCCESS") response to Mobile №1
-- 2) HMI sent RC.OnInteriorVehicleData("RADIO") notification
--   Check:
--    SDL does NOT send OnInteriorVehicleData notification to Mobile №1
--    SDL sends OnInteriorVehicleData("RADIO") notification to Mobile №2
-- 3) Mobile №2 App2 requested Unsubscribe from GetInteriorVehicleData("CLIMATE" module, subscribe = false)
--   Check:
--    SDL sends GetInteriorVehicleData("SUCCESS") response to Mobile №2
-- 4) HMI sent RC.OnInteriorVehicleData("CLIMATE") notification
--   Check:
--    SDL does NOT send OnInteriorVehicleData notification to Mobile №1
--    SDL sends OnInteriorVehicleData("CLIMATE") notification to Mobile №2
-- 5) Mobile №1 App1 requested Unsubscribe from GetInteriorVehicleData("CLIMATE" module, subscribe = false)
--   Check:
--    SDL sends RC.GetInteriorVehicleData(appId_1, "CLIMATE" module,  subscribe = false) to HMI--
--    SDL receives RC.GetInteriorVehicleData (SUCCESS) response from HMI
--    SDL sends GetInteriorVehicleData("SUCCESS") response Mobile №1
-- 6) HMI sent RC.OnInteriorVehicleData("CLIMATE") notification
--   Check:
--    SDL does NOT send OnInteriorVehicleData notifications to Mobile №1 and №2
-- 7) Mobile №2 App2 requested Unsubscribe from GetInteriorVehicleData("RADIO" module, subscribe = false)
--   Check:
--    SDL sends RC.GetInteriorVehicleData(appId_2, "RADIO" module,  subscribe = false) to HMI
--    SDL receives RC.GetInteriorVehicleData (SUCCESS) response from HMI
--    SDL sends GetInteriorVehicleData("SUCCESS") response to Mobile №2
-- 8) HMI sent RC.OnInteriorVehicleData("RADIO") notification
--   Check:
--    SDL does NOT send OnInteriorVehicleData notifications to Mobile №1 and №2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = { appName = "Test Application", appID = "0001",  fullAppID = "0000001",  appHMIType = { "REMOTE_CONTROL" } },
  [2] = { appName = "Test Application", appID = "00022", fullAppID = "00000022", appHMIType = { "REMOTE_CONTROL" } }
}

local pReqPayload = {
  [1] = { moduleData = { moduleType = "RADIO" },   isSubscribed = true },
  [2] = { moduleData = { moduleType = "CLIMATE" }, isSubscribed = true }
}
local pReqPayloadNeg = {
  [1] = { moduleData = { moduleType = "RADIO" },   isSubscribed = false },
  [2] = { moduleData = { moduleType = "CLIMATE" }, isSubscribed = false }
}
local pRspPayload = {
  [1] = { moduleData = { moduleType = "RADIO" },   isSubscribed = true, success = true, resultCode = "SUCCESS" },
  [2] = { moduleData = { moduleType = "CLIMATE" }, isSubscribed = true, success = true, resultCode = "SUCCESS" }
}
local pRspPayloadNeg = {
  [1] = { moduleData = { moduleType = "RADIO" },   isSubscribed = false, success = true, resultCode = "SUCCESS" },
  [2] = { moduleData = { moduleType = "CLIMATE" }, isSubscribed = false, success = true, resultCode = "SUCCESS" }
}

local pNotificationPayload = {
  [1] = { moduleData = { moduleType = "RADIO", radioControlData = { radioEnable = true }}},
  [2] = { moduleData = { moduleType = "CLIMATE", climateControlData = { fanSpeed = 50 }}}
}

--[[ Local Functions ]]
local function modifyWayPointGroupInPT(pt)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null

  pt.policy_table.app_policies[appParams[1].fullAppID] = common.cloneTable(pt.policy_table.app_policies["default"])
  pt.policy_table.app_policies[appParams[1].fullAppID].groups     = { "Base-4", "RemoteControl" }
  pt.policy_table.app_policies[appParams[1].fullAppID].moduleType = { "RADIO", "CLIMATE" }
  pt.policy_table.app_policies[appParams[1].fullAppID].appHMIType = { "REMOTE_CONTROL" }
  pt.policy_table.app_policies[appParams[2].fullAppID] = common.cloneTable(pt.policy_table.app_policies["default"])
  pt.policy_table.app_policies[appParams[2].fullAppID].groups     = { "Base-4", "RemoteControl" }
  pt.policy_table.app_policies[appParams[2].fullAppID].moduleType = { "RADIO", "CLIMATE" }
  pt.policy_table.app_policies[appParams[2].fullAppID].appHMIType = { "REMOTE_CONTROL" }
end

local function unsubscribeVehicleData(pAppId, pModuleType, pSubscribe, pIsLastApp)
  local pPayload
  if     pModuleType == "RADIO"   then pPayload = 1
  elseif pModuleType == "CLIMATE" then pPayload = 2
  end

  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("GetInteriorVehicleData", { moduleType = pModuleType, subscribe = pSubscribe })
  -- SDL -> HMI - should send this request only when 1st app get subscribed
  if pIsLastApp then
    common.hmi.getConnection():ExpectRequest("RC.GetInteriorVehicleData",
        { moduleType = pModuleType, subscribe = pSubscribe})
    :Do(function(_,data)
        pReqPayloadNeg[pPayload].moduleData.moduleId = data.params.moduleId
        common.hmi.getConnection():SendResponse( data.id, data.method, "SUCCESS", pReqPayloadNeg[pPayload] )
      end)
  end
    mobSession:ExpectResponse( cid, pRspPayloadNeg[pPayload] )
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modifyWayPointGroupInPT})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, { 1, appParams[1], 1 })
runner.Step("Register App2 from device 2", common.registerAppEx, { 2, appParams[2], 2 })
runner.Step("Activate App 1", common.app.activate, { 1 })
runner.Step("App1 from Mobile 1 subscribes for RADIO",   common.getInteriorVehicleData,
    { 1, "RADIO",   true, "1st_app", pReqPayload, pRspPayload })
runner.Step("App1 from Mobile 1 subscribes for CLIMATE", common.getInteriorVehicleData,
    { 1, "CLIMATE", true, "1st_app", pReqPayload, pRspPayload })
runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("App2 from Mobile 2 subscribes for RADIO",   common.getInteriorVehicleData,
    { 2, "RADIO",   true, nil, pReqPayload, pRspPayload })
runner.Step("App2 from Mobile 2 subscribes for CLIMATE", common.getInteriorVehicleData,
    { 2, "CLIMATE", true, nil, pReqPayload, pRspPayload })

runner.Title("Test")
runner.Step("HMI sends RADIO VehicleData - App 2 receive",    common.onInteriorVehicleData,
    { 2, 1, 2, "RADIO", pNotificationPayload })
runner.Step("App1 from Mobile 1 unsubscribes from RADIO",    unsubscribeVehicleData, { 1, "RADIO", false })
runner.Step("HMI sends RADIO VehicleData - App 2 receive",    common.onInteriorVehicleData,
    { 2, 1, 1, "RADIO", pNotificationPayload })

runner.Step("App2 from Mobile 2 unsubscribes from CLIMATE",  unsubscribeVehicleData, { 2, "CLIMATE", false })
runner.Step("HMI sends CLIMATE VehicleData - App 1 receive",  common.onInteriorVehicleData,
    { 1, 2, 1, "CLIMATE", pNotificationPayload })

runner.Step("App1 from Mobile 1 unsubscribes from CLIMATE",  unsubscribeVehicleData, { 1, "CLIMATE", false, "last_app"})
runner.Step("HMI sends CLIMATE VehicleData - NOONE receives", common.onInteriorVehicleData,
    { 1, 2, 0, "CLIMATE", pNotificationPayload })

runner.Step("App2 from Mobile 2 unsubscribes from RADIO",    unsubscribeVehicleData, { 2, "RADIO",   false, "last_app"})
runner.Step("HMI sends RADIO VehicleData - NOONE receives",   common.onInteriorVehicleData,
    { 2, 1, 0, "RADIO", pNotificationPayload })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
