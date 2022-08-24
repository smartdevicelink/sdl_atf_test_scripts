local common = require('test_scripts/Smoke/commonSmoke')

common.putFileParams = {
  requestParams = {
    syncFileName = 'icon.png',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local requestParams = {
  cmdID = 11,
  menuParams = {
    position = 0,
    menuName = "Commandpositive",
    secondaryText = "Secondary",
    tertiaryText = "Tertiary"
  },
  vrCommands = {
    "VRCommandonepositive",
    "VRCommandonepositivedouble"
  },
  cmdIcon = {
    value = "icon.png",
    imageType = "DYNAMIC"
  },
  secondaryImage = {
    value = "icon.png",
    imageType = "DYNAMIC"
  }
}

local requestParamsUIOnly = {
  cmdID = 11,
  menuParams = {
    position = 0,
    menuName = "Commandpositive",
    secondaryText = "Secondary",
    tertiaryText = "Tertiary"
  },
  cmdIcon = {
    value = "icon.png",
    imageType = "DYNAMIC"
  },
  secondaryImage = {
    value = "icon.png",
    imageType = "DYNAMIC"
  }
}

local requestParamsVROnly = {
  cmdID = 11,
  vrCommands = {
    "VRCommandonepositive",
    "VRCommandonepositivedouble"
  },
  cmdIcon = {
    value = "icon.png",
    imageType = "DYNAMIC"
  },
  secondaryImage = {
    value = "icon.png",
    imageType = "DYNAMIC"
  }
}

local requestUiParams = {
  cmdID = requestParams.cmdID,
  cmdIcon = requestParams.cmdIcon,
  menuParams = requestParams.menuParams,
  secondaryImage = requestParams.secondaryImage
}

local requestVrParams = {
  cmdID = requestParams.cmdID,
  type = "Command",
  vrCommands = requestParams.vrCommands
}

local allParams = {
  requestParams = requestParams,
  requestParamsUIOnly = requestParamsUIOnly,
  requestParamsVROnly = requestParamsVROnly,
  requestUiParams = requestUiParams,
  requestVrParams = requestVrParams
}

local function getRequestParams(includeUI, includeVR)
  if not includeUI then
    return allParams.requestParamsVROnly
  elseif not includeVR then
    return allParams.requestParamsUIOnly
  else
    return allParams.requestParams
  end
end

common.addCommandTimeout = function(sendUIResponse, sendVRResponse)
  local requestParams = getRequestParams(sendUIResponse ~= nil, sendVRResponse ~= nil)
  local cid = common.getMobileSession():SendRPC("AddCommand", requestParams)

  if sendUIResponse ~= nil then
    allParams.requestUiParams.appID = common.getHMIAppId()
    allParams.requestUiParams.cmdIcon.value = common.getPathToFileInAppStorage("icon.png")
    allParams.requestUiParams.secondaryImage.value = common.getPathToFileInAppStorage("icon.png")
    common.getHMIConnection():ExpectRequest("UI.AddCommand", allParams.requestUiParams)
    :Do(function(_, data)
        if sendUIResponse then
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end
        common.getHMIConnection():ExpectRequest("UI.DeleteCommand", {
          cmdID = allParams.requestParams.cmdID
        }):Timeout(20000)
      end)
  else
    common.getHMIConnection():ExpectRequest("UI.AddCommand"):Times(0)
  end

  if sendVRResponse ~= nil then
    allParams.requestVrParams.appID = common.getHMIAppId()
    common.getHMIConnection():ExpectRequest("VR.AddCommand", allParams.requestVrParams)
    :Do(function(_, data)
  	    if sendVRResponse then
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end
        common.getHMIConnection():ExpectRequest("VR.DeleteCommand", { 
          cmdID = allParams.requestParams.cmdID,
          type = "Command",
          grammarID = data.params.grammarID
        }):Timeout(20000)
      end)
    :ValidIf(function(_, data)
      if data.params.grammarID ~= nil then
        return true
      else
        return false, "grammarID should not be empty"
      end
    end)
  else
    common.getHMIConnection():ExpectRequest("VR.AddCommand"):Times(0)
  end

  common.getMobileSession():ExpectResponse(cid, {
    success = false,
    resultCode = "GENERIC_ERROR"
  }):Timeout(20000)
  common.getMobileSession():ExpectNotification("OnHashChange"):Times(0)
end

common.addCommandFailure = function(uiResult, vrResult)
  local requestParams = getRequestParams(uiResult ~= nil, vrResult ~= nil)
  local cid = common.getMobileSession():SendRPC("AddCommand", requestParams)

  if uiResult ~= nil then
    allParams.requestUiParams.appID = common.getHMIAppId()
    allParams.requestUiParams.cmdIcon.value = common.getPathToFileInAppStorage("icon.png")
    allParams.requestUiParams.secondaryImage.value = common.getPathToFileInAppStorage("icon.png")
    common.getHMIConnection():ExpectRequest("UI.AddCommand", allParams.requestUiParams)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, uiResult, {})
        if uiResult == "SUCCESS" then
          common.getHMIConnection():ExpectRequest("UI.DeleteCommand", {
            cmdID = allParams.requestParams.cmdID
          })
        else
          common.getHMIConnection():ExpectRequest("UI.DeleteCommand"):Times(0)
        end
      end)
  else
    common.getHMIConnection():ExpectRequest("UI.AddCommand"):Times(0)
  end

  if vrResult ~= nil then
    allParams.requestVrParams.appID = common.getHMIAppId()
    common.getHMIConnection():ExpectRequest("VR.AddCommand", allParams.requestVrParams)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, vrResult, {})
        if vrResult == "SUCCESS" then
          common.getHMIConnection():ExpectRequest("VR.DeleteCommand", { 
            cmdID = allParams.requestParams.cmdID,
            type = "Command",
            grammarID = data.params.grammarID
          })
        else
          common.getHMIConnection():ExpectRequest("VR.DeleteCommand"):Times(0)
        end
      end)
    :ValidIf(function(_, data)
      if data.params.grammarID ~= nil then
        return true
      else
        return false, "grammarID should not be empty"
      end
    end)
  else
    common.getHMIConnection():ExpectRequest("VR.AddCommand"):Times(0)
  end

  local mobileResult = uiResult == "SUCCESS" and vrResult or uiResult
  common.getMobileSession():ExpectResponse(cid, {
    success = false,
    resultCode = mobileResult
  })
  common.getMobileSession():ExpectNotification("OnHashChange"):Times(0)
end

return common