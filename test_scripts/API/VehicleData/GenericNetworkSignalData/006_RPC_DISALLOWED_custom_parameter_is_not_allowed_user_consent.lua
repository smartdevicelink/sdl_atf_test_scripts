---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Policy prohibition for VehicleDataItems in case VD is not allowed by policies

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains VehicleDataItems with custom VD items
-- 4. Custom VD is not allowed( VD is not included in 'parameters' of functional group )

-- Sequence:
-- 1. SubscribeVD/GetVD/UnsubscribeVD with custom VD is requested from mobile app
--   a. SDL responds with DISALLOWED resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId = 1
local definedInParameters = { "gps", "custom_vd_item1_integer" }
local notDefinedInParameters = { "rpm", "custom_vd_item2_float" }
local disallowedCode = "DISALLOWED"

--[[ Local Functions ]]
function common.ptuFuncWithCustomData(pTbl)
  pTbl.policy_table.vehicle_data = { }
  pTbl.policy_table.vehicle_data.schema_items = common.customDataTypeSample
  pTbl.policy_table.vehicle_data.schema_version = "00.00.02"
  pTbl.policy_table.functional_groupings.NewTestCaseGroup = common.cloneTable(
    pTbl.policy_table.functional_groupings["Emergency-1"])

  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.GetVehicleData.parameters = definedInParameters
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.OnVehicleData.parameters = definedInParameters
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.SubscribeVehicleData.parameters = definedInParameters
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.UnsubscribeVehicleData.parameters = definedInParameters
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.user_consent_prompt = "NewTestCaseGroup"
  pTbl.policy_table.app_policies[common.getConfigAppParams(appSessionId).fullAppID].groups = {
    "Base-4", "NewTestCaseGroup" }
end

local function processingAllowedAndDisallowedData()
  local mobRequestData = {
    gps = true,
    custom_vd_item1_integer = true,
    rpm = true,
    custom_vd_item2_float = true
  }

  local hmiRequestData = {
    gps = true,
    [common.VehicleDataItemsWithData.custom_vd_item1_integer.key] = true
  }

  local hmiResponseDataGps, mobileResponseDataGps = common.getVehicleDataResponse("gps")
  local hmiResponseDatacustom_vd_item1_integer, mobileResponseDatacustom_vd_item1_integer = common.getVehicleDataResponse("custom_vd_item1_integer")

  local hmiResponseData = {
    gps = hmiResponseDataGps.gps,
    [common.VehicleDataItemsWithData.custom_vd_item1_integer.key] = hmiResponseDatacustom_vd_item1_integer[common.VehicleDataItemsWithData.custom_vd_item1_integer.key]
  }

  local MobResp = {
    gps = mobileResponseDataGps.gps,
    [common.VehicleDataItemsWithData.custom_vd_item1_integer.name] = mobileResponseDatacustom_vd_item1_integer[common.VehicleDataItemsWithData.custom_vd_item1_integer.name]
  }

  local cid = common.getMobileSession():SendRPC("GetVehicleData", mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)
  :ValidIf(function(_,data)
    if data.params.rpm or
      data.params[common.VehicleDataItemsWithData.custom_vd_item2_float.key] then
      return false, "VI.GetVehicleData request contains unexpected params rpm or " ..
      common.VehicleDataItemsWithData.custom_vd_item2_float.key .. ".\n" ..
      "Received parameters are \n" .. common.printTable(data.params)
    end
    return true
  end)

  MobResp.success = true
  MobResp.resultCode = "SUCCESS"
  MobResp.info = "'custom_vd_item2_float', 'rpm' disallowed by policies."
  common.getMobileSession():ExpectResponse(cid, MobResp)
  :ValidIf(function(_, data)
    if data.payload.rpm or
      data.payload.custom_vd_item2_float then
      return false, "GetVehicleData response contains unexpected params rpm or " ..
      common.VehicleDataItemsWithData.custom_vd_item2_float.name .. ".\n" ..
      "Received parameters are \n" .. common.printTable(data.params)
    end
    return true
  end)
end

local function processingUserNotAllowedAndDisallowedData()
  local mobRequestData = {
    gps = true,
    custom_vd_item1_integer = true,
    rpm = true,
    custom_vd_item2_float = true
  }
  local cid = common.getMobileSession():SendRPC("GetVehicleData", mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData")
  :Times(0)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "USER_DISALLOWED" })
end

