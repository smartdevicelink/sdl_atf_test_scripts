---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local ssl = require("test_scripts/Security/SSLHandshakeFlow/common")
local constants = require("protocol_handler/ford_protocol_constants")
local runner = require('user_modules/script_runner')
local utils = require('user_modules/utils')
local events = require("events")
local bson = require('bson4lua')
local SDL = require('SDL')
local hmi_values = require("user_modules/hmi_values")
local atf_logger = require("atf_logger")

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 5

--[[ Variables ]]
local common = ssl

common.events      = events
common.frameInfo   = constants.FRAME_INFO
common.frameType   = constants.FRAME_TYPE
common.serviceType = constants.SERVICE_TYPE
common.getDeviceName = utils.getDeviceName
common.getDeviceMAC = utils.getDeviceMAC
common.isFileExist = utils.isFileExist
common.cloneTable = utils.cloneTable
common.testSettings = runner.testSettings
common.Title = runner.Title
common.Step = runner.Step
common.getDefaultHMITable = hmi_values.getDefaultHMITable
common.spairs = utils.spairs
common.ptsTable = actions.sdl.getPTS
common.getParams = actions.app.getParams
common.isTableEqual = utils.isTableEqual
common.failTestStep = actions.run.fail
common.getHMICapabilitiesFromFile = actions.sdl.getHMICapabilitiesFromFile
common.setHMICapabilitiesToFile = actions.sdl.setHMICapabilitiesToFile
common.createSession = actions.mobile.createSession
common.getHMIConnection = actions.hmi.getConnection
common.toString = utils.toString
common.wait = utils.wait
common.getMobileSession = actions.getMobileSession
common.tableToString = utils.tableToString
common.bson_to_table = bson.to_table
common.bson_to_bytes = bson.to_bytes

common.bsonType = {
    DOUBLE   = 0x01,
    STRING   = 0x02,
    DOCUMENT = 0x03,
    ARRAY    = 0x04,
    BOOLEAN  = 0x08,
    INT32    = 0x10,
    INT64    = 0x12
}

local hmiDefaultCapabilities = common.getDefaultHMITable()
common.isCacheNotUsed = false

common.vehicleTypeInfoParams = {
    default = {
        make = "Ford",
        model = "Focus",
        modelYear = "2015",
        trim = "SEL",
        ccpu_version = "12345_TV"
    },
    custom = {
        make = "OEM1",
        model = "Mustang",
        modelYear = "2020",
        trim = "LES",
        ccpu_version = "2020_TV"
    }
}
common.defaultSystemHardwareVersion = " "

--[[ Tests Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Functions ]]
function common.log(...)
    local strBinaryData = ""
    local function getTableSize(T)
      local count = 0
      for _ in pairs(T) do count = count + 1 end
      return count
    end
    local str = "[" .. atf_logger.formated_time(true) .. "]"
        for _, a in pairs({...}) do
            if type(a) == 'table' then
                local i = 0
                for p, v in pairs(a) do
                    i = i + 1
                    local endDelimiter = ",\n "
                    if i == getTableSize(a) then endDelimiter = "\n " end
                    local vv = v.value
                    if type(v.value) == 'table' then
                        local val = ""
                        local subEndDelimiter = ", "
                        for key, subv in pairs(v.value) do
                            if key == getTableSize(v.value) then subEndDelimiter = "" end
                            val = val .. subv.value .. subEndDelimiter
                        end
                        vv = "{ ".. val .." }"
                    end
                    strBinaryData = strBinaryData .. p .." : " .. vv .. endDelimiter
                end
                str = str .. " " .. "{\n " .. strBinaryData .. "}"
            else
                str = str .. " " .. a
            end
        end
    utils.cprint(35, str)
end

