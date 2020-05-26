---------------------------------------------------------------------------------------------------
-- VehicleData common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.mobileHost = "127.0.0.1"
config.defaultProtocolVersion = 2
config.ValidateSchema = false
config.zeroOccurrenceTimeout = 1000

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local json = require("modules/json")
local utils = require('user_modules/utils')
local events = require('events')
local test = require("user_modules/dummy_connecttest")
local SDL = require("modules/SDL")

--[[ Local Variables ]]
local common = {}
common.getPolicyAppId = actions.app.getPolicyAppId
common.start = actions.start
common.setSDLIniParameter = actions.setSDLIniParameter
common.activateApp = actions.activateApp
common.registerApp = actions.registerApp
common.getMobileSession = actions.getMobileSession
common.policyTableUpdate = actions.policyTableUpdate
common.getHMIConnection = actions.getHMIConnection
common.setHMIAppId = actions.setHMIAppId
common.getHMIAppId = actions.getHMIAppId
common.getConfigAppParams = actions.getConfigAppParams
common.getAppsCount = actions.getAppsCount
common.registerAppWOPTU = actions.registerAppWOPTU

common.cloneTable = utils.cloneTable
common.printTable = utils.printTable
common.tableToString = utils.tableToString
common.tableToJsonFile = utils.tableToJsonFile
common.jsonFileToTable = utils.jsonFileToTable
common.isFileExist = utils.isFileExist
common.wait = utils.wait

common.GetPathToSDL = commonPreconditions.GetPathToSDL

common.runSDL = test.runSDL
common.FailTestCase = test.FailTestCase

common.DeleteFile = SDL.DeleteFile

common.is_table_equal = commonFunctions.is_table_equal
common.read_parameter_from_smart_device_link_ini = commonFunctions.read_parameter_from_smart_device_link_ini

common.EMPTY_ARRAY = json.EMPTY_ARRAY
common.EMPTY_OBJECT = json.EMPTY_OBJECT
common.null = json.null
common.decode = json.decode

common.isPTUStarted = actions.isPTUStarted
common.getPTS = actions.sdl.getPTS

common.CUSTOM_DATA_TYPE = "VEHICLEDATA_OEM_CUSTOM_DATA"

common.VehicleDataItemsWithData = {}

common.VD = {
  NOT_EXPECTED = 0,
  EXPECTED = 1
}

function common.getPreloadedFileAndContent()
  local preloadedFile = common:GetPathToSDL()
    .. common:read_parameter_from_smart_device_link_ini("PreloadedPT")
  local preloadedTable = common.jsonFileToTable(preloadedFile)
  return preloadedTable, preloadedFile
end

