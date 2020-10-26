---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/3164
--
-- Description: Check the successful merge of empty module data existed in cache with new data
--  from OnInteriorVehicleData
--
-- Precondition:
-- 1. SDL Core and HMI are started
-- 2. RC app is registered and activated
-- 3. PTU with permission for RC is performed

-- Steps:
-- 1. Mobile app requests subscription for <moduleType> via GetInteriorVehicleData RPC
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(<moduleType>) to HMI
-- 2.  HMI responds with empty moduleData to RC.GetInteriorVehicleData(<moduleType>)
-- SDL does:
-- - a. save received moduleData from HMI in cache
-- - b. resend GetInteriorVehicleData response to mobile app
-- 3. HMI sends OnInteriorVehicleData with updated moduleData for <moduleType>
-- SDL does:
-- - a. merge empty module data from cache with new data from OnInteriorVehicleData
-- - b. resend OnInteriorVehicleData notification with received data from HMI to mobile app
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local rc = require('user_modules/sequences/remote_control')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

-- [[ Local Variables ]]
local appId = 1
local isSubscribe = true
local withoutSubscription = nil
local isCached = true
local moduleData = {
  emptyRadioData = { moduleType = "RADIO", radioControlData = {}},
  emptyAudioData = { moduleType = "AUDIO", audioControlData = {}},
  emptyHmiSettingsData = { moduleType = "HMI_SETTINGS", hmiSettingsControlData = {}},
  emptyClimateData = { moduleType = "CLIMATE", climateControlData = {}},
  emptySeatData = { moduleType = "SEAT", seatControlData = {}},
}

-- [[ Local Functions ]]
local function getModuleId(pModuleType)
  return rc.predefined.getModuleControlData(pModuleType, 1).moduleId
end

local function getInteriorVehicleData(pModuleData, pIsSubscribe, pIsCached)
  local rpc = "GetInteriorVehicleData"
  local mobSession = common.mobile.getSession(appId)
  local hmi = common.hmi.getConnection()
  local moduleId = getModuleId(pModuleData.moduleType)
  pModuleData.moduleId = moduleId
  local resData = { moduleData = pModuleData, isSubscribed = pIsSubscribe }
  local cid = mobSession:SendRPC(rc.rpc.getAppEventName(rpc),
      rc.rpc.getAppRequestParams(rpc, pModuleData.moduleType, moduleId, pIsSubscribe))
  if pIsCached ~= true then
    hmi:ExpectRequest(rc.rpc.getHMIEventName(rpc),
        rc.rpc.getHMIRequestParams(rpc, pModuleData.moduleType, moduleId, appId, pIsSubscribe))
    :Do(function(_, data)
        hmi:SendResponse(data.id, data.method, "SUCCESS", resData)
      end)
  end
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", table.unpack(resData) })
end

local function getActualModuleData(pModuleType)
  return rc.state.getActualModuleIVData(pModuleType, getModuleId(pModuleType))
end

local function onInteriorVehicleData(pModuleType)
  local actualModuleData = getActualModuleData(pModuleType)
  rc.rc.checkSubscription(pModuleType, getModuleId(pModuleType), appId, isCached, actualModuleData )
end

--[[Scenario]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", rc.rc.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("PTU with permission for RC", rc.rc.policyTableUpdate)

runner.Title("Test")
for caseName, value in pairs(moduleData) do
  runner.Step("Subscribe to moduleType " .. value.moduleType, getInteriorVehicleData, { value, isSubscribe })
  runner.Step("OnInteriorVehicleData with updated data " .. caseName, onInteriorVehicleData,
    { value.moduleType })
  runner.Step("GetInteriorVehicleData after subscription " .. caseName, getInteriorVehicleData,
    { getActualModuleData(value.moduleType), withoutSubscription, isCached })
end

runner.Title("Postconditions")