local function onPermissionChangeValidationUserDisallowed(pPermissionItem, pGroupParams)
  local checkedRPCs = { "GetVehicleData", "OnVehicleData", "SubscribeVehicleData", "UnsubscribeVehicleData" }
  local hmiLevels = { "BACKGROUND", "FULL", "LIMITED" }
  local msg = ""
  local isError = false
  for _, value in pairs(pPermissionItem) do
    for _, RPCname in pairs(checkedRPCs) do
      if value.rpcName == RPCname then
        local function expectedItem(pExpValue)
          local out = {
            allowed = common.EMPTY_ARRAY,
            userDisallowed = pExpValue
          }
          return out
        end
        if true ~= common:is_table_equal(pGroupParams, value.parameterPermissions.userDisallowed) or
          true ~= common:is_table_equal(common.EMPTY_ARRAY, value.parameterPermissions.allowed)then
          msg = msg .. "OnPermissionCnage notification contains not actual parameterPermissions for " .. RPCname ..
          " :\n" ..
          "Expected table:\n" .. common.tableToString(expectedItem(pGroupParams)) .. " \n" ..
          "Actual table:\n" .. common.tableToString(value.parameterPermissions) .. "\n"
          isError = true
        end
        if true ~= common:is_table_equal(hmiLevels, value.hmiPermissions.userDisallowed) or
          true ~= common:is_table_equal(common.EMPTY_ARRAY, value.hmiPermissions.allowed)then
          msg = msg .. "OnPermissionCnage notification contains not actual hmiPermissions for " .. RPCname ..
          " :\n" ..
          "Expected table:\n" .. common.tableToString(expectedItem(hmiLevels)) .. " \n" ..
          "Actual table:\n" .. common.tableToString(value.hmiPermissions) .. " \n"
          isError = true
        end
      end
    end
  end
  if isError == true then
    return false, msg
  end
  return true
end

local function userConsent(isConsent)
  local RequestIdGetListOfPermissions = common.getHMIConnection():SendRequest("SDL.GetListOfPermissions",
    {appID = common.getHMIAppId()})
  EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions)
  :Do(function(_,data)
    common.getHMIConnection():SendNotification("SDL.OnAppPermissionConsent",
    {
      appID = common.getHMIAppId(),
      consentedFunctions = {
        { allowed = isConsent, id = data.result.allowedFunctions[1].id, name = "NewTestCaseGroup" }
      },
      source = "GUI"
    })
  end)
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_, data)
      if isConsent == false then
        return onPermissionChangeValidationUserDisallowed(data.payload.permissionItem, definedInParameters)
      end
      return common.onPermissionChangeValidation(data.payload.permissionItem, definedInParameters)
    end)
end

local function policyTableUpdateWithOnPermChange()
  common.policyTableUpdate(common.ptuFuncWithCustomData)
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_, data)
      return onPermissionChangeValidationUserDisallowed(data.payload.permissionItem, definedInParameters)
    end)
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, { false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("PTU with VehicleDataItems", policyTableUpdateWithOnPermChange)
runner.Step("User consent false", userConsent, { false })

for _, vehicleDataName in pairs(definedInParameters) do
  runner.Step("SubscribeVehicleData " .. vehicleDataName .. " USER_DISALLOWED", common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "SubscribeVehicleData", "USER_DISALLOWED" })
  runner.Step("GetVehicleData " .. vehicleDataName .. " USER_DISALLOWED", common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "GetVehicleData", "USER_DISALLOWED" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
  runner.Step("UnsubscribeVehicleData " .. vehicleDataName .. " USER_DISALLOWED", common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "UnsubscribeVehicleData", "USER_DISALLOWED" })
end

for _, vehicleDataName in pairs(notDefinedInParameters) do
  runner.Step("SubscribeVehicleData " .. vehicleDataName .. " USER_DISALLOWED", common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "SubscribeVehicleData", "USER_DISALLOWED" })
  runner.Step("GetVehicleData " .. vehicleDataName .. " USER_DISALLOWED", common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "GetVehicleData", "USER_DISALLOWED" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
  runner.Step("UnsubscribeVehicleData " .. vehicleDataName .. " USER_DISALLOWED", common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "UnsubscribeVehicleData", "USER_DISALLOWED" })
end

runner.Step("GetVehicleData with not allowed by user and disallowed VD", processingUserNotAllowedAndDisallowedData)

runner.Step("User consent true", userConsent, { true })

for _,vehicleDataName in pairs(definedInParameters) do
  runner.Step("SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName })
  runner.Step("GetVehicleData " .. vehicleDataName, common.GetVD,
    { appSessionId, vehicleDataName })
  runner.Step("UnsubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "UnsubscribeVehicleData" })
end

for _, vehicleDataName in pairs(notDefinedInParameters) do
  runner.Step("SubscribeVehicleData " .. vehicleDataName .. " " .. disallowedCode, common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "SubscribeVehicleData", disallowedCode })
  runner.Step("GetVehicleData " .. vehicleDataName .. " " .. disallowedCode, common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "GetVehicleData", disallowedCode })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
  runner.Step("UnsubscribeVehicleData " .. vehicleDataName .. " " .. disallowedCode, common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "UnsubscribeVehicleData", disallowedCode })
end

runner.Step("GetVehicleData with allowed and not allowed VD", processingAllowedAndDisallowedData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