-- Note: Function is assumed that preloaded file contains only RPC spec data,
-- in case the preloaded file will be updated with some custom data the function should be extended to
-- a processing of custom data in the preloaded file
local function VehicleDataItemsWithDataTableCreation()
  local preloadedTable = common.getPreloadedFileAndContent()
  if preloadedTable.policy_table.vehicle_data.schema_items then
    for _, item in pairs (preloadedTable.policy_table.vehicle_data.schema_items) do
      common.VehicleDataItemsWithData[item.name] = common.cloneTable(item)
      local itemStruct = common.VehicleDataItemsWithData[item.name]
      itemStruct.rpcSpecData = true
      if item.type == "Struct" then
      itemStruct.params = {}
        for _, subItem in pairs(item.params) do
          itemStruct.params[subItem.name] = common.cloneTable(subItem)
          local subItemStruct = itemStruct.params[subItem.name]
          if subItem.type == "Struct" then
            subItemStruct.params = {}
            for _, subItem2 in pairs(subItem.params) do
              subItemStruct.params[subItem2.name] = common.cloneTable(subItem2)
            end
          end
        end
      end
    end

    common.VehicleDataItemsWithData.engineTorque.APItype = "VEHICLEDATA_ENGINETORQUE"
    local gpsParams = common.VehicleDataItemsWithData.gps.params
    gpsParams.longitudeDegrees.value = 100
    gpsParams.latitudeDegrees.value = 20.5
    gpsParams.utcYear.value = 2020
    gpsParams.utcMonth.value = 6
    gpsParams.utcDay.value = 3
    gpsParams.utcHours.value = 14
    gpsParams.utcMinutes.value = 4
    gpsParams.utcSeconds.value = 34
    gpsParams.pdop.value = 10
    gpsParams.hdop.value = 100
    gpsParams.vdop.value = 500
    gpsParams.actual.value = false
    gpsParams.compassDirection.value = "WEST"
    gpsParams.dimension.value = "2D"
    gpsParams.satellites.value = 5
    gpsParams.altitude.value = 10
    gpsParams.heading.value = 100.9
    gpsParams.speed.value = 40.5
    common.VehicleDataItemsWithData.gps.APItype = "VEHICLEDATA_GPS"
    common.VehicleDataItemsWithData.speed.value = 30.2
    common.VehicleDataItemsWithData.speed.APItype = "VEHICLEDATA_SPEED"
    common.VehicleDataItemsWithData.rpm.value = 10
    common.VehicleDataItemsWithData.rpm.APItype = "VEHICLEDATA_RPM"
    common.VehicleDataItemsWithData.fuelLevel.value = -3
    common.VehicleDataItemsWithData.fuelLevel.APItype = "VEHICLEDATA_FUELLEVEL"
    common.VehicleDataItemsWithData.fuelLevel_State.value = "NORMAL"
    common.VehicleDataItemsWithData.fuelLevel_State.APItype = "VEHICLEDATA_FUELLEVEL_STATE"
    common.VehicleDataItemsWithData.instantFuelConsumption.value = 1000.1
    common.VehicleDataItemsWithData.instantFuelConsumption.APItype = "VEHICLEDATA_FUELCONSUMPTION"
    common.VehicleDataItemsWithData.fuelRange.value = {
      { type = "GASOLINE" , range = 20 }, { type = "BATTERY", range = 100 }}
    common.VehicleDataItemsWithData.fuelRange.APItype = "VEHICLEDATA_FUELRANGE"
    common.VehicleDataItemsWithData.externalTemperature.value = 24.1
    common.VehicleDataItemsWithData.externalTemperature.APItype = "VEHICLEDATA_EXTERNTEMP"
    common.VehicleDataItemsWithData.turnSignal.value = "OFF"
    common.VehicleDataItemsWithData.turnSignal.APItype = "VEHICLEDATA_TURNSIGNAL"
    common.VehicleDataItemsWithData.vin.value = "SJFHSIGD4058569"
    common.VehicleDataItemsWithData.vin.APItype = "VEHICLEDATA_VIN"
    common.VehicleDataItemsWithData.prndl.value = "PARK"
    common.VehicleDataItemsWithData.prndl.APItype = "VEHICLEDATA_PRNDL"
    local tirePressureParams = common.VehicleDataItemsWithData.tirePressure.params
    tirePressureParams.pressureTelltale.value = "OFF"
    local leftFrontParams = tirePressureParams.leftFront.params
    leftFrontParams.status.value = "NORMAL"
    leftFrontParams.tpms.value = "UNKNOWN"
    leftFrontParams.pressure.value = 1000
    local rightFrontParams = tirePressureParams.rightFront.params
    rightFrontParams.status.value = "NORMAL"
    rightFrontParams.tpms.value = "UNKNOWN"
    rightFrontParams.pressure.value = 1000
    local leftRearParams = tirePressureParams.leftRear.params
    leftRearParams.status.value = "NORMAL"
    leftRearParams.tpms.value = "UNKNOWN"
    leftRearParams.pressure.value = 1000
    local rightRearParams = tirePressureParams.rightRear.params
    rightRearParams.status.value = "NORMAL"
    rightRearParams.tpms.value = "UNKNOWN"
    rightRearParams.pressure.value = 1000
    local innerLeftRearParams = tirePressureParams.innerLeftRear.params
    innerLeftRearParams.status.value = "NORMAL"
    innerLeftRearParams.tpms.value = "UNKNOWN"
    innerLeftRearParams.pressure.value = 1000
    local innerRightRearParams = tirePressureParams.innerRightRear.params
    innerRightRearParams.status.value = "NORMAL"
    innerRightRearParams.tpms.value = "UNKNOWN"
    innerRightRearParams.pressure.value = 1000
    common.VehicleDataItemsWithData.tirePressure.APItype = "VEHICLEDATA_TIREPRESSURE"
    common.VehicleDataItemsWithData.odometer.value = 10000
    common.VehicleDataItemsWithData.odometer.APItype = "VEHICLEDATA_ODOMETER"
    local beltStatusParams = common.VehicleDataItemsWithData.beltStatus.params
    beltStatusParams.driverBeltDeployed.value = "NO_EVENT"
    beltStatusParams.passengerBeltDeployed.value = "NO_EVENT"
    beltStatusParams.passengerBuckleBelted.value = "NO_EVENT"
    beltStatusParams.driverBuckleBelted.value = "NO_EVENT"
    beltStatusParams.leftRow2BuckleBelted.value = "YES"
    beltStatusParams.passengerChildDetected.value = "YES"
    beltStatusParams.rightRow2BuckleBelted.value = "YES"
    beltStatusParams.middleRow2BuckleBelted.value = "NO"
    beltStatusParams.middleRow3BuckleBelted.value = "NO"
    beltStatusParams.leftRow3BuckleBelted.value = "NOT_SUPPORTED"
    beltStatusParams.rightRow3BuckleBelted.value = "NOT_SUPPORTED"
    beltStatusParams.leftRearInflatableBelted.value = "NOT_SUPPORTED"
    beltStatusParams.rightRearInflatableBelted.value = "FAULT"
    beltStatusParams.middleRow1BeltDeployed.value = "NO_EVENT"
    beltStatusParams.middleRow1BuckleBelted.value = "NO_EVENT"
    common.VehicleDataItemsWithData.beltStatus.APItype = "VEHICLEDATA_BELTSTATUS"
    local gearStatusParams = common.VehicleDataItemsWithData.gearStatus.params
    gearStatusParams.userSelectedGear.value = "NINTH"
    gearStatusParams.actualGear.value = "TENTH"
    gearStatusParams.transmissionType.value = "MANUAL"
    common.VehicleDataItemsWithData.gearStatus.APItype = "VEHICLEDATA_GEARSTATUS"
    local bodyInformationParams = common.VehicleDataItemsWithData.bodyInformation.params
    bodyInformationParams.parkBrakeActive.value = true
    bodyInformationParams.ignitionStableStatus.value = "IGNITION_SWITCH_STABLE"
    bodyInformationParams.ignitionStatus.value = "RUN"
    bodyInformationParams.driverDoorAjar.value = true
    bodyInformationParams.passengerDoorAjar.value = false
    bodyInformationParams.rearLeftDoorAjar.value = false
    bodyInformationParams.rearRightDoorAjar.value = false
    common.VehicleDataItemsWithData.bodyInformation.APItype = "VEHICLEDATA_BODYINFO"
    local deviceStatusParams = common.VehicleDataItemsWithData.deviceStatus.params
    deviceStatusParams.voiceRecOn.value = true
    deviceStatusParams.btIconOn.value = false
    deviceStatusParams.callActive.value = false
    deviceStatusParams.phoneRoaming.value = true
    deviceStatusParams.textMsgAvailable.value = false
    deviceStatusParams.battLevelStatus.value = "NOT_PROVIDED"
    deviceStatusParams.stereoAudioOutputMuted.value = false
    deviceStatusParams.monoAudioOutputMuted.value = false
    deviceStatusParams.signalLevelStatus.value = "NOT_PROVIDED"
    deviceStatusParams.primaryAudioSource.value = "CD"
    deviceStatusParams.eCallEventActive.value = false
    common.VehicleDataItemsWithData.deviceStatus.APItype = "VEHICLEDATA_DEVICESTATUS"
    common.VehicleDataItemsWithData.driverBraking.value = "NO_EVENT"
    common.VehicleDataItemsWithData.driverBraking.APItype = "VEHICLEDATA_BRAKING"
    common.VehicleDataItemsWithData.wiperStatus.value = "AUTO_OFF"
    common.VehicleDataItemsWithData.wiperStatus.APItype = "VEHICLEDATA_WIPERSTATUS"
    local headLampStatusParams = common.VehicleDataItemsWithData.headLampStatus.params
    headLampStatusParams.ambientLightSensorStatus.value = "NIGHT"
    headLampStatusParams.highBeamsOn.value = true
    headLampStatusParams.lowBeamsOn.value = false
    common.VehicleDataItemsWithData.headLampStatus.APItype = "VEHICLEDATA_HEADLAMPSTATUS"
    common.VehicleDataItemsWithData.engineTorque.value = 24.5
    common.VehicleDataItemsWithData.engineTorque.APItype = "VEHICLEDATA_ENGINETORQUE"
    common.VehicleDataItemsWithData.accPedalPosition.value = 10
    common.VehicleDataItemsWithData.accPedalPosition.APItype = "VEHICLEDATA_ACCPEDAL"
    common.VehicleDataItemsWithData.steeringWheelAngle.value = -100
    common.VehicleDataItemsWithData.steeringWheelAngle.APItype = "VEHICLEDATA_STEERINGWHEEL"
    common.VehicleDataItemsWithData.engineOilLife.value = 10.5
    common.VehicleDataItemsWithData.engineOilLife.APItype = "VEHICLEDATA_ENGINEOILLIFE"
    common.VehicleDataItemsWithData.electronicParkBrakeStatus.value = "OPEN"
    common.VehicleDataItemsWithData.electronicParkBrakeStatus.APItype = "VEHICLEDATA_ELECTRONICPARKBRAKESTATUS"
    common.VehicleDataItemsWithData.cloudAppVehicleID.value = "GHF5848363FGHY90034847"
    common.VehicleDataItemsWithData.cloudAppVehicleID.APItype = "VEHICLEDATA_CLOUDAPPVEHICLEID"
    local eCallInfoParams = common.VehicleDataItemsWithData.eCallInfo.params
    eCallInfoParams.eCallNotificationStatus.value = "NOT_USED"
    eCallInfoParams.auxECallNotificationStatus.value = "NOT_USED"
    eCallInfoParams.eCallConfirmationStatus.value = "NORMAL"
    common.VehicleDataItemsWithData.eCallInfo.APItype = "VEHICLEDATA_ECALLINFO"
    local airbagStatusParams = common.VehicleDataItemsWithData.airbagStatus.params
    airbagStatusParams.driverAirbagDeployed.value = "NO_EVENT"
    airbagStatusParams.driverSideAirbagDeployed.value = "NO_EVENT"
    airbagStatusParams.driverCurtainAirbagDeployed.value = "NO_EVENT"
    airbagStatusParams.passengerAirbagDeployed.value = "NO_EVENT"
    airbagStatusParams.passengerCurtainAirbagDeployed.value = "NO_EVENT"
    airbagStatusParams.driverKneeAirbagDeployed.value = "NO_EVENT"
    airbagStatusParams.passengerSideAirbagDeployed.value = "NO_EVENT"
    airbagStatusParams.passengerKneeAirbagDeployed.value = "NO_EVENT"
    common.VehicleDataItemsWithData.airbagStatus.APItype = "VEHICLEDATA_AIRBAGSTATUS"
    local emergencyEventParams = common.VehicleDataItemsWithData.emergencyEvent.params
    emergencyEventParams.emergencyEventType.value = "NO_EVENT"
    emergencyEventParams.fuelCutoffStatus.value = "NORMAL_OPERATION"
    emergencyEventParams.rolloverEvent.value = "NO"
    emergencyEventParams.maximumChangeVelocity.value = 0
    emergencyEventParams.multipleEvents.value = "NO"
    common.VehicleDataItemsWithData.emergencyEvent.APItype = "VEHICLEDATA_EMERGENCYEVENT"
    local clusterModeStatusParams = common.VehicleDataItemsWithData.clusterModeStatus.params
    clusterModeStatusParams.powerModeActive.value = true
    clusterModeStatusParams.powerModeQualificationStatus.value = "POWER_MODE_OK"
    clusterModeStatusParams.carModeStatus.value = "NORMAL"
    clusterModeStatusParams.powerModeStatus.value = "KEY_APPROVED_0"
    common.VehicleDataItemsWithData.clusterModeStatus.APItype = "VEHICLEDATA_CLUSTERMODESTATUS"
    local myKeyParams = common.VehicleDataItemsWithData.myKey.params
    myKeyParams.e911Override.value = "ON"
    common.VehicleDataItemsWithData.myKey.APItype = "VEHICLEDATA_MYKEY"
  else
    utils.cprint(31, "VehicleDataItemsWithData are missed in preloaded file")
  end
