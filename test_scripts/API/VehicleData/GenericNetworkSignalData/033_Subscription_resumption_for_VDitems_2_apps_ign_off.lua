---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Resumption of subscription for custom and RPC spec VehicleData for several apps

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. 2 apps are registered
-- 4. PTU is performed, the update contains VehicleDataItems with custom VD in update file
-- 5. App1 is subscribed to gps, custom_vd_item1_integer
-- 6. App2 is subscribed to gps, custom_vd_item2_float, rpm
-- 7. IGN_OFF-IGN_ON is performed

-- Sequence:
-- 1. Mobile app1 and app2 register with actual hashID
--   a. SDL starts data resumption for both apps
-- 2. SDL resumes the subscription and sends VI.SubscribeVD request to HMI
--   a. HMI responds with success resultCode
-- 3. After success response from HMI SDL resumes the subscription
-- 4. HMI sends OnVD notification with subscribed VD
--   a. SDL resends OnVD notification to appropriate mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionIdForApp1 = 1
local appSessionIdForApp2 = 2
local hashIDs = { }

--[[ Local Functions ]]
local function startServices(pAppId)
  common.getMobileSession(pAppId):StartService(7)
end

local function registerApps()
  common.getConfigAppParams(appSessionIdForApp1).hashID = hashIDs[appSessionIdForApp1]
  common.getConfigAppParams(appSessionIdForApp2).hashID = hashIDs[appSessionIdForApp2]

  local corId1 = common.getMobileSession(appSessionIdForApp1):SendRPC("RegisterAppInterface",
    common.getConfigAppParams(appSessionIdForApp1))
  local corId2 = common.getMobileSession(appSessionIdForApp2):SendRPC("RegisterAppInterface",
    common.getConfigAppParams(appSessionIdForApp2))

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
    { application = { appName = common.getConfigAppParams(appSessionIdForApp1).appName } },
    { application = { appName = common.getConfigAppParams(appSessionIdForApp2).appName } })
    :Do(function(exp, d1)
        if exp.occurences == 1 then
          common.setHMIAppId(d1.params.application.appID, appSessionIdForApp1)
        else
          common.setHMIAppId(d1.params.application.appID, appSessionIdForApp2)
        end
      end)
    :Times(2)

  common.getMobileSession(appSessionIdForApp1):ExpectResponse(corId1, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      common.getMobileSession(appSessionIdForApp1):ExpectNotification("OnHMIStatus",
        { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      common.getMobileSession(appSessionIdForApp1):ExpectNotification("OnPermissionsChange")
    end)

  common.getMobileSession(appSessionIdForApp2):ExpectResponse(corId2, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      common.getMobileSession(appSessionIdForApp2):ExpectNotification("OnHMIStatus",
        { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
        { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
      :Times(2)
      common.getMobileSession(appSessionIdForApp2):ExpectNotification("OnPermissionsChange")
    end)

  local hmiRequestDataApp1 = {
    gps = true,
    [common.VehicleDataItemsWithData.custom_vd_item1_integer.key] = true
  }

  local hmiRequestDataApp2 = {
    rpm = true,
    [common.VehicleDataItemsWithData.custom_vd_item2_float.key] = true
  }

  local hmiResponseDataApp1 = {
    [common.VehicleDataItemsWithData.custom_vd_item1_integer.key] =
        { dataType = common.CUSTOM_DATA_TYPE, resultCode = "SUCCESS" },
    gps = { dataType = common.VehicleDataItemsWithData.gps.APItype, resultCode = "SUCCESS" }
  }

  local hmiResponseDataApp2 = {
    [common.VehicleDataItemsWithData.custom_vd_item2_float.key] =
        { dataType = common.CUSTOM_DATA_TYPE, resultCode = "SUCCESS" },
    rpm = { dataType = common.VehicleDataItemsWithData.rpm.APItype, resultCode = "SUCCESS" }
  }

  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData",
    hmiRequestDataApp1,
    hmiRequestDataApp2)
  :Do(function(exp, data)
      if exp.occurences == 1 then
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseDataApp1)
      else
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseDataApp2)
      end
    end)
  :Times(2)

  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

local function saveHashId(pAppId)
  hashIDs[pAppId] = common.hashId
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set ApplicationListUpdateTimeout=4000", common.setSDLIniParameter,
  { "ApplicationListUpdateTimeout", 4000 })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 registration", common.registerAppWOPTU)
runner.Step("App2 registration", common.registerAppWOPTU, { appSessionIdForApp2 })
runner.Step("App1 activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.ptuWithPolicyUpdateReq, { common.ptuFuncWithCustomData2Apps })

runner.Step("App1 SubscribeVehicleData custom_vd_item1_integer", common.VDsubscription,
  { appSessionIdForApp1, "custom_vd_item1_integer", "SubscribeVehicleData" })
runner.Step("App1 SubscribeVehicleData gps", common.VDsubscription,
  { appSessionIdForApp1, "gps", "SubscribeVehicleData" })
runner.Step("Save hashId for App1", saveHashId, { appSessionIdForApp1 })
runner.Step("OnVehicleData custom_vd_item1_integer", common.onVD, { appSessionIdForApp1, "custom_vd_item1_integer" })
runner.Step("OnVehicleData gps", common.onVD, { appSessionIdForApp1, "gps" })
runner.Step("App2 activation", common.activateApp, { appSessionIdForApp2 })
runner.Step("App2 SubscribeVehicleData custom_vd_item2_float", common.VDsubscription,
  { appSessionIdForApp2, "custom_vd_item2_float", "SubscribeVehicleData" })
runner.Step("App2 SubscribeVehicleData rpm", common.VDsubscription,
  { appSessionIdForApp2, "rpm", "SubscribeVehicleData" })
runner.Step("App2 SubscribeVehicleData gps", common.VDsubscriptionWithoutReqOnHMI,
  { appSessionIdForApp2, "gps", "SubscribeVehicleData" })
runner.Step("Save hashId for App2", saveHashId, { appSessionIdForApp2 })
runner.Step("OnVehicleData custom_vd_item2_float", common.onVD, { appSessionIdForApp2, "custom_vd_item2_float" })
runner.Step("OnVehicleData rpm", common.onVD, { appSessionIdForApp2, "rpm" })

runner.Title("Test")
runner.Step("Ignition off", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Start services App1", startServices, { appSessionIdForApp1 })
runner.Step("Start services App2", startServices, { appSessionIdForApp2 })
runner.Step("Apps registration", registerApps)
runner.Step("App2 OnVehicleData custom_vd_item2_float", common.onVD, { appSessionIdForApp2, "custom_vd_item2_float" })
runner.Step("App2 OnVehicleData rpm", common.onVD, { appSessionIdForApp2, "rpm" })
runner.Step("App1 activation", common.activateApp)
runner.Step("App1 OnVehicleData custom_vd_item1_integer", common.onVD, { appSessionIdForApp1, "custom_vd_item1_integer" })
runner.Step("App1 and App2 OnVehicleData gps", common.onVD2Apps, { "gps" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
