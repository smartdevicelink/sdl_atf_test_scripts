---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local utils = require("user_modules/utils")

--[[ Module ]]
local m = actions

--[[ Local variables ]]
local putFileParams = {
	requestParams = {
	    syncFileName = 'icon.png',
	    fileType = "GRAPHIC_PNG",
	    persistentFile = false,
	    systemFile = false
	},
	filePath = "files/icon.png"
}

--[[ Functions ]]
local function addCommandParams()
	local requestParams = {
		cmdID = 11,
		menuParams = {
			position = 0,
			menuName ="Commandpositive"
		},
		cmdIcon = {
			value ="icon.png",
			imageType ="DYNAMIC"
		}
	}
	local responseUiParams = {
		cmdID = requestParams.cmdID,
		cmdIcon = commonFunctions:cloneTable(requestParams.cmdIcon),
		menuParams = requestParams.menuParams
	}
	responseUiParams.cmdIcon.value = m.getPathToFileInStorage("icon.png")
	local params = {
		requestParams = requestParams,
		responseUiParams = responseUiParams,
	}
	 return params
end

local function alertParams()
	local requestParams = {
	alertText1 = "alertText1",
	alertText2 = "alertText2",
	softButtons = {
		{
			type = "BOTH",
			text = "Close",
			image = {
				value = "icon.png",
				imageType = "DYNAMIC",
			},
			isHighlighted = true,
			softButtonID = 3,
			systemAction = "DEFAULT_ACTION",
		}
	}
}

local responseUiParamsAlert = {
	alertStrings = {
		{
			fieldName = requestParams.alertText1,
			fieldText = requestParams.alertText1
		},
		{
			fieldName = requestParams.alertText2,
			fieldText = requestParams.alertText2
		}
	},
		alertType = "UI",
		softButtons = commonFunctions:cloneTable(requestParams.softButtons)
	}
	responseUiParamsAlert.softButtons[1].image.value = m.getPathToFileInStorage("icon.png")
	local params = {
		requestParams = requestParams,
		responseUiParams = responseUiParamsAlert,
	}
	return params
end

function m.getPathToFileInStorage(fileName)
  return commonPreconditions:GetPathToSDL() .. "storage/"
  .. config["application1"].registerAppInterfaceParams.appID .. "_"
  .. utils.getDeviceMAC() .. "/" .. fileName
end

function m.putFile(pParams)
  if not pParams then pParams = putFileParams end
  local mobileSession = m.getMobileSession();
  local cid = mobileSession:SendRPC("PutFile", pParams.requestParams, pParams.filePath)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function m.addCommand(pIsTemplate, pParams)
	if not pParams then pParams = addCommandParams() end
	if
		pIsTemplate == true or
	 	pIsTemplate == false then
		pParams.requestParams.cmdIcon.isTemplate = pIsTemplate
		pParams.responseUiParams.cmdIcon.isTemplate = pIsTemplate
	end
	local mobSession = m.getMobileSession()
	local hmiConnection = m.getHMIConnection()
	local cid = mobSession:SendRPC("AddCommand", pParams.requestParams)
	pParams.responseUiParams.appID = m.getHMIAppId()
	EXPECT_HMICALL("UI.AddCommand", pParams.responseUiParams)
	:Do(function(_,data)
		hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_, data)
		if
			not pIsTemplate and
			data.params.cmdIcon.isTemplate then
			return false, " isTemplate paramter is present in UI.AddCommand, isTemplate was not send in mobile request "
		end
		return true
	end)
	mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	mobSession:ExpectNotification("OnHashChange")
end

function m.rpcInvalidData(pIsTemplate, pRpc)
	local params
	if "AddCommand" == pRpc then
		params = addCommandParams()
		params.requestParams.cmdIcon.isTemplate = pIsTemplate
	else
		params =  alertParams()
		params.requestParams.softButtons[1].image.isTemplate = pIsTemplate
	end
	local mobSession = m.getMobileSession()
	local cid = mobSession:SendRPC(pRpc, params.requestParams)
	EXPECT_HMICALL("UI." .. pRpc)
	:Times(0)
	mobSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function sendOnSystemContext(ctx)
  m.getHMIConnection():SendNotification("UI.OnSystemContext",
	{
	  appID = m.getHMIAppId(),
	  systemContext = ctx
	})
end

function m.alert(pIsTemplate, pParams)
	if not pParams then pParams = alertParams() end
	local mobSession = m.getMobileSession()
	if pIsTemplate then
		pParams.requestParams.softButtons[1].image.isTemplate = pIsTemplate
		pParams.responseUiParams.softButtons[1].image.isTemplate = pIsTemplate
	end
	local responseDelay = 3000
	local cid = mobSession:SendRPC("Alert", pParams.requestParams)
	EXPECT_HMICALL("UI.Alert", pParams.responseUiParams)
	:Do(function(_,data)
		sendOnSystemContext("ALERT")
		local alertId = data.id
		local function alertResponse()
			m.getHMIConnection():SendResponse(alertId, "UI.Alert", "SUCCESS", { })
			sendOnSystemContext("MAIN")
		end
		RUN_AFTER(alertResponse, responseDelay)
	end)
	:ValidIf(function(_, data)
		if
			not pIsTemplate and
			data.params.softButtons[1].image.isTemplate then
			return false, " isTemplate paramter is present in UI.Alert, isTemplate was not send in mobile request "
		end
		return true
	end)
	mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT"},
        { systemContext = "MAIN"})
	mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

return m