function common.startServiceProtectedACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
    local mobSession = common.getMobileSession(pAppId)
    mobSession:StartSecureService(pServiceId, bson.to_bytes(pRequestPayload))
    common.log("MOB->SDL: App" ..pAppId.." StartSecureService(" ..pServiceId.. ")", pRequestPayload)
    mobSession:ExpectControlMessage(pServiceId, {
      frameInfo = common.frameInfo.START_SERVICE_ACK,
      encryption = true
    })
    :ValidIf(function(_, data)
        local actPayload = bson.to_table(data.binaryData)
        common.log("SDL->MOB: App" ..pAppId.." StartServiceAck(" ..pServiceId.. ")", actPayload)
        return compareValues(pResponsePayload, actPayload, "binaryData")
    end)

    if pServiceId == 7 then
        mobSession:ExpectHandshakeMessage()
    elseif pServiceId == 11 then
        common.getHMIConnection():ExpectRequest("Navigation.SetVideoConfig")
        :Do(function(_, data)
            common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end
end

function common.startServiceProtectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
    local mobSession = common.getMobileSession(pAppId)
    mobSession:StartSecureService(pServiceId, bson.to_bytes(pRequestPayload))
    local ret = mobSession:ExpectControlMessage(pServiceId, {
        frameInfo = common.frameInfo.START_SERVICE_NACK,
        encryption = false
    })
    :ValidIf(function(_, data)
        local actPayload = bson.to_table(data.binaryData)
        return compareValues(pResponsePayload, actPayload, "binaryData")
    end)
    return ret
end

function common.startServiceUnprotectedACK(pAppId, pServiceId, pRequestPayload, pResponsePayload, pExtensionFunc)
    if pExtensionFunc then pExtensionFunc() end
    local mobSession = common.getMobileSession(pAppId)
    local msg = {
        serviceType = pServiceId,
        frameType = constants.FRAME_TYPE.CONTROL_FRAME,
        frameInfo = constants.FRAME_INFO.START_SERVICE,
        sessionId = mobSession,
        encryption = false,
        binaryData = bson.to_bytes(pRequestPayload)
    }
    mobSession:Send(msg)
    common.log("MOB->SDL: App" ..pAppId.." StartService(" ..pServiceId.. ")", pRequestPayload)
    local ret = mobSession:ExpectControlMessage(pServiceId, {
        frameInfo = common.frameInfo.START_SERVICE_ACK,
        encryption = false
    })
    :ValidIf(function(_, data)
        mobSession.hashCode = data.binaryData
        mobSession.sessionId = data.sessionId
        local actPayload = bson.to_table(data.binaryData)
        common.log("SDL->MOB: App" ..pAppId.." StartServiceAck(" ..pServiceId.. ")", actPayload)
        return compareValues(pResponsePayload, actPayload, "binaryData")
    end)
    return ret
end

function common.startServiceUnprotectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload, pExtensionFunc)
    if pExtensionFunc then pExtensionFunc() end
    local mobSession = common.getMobileSession(pAppId)
    local msg = {
        serviceType = pServiceId,
        frameType = constants.FRAME_TYPE.CONTROL_FRAME,
        frameInfo = constants.FRAME_INFO.START_SERVICE,
        sessionId = mobSession,
        encryption = false,
        binaryData = bson.to_bytes(pRequestPayload)
    }
    mobSession:Send(msg)
    local ret = mobSession:ExpectControlMessage(pServiceId, {
        frameInfo = common.frameInfo.START_SERVICE_NACK,
        encryption = false
    })
    :ValidIf(function(_, data)
        local actPayload = bson.to_table(data.binaryData)
        return compareValues(pResponsePayload, actPayload, "binaryData")
    end)
    return ret
end

function common.registerAppUpdatedProtocolVersion(hasPTU)
    local appId = 1
    local session = common.getMobileSession()
    local msg = {
        serviceType = common.serviceType.RPC,
        frameType = constants.FRAME_TYPE.CONTROL_FRAME,
        frameInfo = constants.FRAME_INFO.START_SERVICE,
        sessionId = session.sessionId,
        encryption = false,
        binaryData = bson.to_bytes({ protocolVersion = { type = common.bsonType.STRING, value = "5.4.0" }})
    }
    session:Send(msg)

    session:ExpectControlMessage(common.serviceType.RPC, {
        frameInfo = common.frameInfo.START_SERVICE_ACK,
        encryption = false
    })
    :Do(function()
        session.sessionId = appId
        local corId = session:SendRPC("RegisterAppInterface", common.app.getParams(appId))

        common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
            { application = { appName = common.app.getParams(appId).appName } })
        :Do(function(_, d1)
            common.app.setHMIId(d1.params.application.appID, appId)
            if hasPTU then
                common.ptu.expectStart()
            end
        end)

        session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
        :Do(function()
            session:ExpectNotification("OnHMIStatus",
                { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        end)
    end)
end

function common.ptuFailedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload, pExtensionFunc)
    if pExtensionFunc then pExtensionFunc() end
    common.startServiceProtectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
    common.getMobileSession():ExpectHandshakeMessage()
    :Times(0)
    local function ptUpdate(pTbl)
        -- notifications_per_minute_by_priority parameter is mandatory and PTU would fail if it's removed
        pTbl.policy_table.module_config.notifications_per_minute_by_priority = nil
    end
    local expNotificationFunc = function()
        common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData")
        :Times(0)
    end
    common.isPTUStarted()
    :Do(function()
        common.policyTableUpdate(ptUpdate, expNotificationFunc)
    end)