end

VehicleDataItemsWithDataTableCreation()

common.customDataTypeSample = {
  {
    name = "custom_vd_item1_integer",
    type = "Integer",
    key = "OEM_REF_INT",
    array = false,
    mandatory = false,
    minvalue = 0,
    maxvalue = 100,
    params = common.EMPTY_ARRAY
  },
  {
    name = "custom_vd_item2_float",
    type = "Float",
    key = "OEM_REF_FLOAT",
    array = false,
    mandatory = false,
    minvalue = 1,
    maxvalue = 100.5
  },
  {
    name = "custom_vd_item3_enum",
    type = "VehicleDataStatus",
    key = "OEM_REF_Enum",
    array = false,
    mandatory = false
  },
  {
    name = "custom_vd_item4_string",
    type = "String",
    key = "OEM_REF_STR",
    array = false,
    mandatory = false,
    minlength = 1,
    maxlength = 256
  },
  {
    name = "custom_vd_item5_boolean",
    type = "Boolean",
    key = "OEM_REF_BOOL",
    array = false,
    mandatory = false
  },
  {
    name = "custom_vd_item6_array_string",
    type = "String",
    key = "OEM_REF_ARR_STR",
    array = true,
    mandatory = false,
    minsize = 0,
    maxsize = 100,
    minlength = 1,
    maxlength = 256
  },
  {
    name = "custom_vd_item7_array_integer",
    type = "Integer",
    key = "OEM_REF_ARR_INT",
    array = true,
    mandatory = false,
    minsize = 0,
    maxsize = 50,
    minvalue = 0,
    maxvalue = 100
  },
  {
    name = "custom_vd_item8_array_float",
    type = "Float",
    key = "OEM_REF_ARR_FLOAT",
    array = true,
    mandatory = false,
    minsize = 0,
    maxsize = 50,
    minvalue = 0,
    maxvalue = 100
  },
  {
    name = "custom_vd_item9_array_enum",
    type = "VehicleDataStatus",
    key = "OEM_REF_ARR_ENUM",
    array = true,
    mandatory = false,
    minsize = 0,
    maxsize = 50,
    minvalue = 0,
    maxvalue = 100
  },
  {
    name = "custom_vd_item10_array_bool",
    type = "Boolean",
    key = "OEM_REF_ARR_BOOL",
    array = true,
    mandatory = false,
    minsize = 0,
    maxsize = 50
  },
  {
    name = "custom_vd_item11_struct",
    type = "Struct",
    key = "OEM_REF_STRUCT",
    mandatory = false,
    params = {
      {
        name = "struct_element_1_int",
        type = "Integer",
        key = "OEM_REF_STRUCT_1_INT",
        mandatory = true,
        minvalue = -100,
        maxvalue = 1000
      },
      {
        name = "struct_element_2_str",
        type = "String",
        key = "OEM_REF_STRUCT_2_STR",
        mandatory = true
      },
      {
        name = "struct_element_3_flt",
        type = "Float",
        key = "OEM_REF_STRUCT_3_FLT",
        mandatory = false
      },
      {
        name = "struct_element_4_enum",
        type = "VehicleDataStatus",
        key = "OEM_REF_STRUCT_4_Enum",
        mandatory = false
      },
      {
        name = "struct_element_5_array",
        type = "Integer",
        key = "OEM_REF_STRUCT_5_ARRAY",
        mandatory = false,
        minsize = 0,
        maxsize = 10,
        minvalue = 0,
        maxvalue = 100,
        array = true
      },
      {
        name = "struct_element_6_struct",
        type = "Struct",
        key = "OEM_REF_STRUCT_6_STRUCT",
        mandatory = false,
        params = {
          {
            name = "substruct_element_1_int",
            type = "Integer",
            key = "OEM_REF_SUB_STRUCT_1_INT",
            mandatory = false,
            array = true
          },
          {
            name = "substruct_element_2_bool",
            type = "Boolean",
            key = "OEM_REF_SUB_STRUCT_2_BOOL",
            mandatory = false
          }
        }
      }
    }
  }
}



