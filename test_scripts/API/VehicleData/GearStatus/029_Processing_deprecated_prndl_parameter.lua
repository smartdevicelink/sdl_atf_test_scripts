---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: Processing of deprecated parameter 'prndl'.
--
-- In case:
-- 1) App is registered with version is equal to/greater than/less than parameter version
-- 2) The parameter `prndl` is deprecated since=6.2 in API and DB.
-- 3) App requests Get/Sub/UnsubscribeVehicleData with prndl=true.
-- 4) HMI sends valid OnVehicleData notification with prndl=<value since=2.0>
-- SDL does:
--  a) process the requests successful
--  b) process the OnVehicleData notification and transfer it to mobile app
-- 5) App is registered with version less than version of parameter value
-- 6) App requests GetVehicleData(prndl)
-- SDL does:
--  a) send this request to HMI.
-- 7) HMI responds with prndl=<value since=6.2>
-- SDL does:
--  a) process this value as invalid
--  b) sends response GetVehicleData(success:false, resultCode:`GENERIC_ERROR`) to mobile app
-- 8) HMI sends a OnVehicleData notification with prndl=<value since=6.2>.
-- SDL does:
--  a) ignore this notification.
--  b) not send OnVehicleData notification to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

-- [[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"

local appId1 = 1
local isExpectedSubscribeVDonHMI = true
local expected = 1
local notExpected = 0

local appVersions = {
  lessThanParamVersion = { major = 5, minor = 0 },
  greaterThanParamVersion = { major = 7, minor = 0 },
  equalToParamVersion =  { major = 6, minor = 2 }
}

local parameterName = "prndl"
local prndlSince62 = "NINTH"
local prndlSince20 = "PARK"

-- [[ Local Functions ]]
local function setAppVersion(pMajor, pMinor)
  common.getAppParams().syncMsgVersion.majorVersion = pMajor
  common.getAppParams().syncMsgVersion.minorVersion = pMinor
end

local function invalidDataFromHMIWithPRNDLparam(pData)
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { prndl = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { prndl = true })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { prndl = pData })
  end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

common.Title("Test")
common.Title("Version of prndl value is since=2.0")
for caseName, value in common.spairs(appVersions) do
  common.Step("Set app version " .. caseName, setAppVersion, { value.major, value.minor })
  common.Step("Register App" .. caseName, common.registerApp)
  common.Step("GetVehicleData for prndl" .. caseName, common.getVehicleData, { prndlSince20, parameterName })
  common.Step("App subscribes to prndl data" .. caseName, common.processSubscriptionRPC,
    { rpc_sub, appId1, isExpectedSubscribeVDonHMI, parameterName })
  common.Step("OnVehicleData with prndl data" .. caseName, common.sendOnVehicleData,
    { prndlSince20, expected, parameterName })
  common.Step("App unsubscribes from prndl data" .. caseName, common.processSubscriptionRPC,
    { rpc_unsub, appId1, isExpectedSubscribeVDonHMI, parameterName })
  common.Step("Unregistration App" .. caseName, common.appUnregistration)
end

common.Title("Version of prndl value is since=6.2")
common.Step("Set app version less than version of parameter value", setAppVersion,
  { appVersions.lessThanParamVersion.major, appVersions.lessThanParamVersion.minor })
common.Step("Register App less than version of parameter value", common.registerApp)
common.Step("GetVehicleData less than version of parameter value", invalidDataFromHMIWithPRNDLparam, { prndlSince62 })
common.Step("App subscribes less than version of parameter value", common.processSubscriptionRPC,
  { rpc_sub, appId1, isExpectedSubscribeVDonHMI, parameterName })
common.Step("OnVehicleData less than version of parameter value", common.sendOnVehicleData,
  { prndlSince62, notExpected, parameterName })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
