---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Resumption of subscription for custom and RPC spec VehicleData for one
--   after unexpected disconnect

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed, the update contains VehicleDataItems with custom VD in update file
-- 5. SDL is subscribed for custom VD
-- 6. Transport reconnection is performed

-- Sequence:
-- 1. Mobile app registers with actual hashID
--   a. SDL starts data resumption
-- 2. SDL resumes subscription for custom VD and sends VI.SubscribeVD request to HMI
--   a. HMI responds with success resultCode
-- 3. After success response from HMI SDL resumes the subscription
-- 4. HMI sends OnVD notification with custom VD
--   a. SDL resends OnVD notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId = 1

--[[ Local Functions ]]
local function registerApp()
  common.getConfigAppParams().hashID = common.hashId
  common.getMobileSession():StartService(7)
  :Do(function()
      local corId = common.getMobileSession():SendRPC("RegisterAppInterface", common.getConfigAppParams(1))
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams(1).appName } })

      local hmiRequestData = {
        gps = true,
        [common.VehicleDataItemsWithData.custom_vd_item1_integer.key] = true
      }

      local hmiResponseData = {
        [common.VehicleDataItemsWithData.custom_vd_item1_integer.key] = {
          dataType = common.CUSTOM_DATA_TYPE, resultCode = "SUCCESS"
        },
        gps = { dataType = common.VehicleDataItemsWithData.gps.APItype, resultCode = "SUCCESS" }
      }

      common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", hmiRequestData)
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
        end)

      common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)

      common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession():ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
            { hmiLevel = "FULL", systemContext = "MAIN" })
          :Times(2)
          common.getMobileSession():ExpectNotification("OnPermissionsChange")
        end)
    end)

end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })
runner.Step("SubscribeVehicleData custom_vd_item1_integer", common.VDsubscription,
  { appSessionId, "custom_vd_item1_integer", "SubscribeVehicleData" })
runner.Step("SubscribeVehicleData gps", common.VDsubscription, { appSessionId, "gps", "SubscribeVehicleData" })
runner.Step("OnVehicleData custom_vd_item1_integer", common.onVD, { appSessionId, "custom_vd_item1_integer" })
runner.Step("OnVehicleData gps", common.onVD, { appSessionId, "gps" })

runner.Title("Test")
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("App registration", registerApp)
runner.Step("OnVehicleData custom_vd_item1_integer", common.onVD, { appSessionId, "custom_vd_item1_integer" })
runner.Step("OnVehicleData gps", common.onVD, { appSessionId, "gps" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