--[[ Local Functions ]]
function common.writeCustomDataToGeneralArray(pTbl)
  local function addItems(pDestTbl, pSrcTbl)
    for _, item in pairs (pSrcTbl) do
      if type(item) == "table" then
        pDestTbl[item.name] = common.cloneTable(item)
        if item.type == "Struct" then
          pDestTbl[item.name].params = {}
          addItems(pDestTbl[item.name].params, item.params)
        end
      else
        pDestTbl[item.name] = item
      end
    end
  end

  if type(pTbl) == "table" then
    addItems(common.VehicleDataItemsWithData, pTbl)
  else
    print("Error: pTbl is not a table, pTbl is wrong value type: " .. type(pTbl))
  end
end

function common.setDefaultValuesForCustomData()
  common.VehicleDataItemsWithData.custom_vd_item1_integer.value = 50
  common.VehicleDataItemsWithData.custom_vd_item2_float.value = 99.99
  common.VehicleDataItemsWithData.custom_vd_item3_enum.value = "OFF"
  common.VehicleDataItemsWithData.custom_vd_item4_string.value = " Some string "
  common.VehicleDataItemsWithData.custom_vd_item5_boolean.value = true
  common.VehicleDataItemsWithData.custom_vd_item6_array_string.value = { "string_el_1", "string_el_2", "string_el_3" }
  common.VehicleDataItemsWithData.custom_vd_item7_array_integer.value = { 1, 2, 3, 4, 5 }
  common.VehicleDataItemsWithData.custom_vd_item8_array_float.value = { 1, 2, 3.5, 4.5, 5.5 }
  common.VehicleDataItemsWithData.custom_vd_item9_array_enum.value = { "ON" }
  common.VehicleDataItemsWithData.custom_vd_item10_array_bool.value = { false, true }
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_1_int.value = 100
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_2_str.value = "100"
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_3_flt.value = 100.10
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_4_enum.value = "NO_DATA_EXISTS"
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_5_array.value = { 100 }
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_6_struct.params.substruct_element_1_int.value = { 100, 500, 300 }
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_6_struct.params.substruct_element_2_bool.value = false
end

