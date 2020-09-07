---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/3164
--
-- Description: Check the successful merge of empty module data with existing data in cache
--
-- Precondition:
-- 1. SDL Core and HMI are started
-- 2. RC app is registered and activated
-- 3. PTU with permission for RC is performed
-- 4. App is subscribed to <moduleType>

-- Steps:
-- 1. HMI sends OnInteriorVehicleData notification with empty control data for <moduleType>
-- SDL does:
-- - a. merge received data with existing data in cache
-- - b. send OnInteriorVehicleData notification with data received from HMI to mobile app
-- 2. Mobile app requests GetInteriorVehicleData(<moduleType>)
-- SDL does:
-- - a. respond to GetInteriorVehicleData with initial data from cache
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
local isSubscriptionNotCached = false
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

local function onInteriorVehicleData(pModuleData)
  local rpc = "OnInteriorVehicleData"
  common.hmi.getConnection():SendNotification(rc.rpc.getHMIEventName(rpc), { moduleData = pModuleData })
  common.mobile.getSession(appId):ExpectNotification(rc.rpc.getAppEventName(rpc), { moduleData = pModuleData })
end

local function getInteriorVehicleData(pModuleType)
  local rpc = "GetInteriorVehicleData"
  local mobSession = common.mobile.getSession(appId)
  local moduleId = getModuleId(pModuleType)
  local cid = mobSession:SendRPC(rc.rpc.getAppEventName(rpc),
    rc.rpc.getAppRequestParams(rpc, pModuleType, moduleId))
  mobSession:ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    moduleData = rc.state.getActualModuleIVData(pModuleType, moduleId)
  })
end

--[[Scenario]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", rc.rc.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("PTU with permission for RC", rc.rc.policyTableUpdate)
for _, value in pairs (moduleData) do
  runner.Step("Subscribe to moduleType " .. value.moduleType, rc.rc.subscribeToModule,
    { value.moduleType, getModuleId(value.moduleType), appId, isSubscriptionNotCached })
end

runner.Title("Test")
for caseName, value in pairs(moduleData) do
  runner.Step("OnInteriorVehicleData " .. caseName, onInteriorVehicleData, { value })
  runner.Step("GetInteriorVehicleData without changes " .. caseName, getInteriorVehicleData, { value.moduleType })
end

runner.Title("Postconditions")