end

function common.startSecureServiceTimeNotProvided(pAppId, pServiceId, pRequestPayload, pResponsePayload, pExtensionFunc)
    if pExtensionFunc then pExtensionFunc() end

    local event = events.Event()
    event.level = 3
    event.matches = function(_, data)
        return data.method == "BasicCommunication.GetSystemTime"
    end
    common.getHMIConnection():ExpectEvent(event, "Expect GetSystemTime")
    :Do(function(_, data)
        common.getHMIConnection():SendError(data.id, data.method, "DATA_NOT_AVAILABLE", "Time is not provided")
    end)

    common.startServiceProtectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
end

function common.setProtectedServicesInIni()
  common.sdl.setSDLIniParameter("ForceProtectedService", "0x0A, 0x0B")
end

function common.getVehicleTypeDataFromInitialCap()
    local initialCap = SDL.HMICap.get()
    return initialCap.VehicleInfo.vehicleType
end

function common.getVehicleTypeDataFromCachedCap()
    local initialCap = SDL.HMICapCache.get()
    return initialCap.VehicleInfo.vehicleType
end

function common.getCapWithMandatoryExp()
    local initialCap = common.cloneTable(hmiDefaultCapabilities)
    initialCap.VehicleInfo.GetVehicleType.mandatory = true
    initialCap.BasicCommunication.GetSystemInfo.mandatory = true
    return initialCap
end

function common.setStringBsonValue(pValue)
    return { type = common.bsonType.STRING, value = pValue }
end

function common.getRpcServiceAckParamsFromStruct(pVehicleTypeInfoParams)
    local ackParams = {
        make = common.setStringBsonValue(pVehicleTypeInfoParams.make),
        model = common.setStringBsonValue(pVehicleTypeInfoParams.model),
        modelYear = common.setStringBsonValue(pVehicleTypeInfoParams.modelYear),
        trim = common.setStringBsonValue(pVehicleTypeInfoParams.trim),
        systemSoftwareVersion = common.setStringBsonValue(pVehicleTypeInfoParams.ccpu_version),
        systemHardwareVersion = common.setStringBsonValue(common.defaultSystemHardwareVersion)
    }
    for key, KeyValue in pairs(ackParams) do
        if not KeyValue.value then
            ackParams[key] = nil
        end
    end
    return ackParams
end

function common.getRpcServiceAckParams(pHMIcap)
    local vehicleTypeInfoParams = {}
    for k, v in pairs(pHMIcap.VehicleInfo.GetVehicleType.params.vehicleType) do
        vehicleTypeInfoParams[k] = v
    end
    for k, v in pairs(pHMIcap.BasicCommunication.GetSystemInfo.params) do
        vehicleTypeInfoParams[k] = v
    end
    return common.getRpcServiceAckParamsFromStruct(vehicleTypeInfoParams)
end

function common.endRPCService()
    local mobSession = common.getMobileSession(1)
    local msg = {
        serviceType = common.serviceType.RPC,
        frameType = constants.FRAME_TYPE.CONTROL_FRAME,
        frameInfo = constants.FRAME_INFO.END_SERVICE,
        binaryData = mobSession.hashCode,
        encryption = false
    }
    mobSession:Send(msg)

    local event = actions.run.createEvent()
    -- prepare event to expect
    event.matches = function(_, data)
        return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
        data.serviceType == common.serviceType.RPC and
        (data.frameInfo == constants.FRAME_INFO.END_SERVICE_ACK or
            data.frameInfo == constants.FRAME_INFO.END_SERVICE_NACK)
    end

    mobSession:ExpectEvent(event, "EndService ACK")
    :ValidIf(function(_, data)
        if data.frameInfo == constants.FRAME_INFO.END_SERVICE_ACK then return true
        else return false, "EndService NACK received" end
    end)
end