local function backupPreloadedPT()
  commonPreconditions:BackupFile(common:read_parameter_from_smart_device_link_ini("PreloadedPT"))
end

local function updatePreloadedPT()
  local preloadedTable, preloadedFile = common.getPreloadedFileAndContent()
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  preloadedTable.policy_table.functional_groupings.GroupWithAllRpcSpecVehicleData = common.cloneTable(
    preloadedTable.policy_table.functional_groupings["Emergency-1"])

  local _, rpcSpecDataNames = common.getCustomAndRpcSpecDataNames()
  local rpcsGroupWithAllVehicleData = preloadedTable.policy_table.functional_groupings.GroupWithAllRpcSpecVehicleData.rpcs
  rpcsGroupWithAllVehicleData.GetVehicleData.parameters = rpcSpecDataNames
  rpcsGroupWithAllVehicleData.OnVehicleData.parameters = rpcSpecDataNames
  rpcsGroupWithAllVehicleData.SubscribeVehicleData.parameters = rpcSpecDataNames
  rpcsGroupWithAllVehicleData.UnsubscribeVehicleData.parameters = rpcSpecDataNames

  preloadedTable.policy_table.app_policies.default.groups = {"Base-4", "GroupWithAllRpcSpecVehicleData" }
  common.tableToJsonFile(preloadedTable, preloadedFile)
end

function common.preconditions(isPreloadedUpdate)
  actions.preconditions()
  common.setSDLIniParameter("GetVehicleDataRequest", "100, 1" )
  if isPreloadedUpdate == true or
    isPreloadedUpdate == nil then
    backupPreloadedPT()
    updatePreloadedPT()
  end
end

local function restorePreloadedPT()
  commonPreconditions:RestoreFile(common:read_parameter_from_smart_device_link_ini("PreloadedPT"))
end

function common.postconditions()
  actions.postconditions()
  restorePreloadedPT()
end

function common.policyTableUpdateWithOnPermChange(pPTUpdateFunc, pExpNotificationFunc, pVDparams)
  if not pVDparams then pVDparams = common.getAllVehicleData() end
  common.policyTableUpdate(pPTUpdateFunc, pExpNotificationFunc)
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_, data)
      return common.onPermissionChangeValidation(data.payload.permissionItem, pVDparams)
    end)
end

function common.validation(actualData, expectedData, pMessage)
  if true ~= common:is_table_equal(actualData, expectedData) then
      return false, pMessage .. " contains unexpected parameters.\n" ..
      "Expected table: " .. common.tableToString(expectedData) .. "\n" ..
      "Actual table: " .. common.tableToString(actualData) .. "\n"
  end
  return true
end

local function getOemCustomDataType(pItemName, pCustomTypeItem)
  local dataTypes = common.customDataTypeSample
  if type(pCustomTypeItem) == "table" then
    dataTypes = { pCustomTypeItem }
  end
  for _, customDataType in ipairs(dataTypes) do
    if customDataType.name == pItemName then
      return customDataType.type
    end
  end
  utils.cprint(35, "Warning: Custom data type '" .. pItemName .. "' does not exist")
  return nil
end

