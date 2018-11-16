---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ Variables ]]
local m = actions

--[[ Functions]]
function m.closeApplicationRPCSucces()
	local cid = m.getMobileSession():SendRPC("CloseApplication", {})
	EXPECT_HMICALL("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(), level = "NONE" })
	:Do(function(_, data)
		m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
	end)
	m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
	m.getMobileSession():ExpectNotification("OnHMIStatus",
		{ hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

function m.closeApplicationRPCUnsucces(pResultCode)
	local cid = m.getMobileSession():SendRPC("CloseApplication", {})
	EXPECT_HMICALL("BasicCommunication.ActivateApp")
	:Times(0)
	m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode })
	m.getMobileSession():ExpectNotification("OnHMIStatus")
	:Times(0)
end

function m.closeApplicationRPCwithoutHMIResponse(pResultCode)
	local cid = m.getMobileSession():SendRPC("CloseApplication", {})
	EXPECT_HMICALL("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(), level = "NONE" })
	:Do(function()
		-- HMI did not response
	end)
	m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode })
	m.getMobileSession():ExpectNotification("OnHMIStatus")
	:Times(0)
end

function m.hmiLeveltoLimited(pAppId)
	if not pAppId then pAppId = 1 end
	m.getHMIConnection(pAppId):SendNotification("BasicCommunication.OnAppDeactivated",
		{ appID = m.getHMIAppId(pAppId) })
	m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
		{ hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

return m