function common.registerAppEx(responseExpectedData, pAppId)
    pAppId = pAppId or 1
    local session = common.getMobileSession(pAppId)
    local corId = session:SendRPC("RegisterAppInterface", common.app.getParams(pAppId))

    common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.app.getParams(pAppId).appName } })
    :Do(function(_, d1)
        common.app.setHMIId(d1.params.application.appID, pAppId)
    end)

    local responseData = { success = true, resultCode = "SUCCESS" }
    responseData.systemSoftwareVersion = responseExpectedData.ccpu_version
    local vehicleType = {
        make = responseExpectedData.make,
        model = responseExpectedData.model,
        modelYear = responseExpectedData.modelYear,
        trim = responseExpectedData.trim
    }

    local ret = session:ExpectResponse(corId, responseData)
    :Do(function()
        session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    end)
    :ValidIf(function(_, data)
        local isResult  = true
        local errorMsg = ""
        if data.systemHardwareVersion then
            errorMsg = errorMsg .. "\n RAI response contains unexpected systemHardwareVersion parameter"
            isResult = false
        end
        if not responseExpectedData.systemSoftwareVersion and data.systemSoftwareVersion then
            errorMsg = errorMsg .. "\n RAI response contains unexpected systemSoftwareVersion parameter"
            isResult = false
        end
        if utils.isTableEqual(data.payload.vehicleType, vehicleType) == false then
            errorMsg = "\nData from vehicleType structure in RAI response does not correspond to expected one" ..
            "\nExpected result:\n" .. utils.tableToString(vehicleType) ..
            "\nActual result:\n" .. utils.tableToString(data.payload.vehicleType)
            isResult = false
        end
        return isResult, errorMsg
    end)
    return ret
end

function common.setHMIcap(pVehicleTypeData)
    local hmicap = common.getCapWithMandatoryExp()
    local getVehicleTypeParams = hmicap.VehicleInfo.GetVehicleType.params.vehicleType
    getVehicleTypeParams.make = pVehicleTypeData.make
    getVehicleTypeParams.model = pVehicleTypeData.model
    getVehicleTypeParams.modelYear = pVehicleTypeData.modelYear
    getVehicleTypeParams.trim = pVehicleTypeData.trim

    local getSystemInfoParams = hmicap.BasicCommunication.GetSystemInfo.params
    getSystemInfoParams.ccpu_version = pVehicleTypeData.ccpu_version

    return hmicap
end

function common.ignitionOff()
    local hmiConnection = actions.hmi.getConnection()
    local mobileConnection = actions.mobile.getConnection()
    config.ExitOnCrash = false
    local timeout = 5000
    local function removeSessions()
        for i = 1, actions.mobile.getAppsCount() do
            actions.mobile.deleteSession(i)
        end
    end
    local event = events.Event()
    event.matches = function(event1, event2) return event1 == event2 end
    mobileConnection:ExpectEvent(event, "SDL shutdown")
    :Do(function()
        removeSessions()
        StopSDL()
        config.ExitOnCrash = true
    end)
    hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
    hmiConnection:ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
    :Do(function()
        hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
        for i = 1, actions.mobile.getAppsCount() do
            actions.mobile.getSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
        end
    end)
    hmiConnection:ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
    :Times(actions.mobile.getAppsCount())
    local isSDLShutDownSuccessfully = false
    hmiConnection:ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
        utils.cprint(35, "SDL was shutdown successfully")
        isSDLShutDownSuccessfully = true
        mobileConnection:RaiseEvent(event, event)
    end)
    :Timeout(timeout)
    local function forceStopSDL()
        if isSDLShutDownSuccessfully == false then
            utils.cprint(35, "SDL was shutdown forcibly")
            mobileConnection:RaiseEvent(event, event)
        end
    end
    actions.run.runAfter(forceStopSDL, timeout + 500)
end

local postconditionsOrig = ssl.postconditions
function common.postconditions()
    postconditionsOrig()
    actions.mobile.deleteSession()
end

function common.startRpcService(pAckParams, pAppId)
    pAppId = pAppId or 1
    local reqParams = { protocolVersion = common.setStringBsonValue("5.4.0") }
    return common.startServiceUnprotectedACK(pAppId, common.serviceType.RPC, reqParams, pAckParams)
end