function common.buildSubscribeMobileResponseItem(pHmiResponseItem, pItemName, pCustomTypeItem)
  if type(pHmiResponseItem) == "table" then
    local res = utils.cloneTable(pHmiResponseItem)
    if res.dataType == common.CUSTOM_DATA_TYPE then
      res.oemCustomDataType = getOemCustomDataType(pItemName, pCustomTypeItem)
    end
    return res
  end
  return nil
end

function common.VDsubscription(pAppId, pData, pRPC, pCustomTypeItem)
  local hmiReqResData
  local hmiResponseType
  local pVehicleData = common.VehicleDataItemsWithData[pData]
  if pVehicleData.rpcSpecData == true then
    if pData == "clusterModeStatus" then
        hmiReqResData = "clusterModes"
    else
        hmiReqResData = pVehicleData.name
    end
    hmiResponseType = pVehicleData.APItype
  else
    hmiReqResData = pVehicleData.key
    hmiResponseType = common.CUSTOM_DATA_TYPE
  end

  local hmiRequestData
  if pRPC == "UnsubscribeVehicleData" then
    if pVehicleData.rpcSpecData == true then
      hmiRequestData = { [pVehicleData.name] = true }
    else
      hmiRequestData = { [pVehicleData.key] = true }
    end
  else
    hmiRequestData = common.getHMIrequestData(pData)
  end

  local mobRequestData = { [pVehicleData.name] = true }
  local hmiResponseData = {
    [hmiReqResData] = {
      dataType = hmiResponseType,
      resultCode = "SUCCESS"
    }
  }

  local mobileResponseData
  if pData == "clusterModeStatus" then
    mobileResponseData = {
      clusterModes = hmiResponseData[hmiReqResData]
    }
  else
    mobileResponseData = {
      [pVehicleData.name] =
          common.buildSubscribeMobileResponseItem(hmiResponseData[hmiReqResData], pVehicleData.name, pCustomTypeItem)
    }
  end

  local cid = common.getMobileSession(pAppId):SendRPC(pRPC, mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)
  :ValidIf(function(_,data)
    return common.validation(data.params, hmiRequestData, "VehicleInfo." .. pRPC)
  end)
  mobileResponseData.success = true
  mobileResponseData.resultCode = "SUCCESS"
  common.getMobileSession(pAppId):ExpectResponse(cid, mobileResponseData)
  :ValidIf(function(_,data)
    return common.validation(data.payload, mobileResponseData, pRPC .. " response")
  end)

  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_,data)
    common.hashId = data.payload.hashID
  end)
end

function common.VDsubscriptionWithoutReqOnHMI(pAppId, pData, pRPC, pCustomTypeItem)
  local pVehicleData = common.VehicleDataItemsWithData[pData]
  local mobRequestData = { [pVehicleData.name] = true }

  local hmiResponseType
  if pVehicleData.rpcSpecData == true then
    hmiResponseType = pVehicleData.APItype
  else
    hmiResponseType = common.CUSTOM_DATA_TYPE
  end

  local mobileResponseData = {
    [pVehicleData.name] = common.buildSubscribeMobileResponseItem(
        { dataType = hmiResponseType, resultCode = "SUCCESS" },
        pVehicleData.name,
        pCustomTypeItem)
  }

  local cid = common.getMobileSession(pAppId):SendRPC(pRPC, mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC)
  :Times(0)

  mobileResponseData.success = true
  mobileResponseData.resultCode = "SUCCESS"
  common.getMobileSession(pAppId):ExpectResponse(cid, mobileResponseData)
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_,data)
    common.hashId = data.payload.hashID
  end)
end

function common.GetVD(pAppId, pData)
  local mobRequestData = { [common.VehicleDataItemsWithData[pData].name] = true }
  local hmiRequestData = common.getHMIrequestData(pData)
  local hmiResponseData, mobileResponseData = common.getVehicleDataResponse(pData)
  local cid = common.getMobileSession(pAppId):SendRPC("GetVehicleData", mobRequestData)

  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)
  :ValidIf(function(_,data)
    return common.validation(data.params, hmiRequestData, "VehicleInfo.GetVehicleData")
  end)
  mobileResponseData.success = true
  mobileResponseData.resultCode = "SUCCESS"
  common.getMobileSession(pAppId):ExpectResponse(cid, mobileResponseData)
  :ValidIf(function(_,data)
    return common.validation(data.payload, mobileResponseData, "GetVehicleData response")
  end)
end

function common.onVD(pAppId, pData, pExpTime)
  local HMInotifData, mobileNotifData = common.getVehicleDataResponse(pData)
  if not pExpTime then pExpTime = 1 end

  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", HMInotifData)

  common.getMobileSession(pAppId):ExpectNotification("OnVehicleData", mobileNotifData)
  :Times(pExpTime)
  :ValidIf(function(_,data)
    return common.validation(data.payload, mobileNotifData, "OnVehicleData notification")
  end)
end