local function registerExpFor_GetSI_and_GetVT(pGetSIparams, pGetVTparams, pDelayGetSI, pDelayGetVT, pTSs)
    common.hmi.getConnection():ExpectRequest("BasicCommunication.GetSystemInfo")
    :Do(function(_, data)
        local function response()
            pTSs.ts_get_si = timestamp()
            common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", pGetSIparams)
        end
        common.run.runAfter(response, pDelayGetSI)
    end)

    local times_GetVT = 1
    if pDelayGetVT == -1 then times_GetVT = 0 end
    common.hmi.getConnection():ExpectRequest("VehicleInfo.GetVehicleType")
    :Do(function(_, data)
        local function response()
            pTSs.ts_get_vt = timestamp()
            common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", pGetVTparams)
        end
        if pDelayGetVT ~= -1 then common.run.runAfter(response, pDelayGetVT) end
    end)
   :Times(times_GetVT)
end

function common.startWithExtension(pDelayGetSI, pDelayGetVT, pExtensionFunc)
    local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
    local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)
    local mobileConnectionDelay = 50
    common.init.SDL()
    :Do(function()
        common.init.HMI()
        :Do(function()
            local ts = {}
            local getSIparams = hmiCap.BasicCommunication.GetSystemInfo.params
            local getVTparams = hmiCap.VehicleInfo.GetVehicleType.params
            hmiCap.VehicleInfo.GetVehicleType = nil
            hmiCap.BasicCommunication.GetSystemInfo = nil
            registerExpFor_GetSI_and_GetVT(getSIparams, getVTparams, pDelayGetSI, pDelayGetVT, ts)
            common.init.HMI_onReady(hmiCap)
            common.run.runAfter(function()
                common.init.connectMobile()
                :Do(function()
                    pExtensionFunc(pDelayGetVT, ts, rpcServiceAckParams)
                end)
            end, mobileConnectionDelay)
        end)
    end)
end

function common.delayedStartServiceAckP5(pDelayGetVT, pTS, pRpcServiceAckParams)
    config.defaultProtocolVersion = 5

    common.log("StartService")
    common.startRpcService(pRpcServiceAckParams)
    :ValidIf(function()
        common.log("StartServiceAck")
        if pTS.ts_get_si == nil then
            return false, "StartServiceAck received before receiving of GetSystemInfo from HMI"
        end
        if pTS.ts_get_vt == nil and pDelayGetVT ~= -1 then
            return false, "StartServiceAck received before receiving of GetVehicleType from HMI"
        end
        return true
    end)
    :Do(function()
        common.log("RAI")
        local ts_req = timestamp()
        common.registerAppEx(common.vehicleTypeInfoParams.default)
        :ValidIf(function()
            local tolerance = 750
            local ts_res = timestamp()
            local act_delay = ts_res - ts_req
            common.log("RAIResponse", act_delay)
            if act_delay > tolerance then
                return false, "RAI response is expected right after RAI request, actual delay: "
                    .. act_delay .. "ms"
            end
            return true
        end)
    end)
end

function common.delayedStartServiceAckP4(pDelayGetVT, pTS)
    config.defaultProtocolVersion = 4

    local ts_req = timestamp()
    common.log("StartService")
    common.getMobileSession():StartService(common.serviceType.RPC)
    :Do(function()
        common.log("RAI")
        common.registerAppEx(common.vehicleTypeInfoParams.default)
        :ValidIf(function()
            common.log("RAIResponse")
            if pTS.ts_get_si == nil then
                return false, "RAI response received before receiving of GetSystemInfo from HMI"
            end
            if pTS.ts_get_vt == nil and pDelayGetVT ~= -1 then
                return false, "RAI response received before receiving of GetVehicleType from HMI"
            end
            return true
        end)
    end)
    :ValidIf(function()
        local tolerance = 750
        local ts_res = timestamp()
        local act_delay = ts_res - ts_req
        common.log("StartServiceAck", act_delay)
        if act_delay > tolerance then
            return false, "StartServiceAck is expected right after StartService request, actual delay: "
                .. act_delay .. "ms"
        end
        return true
    end)
end

function common.updateHMICapabilitiesFile(pVehicleTypeData)
    local hmiCapTbl = common.getHMICapabilitiesFromFile()
    hmiCapTbl.VehicleInfo.vehicleType.make = pVehicleTypeData.make
    hmiCapTbl.VehicleInfo.vehicleType.model = pVehicleTypeData.model
    hmiCapTbl.VehicleInfo.vehicleType.modelYear = pVehicleTypeData.modelYear
    hmiCapTbl.VehicleInfo.vehicleType.trim = pVehicleTypeData.trim
    common.setHMICapabilitiesToFile(hmiCapTbl)
end

return common