function common.onVD2Apps(pData, pTimesApp1, pTimesApp2)
  if not pTimesApp1 then pTimesApp1 = 1 end
  if not pTimesApp2 then pTimesApp2 = 1 end
  local HMInotifData, mobileNotifData = common.getVehicleDataResponse(pData)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", HMInotifData)

  common.getMobileSession(1):ExpectNotification("OnVehicleData", mobileNotifData)
  :Times(pTimesApp1)
  :ValidIf(function(_,data)
    return common.validation(data.payload, mobileNotifData, "OnVehicleData notification on first app")
  end)

  common.getMobileSession(2):ExpectNotification("OnVehicleData", mobileNotifData)
  :Times(pTimesApp2)
  :ValidIf(function(_,data)
    return common.validation(data.payload, mobileNotifData, "OnVehicleData notification on second app")
  end)
end

function common.errorRPCprocessing(pAppId, pData, pRPC, pErrorCode)
  local mobRequestData = { [common.VehicleDataItemsWithData[pData].name] = true }
  local cid = common.getMobileSession(pAppId):SendRPC(pRPC, mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC)
  :Times(0)
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = pErrorCode })
end

function common.getHMIrequestData(pVehicleData)
  local HMIrequest = {}
  if common.VehicleDataItemsWithData[pVehicleData].rpcSpecData == true then
    HMIrequest[common.VehicleDataItemsWithData[pVehicleData].name] = true
  else
    local parentVDKey = common.VehicleDataItemsWithData[pVehicleData].key
    if common.VehicleDataItemsWithData[pVehicleData].type == "Struct" then
      HMIrequest[parentVDKey] = {}
      for _, item in pairs(common.VehicleDataItemsWithData[pVehicleData].params) do
        if item.type == "Struct" then
          HMIrequest[parentVDKey][item.key] = {}
          for _, subItem in pairs(item.params) do
            HMIrequest[parentVDKey][item.key][subItem.key] = true
          end
        else
          HMIrequest[parentVDKey][item.key] = true
        end
      end
    else
      HMIrequest[parentVDKey] = true
    end
  end
  return HMIrequest
end

function common.getVehicleDataResponse(pVehicleData)
  local parentVDkey = common.VehicleDataItemsWithData[pVehicleData].key
  local parentVDname = common.VehicleDataItemsWithData[pVehicleData].name
  local HMIresponse = {}
  local mobileResponse = {}
  if pVehicleData == "fuelRange" then
    HMIresponse[parentVDkey] = common.VehicleDataItemsWithData[pVehicleData].value
    mobileResponse[parentVDname] = common.VehicleDataItemsWithData[pVehicleData].value
  elseif
    common.VehicleDataItemsWithData[pVehicleData].type == "Struct" then
    HMIresponse[parentVDkey] = {}
    mobileResponse[parentVDname] = {}
    for _, item in pairs(common.VehicleDataItemsWithData[pVehicleData].params) do
      HMIresponse[parentVDkey][item.key] = item.value
      mobileResponse[parentVDname][item.name] = item.value
      if item.type == "Struct" then
        HMIresponse[parentVDkey][item.key] = {}
        mobileResponse[parentVDname][item.name] = {}
        for _, subItem in pairs(item.params) do
          HMIresponse[parentVDkey][item.key][subItem.key] = subItem.value
          mobileResponse[parentVDname][item.name][subItem.name] = subItem.value
        end
      end
    end
  else
    HMIresponse[parentVDkey] = common.VehicleDataItemsWithData[pVehicleData].value
    mobileResponse[parentVDname] = common.VehicleDataItemsWithData[pVehicleData].value
  end
  if common.VehicleDataItemsWithData[pVehicleData].rpcSpecData == true then
    HMIresponse = mobileResponse
  end
  return HMIresponse, mobileResponse
end

function common.ptuFuncWithCustomData(pTbl)
  pTbl.policy_table.module_config.endpoint_properties = {
    custom_vehicle_data_mapping_url = {
        version = "0.2.1"
      }
  }

  pTbl.policy_table.module_config.endpoints.custom_vehicle_data_mapping_url = {
    default = { "http://x.x.x.x:3000/api/1/vehicleDataMap" }
  }

  pTbl.policy_table.vehicle_data = {}
  pTbl.policy_table.vehicle_data.schema_version = "00.00.02"
  pTbl.policy_table.vehicle_data.schema_items = common.customDataTypeSample
  pTbl.policy_table.functional_groupings.GroupWithAllVehicleData = common.cloneTable(
    pTbl.policy_table.functional_groupings["Emergency-1"])

  local customDataNames = common.getCustomAndRpcSpecDataNames()

  local rpcsGroupWithAllVehicleData = pTbl.policy_table.functional_groupings.GroupWithAllVehicleData.rpcs
  rpcsGroupWithAllVehicleData.GetVehicleData.parameters = customDataNames
  rpcsGroupWithAllVehicleData.OnVehicleData.parameters = customDataNames
  rpcsGroupWithAllVehicleData.SubscribeVehicleData.parameters = customDataNames
  rpcsGroupWithAllVehicleData.UnsubscribeVehicleData.parameters = customDataNames

  pTbl.policy_table.app_policies[actions.app.getPolicyAppId(1)].groups = {
    "Base-4", "GroupWithAllRpcSpecVehicleData", "GroupWithAllVehicleData"
  }
end

function common.ptuFuncWithCustomData2Apps(pTbl)
  common.ptuFuncWithCustomData(pTbl)

  pTbl.policy_table.app_policies[actions.app.getPolicyAppId(2)].groups = {
    "Base-4", "GroupWithAllRpcSpecVehicleData", "GroupWithAllVehicleData"
  }
end

function common.ignitionOff()
  local timeout = 5000
  local function removeSessions()
    for i = 1, common.getAppsCount() do
      test.mobileSession[i] = nil
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  common.getHMIConnection():ExpectEvent(event, "SDL shutdown")
  :Do(function()
      removeSessions()
      StopSDL()
      common.wait(1000)
    end)
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      for i = 1, common.getAppsCount() do
        common.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      end
    end)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(common.getAppsCount())
  local isSDLShutDownSuccessfully = false
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      utils.cprint(35, "SDL was shutdown successfully")
      isSDLShutDownSuccessfully = true
      common.getHMIConnection():RaiseEvent(event, "SDL shutdown")
    end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      common.getHMIConnection():RaiseEvent(event, "SDL shutdown")
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

function common.unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(actions.mobile.getAppsCount())
  actions.mobile.disconnect()
  utils.wait(1000)
end

function common.connectMobile()
  test.mobileConnection:Connect()
  common.getMobileSession():ExpectEvent(events.connectedEvent, "Connected")
  :Do(function()
      utils.cprint(35, "Mobile connected")
    end)
end

function common.ptuWithOnPolicyUpdateFromHMI(pPtuFunc, pVDparams, pExpNotificationFunc)
  common.isPTUStarted()
  :Do(function()
    common.policyTableUpdateWithOnPermChange(pPtuFunc, pExpNotificationFunc, pVDparams)
  end)
  common.getHMIConnection():SendNotification("SDL.OnPolicyUpdate", {} )
end

function common.ptuWithPolicyUpdateReq(pPTUfunc)
  common.isPTUStarted()
  :Do(function()
      common.policyTableUpdateWithOnPermChange(pPTUfunc)
    end)
end

function common.cleanSessions()
  for i = 1, common.getAppsCount() do
    test.mobileSession[i]:StopRPC()
    :Do(function(_, d)
        utils.cprint(35, "Mobile session " .. d.sessionId .. " deleted")
        test.mobileSession[i] = nil
      end)
  end
  common.wait()
end

function common.updateCustomDataTypeSample(pName, dParam, pValue)
  for vehicleDataKey, vehicleDataItem in pairs(common.customDataTypeSample) do
    if vehicleDataItem.name == pName then
      for vehicleDataParam in pairs(common.customDataTypeSample[vehicleDataKey]) do
        if vehicleDataParam == dParam then
            common.customDataTypeSample[vehicleDataKey][vehicleDataParam] = pValue
        end
      end
    end
  end
end

function common.expUpdateNeeded()
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" })
end

function common.getCustomAndRpcSpecDataNames()
  local customData = { }
  local rpcSpecData = { }
  for _, item in pairs(common.VehicleDataItemsWithData) do
    if item.rpcSpecData == true then
      table.insert(rpcSpecData, item.name)
    else
      table.insert(customData, item.name)
    end
  end
  return customData, rpcSpecData
end

function common.onPermissionChangeValidation(pPermissionItem, pGroupParams)
  local checkedRPCs = { "GetVehicleData", "OnVehicleData", "SubscribeVehicleData", "UnsubscribeVehicleData" }
  local hmiLevels = { "BACKGROUND", "FULL", "LIMITED" }
  local msg = ""
  local isError = false
  for _, value in pairs(pPermissionItem) do
    for _, RPCname in pairs(checkedRPCs) do
      if value.rpcName == RPCname then
        local function expectedItem(pExpValue)
          local out = {
            userDisallowed = common.EMPTY_ARRAY,
            allowed = pExpValue
          }
          return out
        end
        if true ~= common:is_table_equal(pGroupParams, value.parameterPermissions.allowed) or
          true ~= common:is_table_equal(common.EMPTY_ARRAY, value.parameterPermissions.userDisallowed)then
          msg = msg .. "OnPermissionChange notification contains not actual parameterPermissions for " .. RPCname ..
          " :\n" ..
          "Expected table:\n" .. common.tableToString(expectedItem(pGroupParams)) .. " \n" ..
          "Actual table:\n" .. common.tableToString(value.parameterPermissions) .. "\n"
          isError = true
        end
        if true ~= common:is_table_equal(hmiLevels, value.hmiPermissions.allowed) or
          true ~= common:is_table_equal(common.EMPTY_ARRAY, value.hmiPermissions.userDisallowed)then
          msg = msg .. "OnPermissionChange notification contains not actual hmiPermissions for " .. RPCname ..
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

function common.policyTableUpdateWithoutOnPermChange(pPTUpdateFunc, pExpNotificationFunc)
  common.policyTableUpdate(pPTUpdateFunc, pExpNotificationFunc)
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
  :Times(0)
end

function common.getAllVehicleData()
  local customData, rpcSpecData = common.getCustomAndRpcSpecDataNames()
  local allVDdata = common.cloneTable(customData)
  for _, value in pairs(rpcSpecData) do
    table.insert(allVDdata, value)
  end
  return allVDdata
end

function common.exitApps()
  for appId = 1, common.getAppsCount() do
    common.getMobileSession(appId):ExpectNotification("OnHMIStatus", { hmiLevel = "NONE" })
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication", {
        appID = common.getHMIAppId(appId),
        reason = "USER_EXIT" })
  end
end

return common

