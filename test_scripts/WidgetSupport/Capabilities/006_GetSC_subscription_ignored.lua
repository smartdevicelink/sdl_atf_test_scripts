---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL ignores subscribe/unsubscribe flag in case App sends `GetSystemCapability`
-- with DISPLAYS type and always contains display capability in GetSystemCapability response
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered
-- Steps:
-- 1) HMI sends `OnSystemCapabilityUpdated` to SDL for display capabilities for particular window
-- SDL does:
--  - transfer `OnSystemCapabilityUpdated` notification to App
-- 2) App sends `GetSystemCapability` request to SDL (with or without`subscribe` flag) for DISPLAYS capabilities
-- SDL does:
--  - proceed with request successfully
--  - provide up-to-date DISPLAYS data to App in response (for all windows)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local systemCapabilityParams = common.getOnSystemCapabilityParams()
local subscription = {
  [1] = nil,
  [2] = true,
  [3] = false,
  [4] = nil,
}

--[[ Local Functions ]]
local function getWidgetParams(pId)
  return {
    windowID = pId,
    windowName = "Widget" .. pId,
    type = "WIDGET"
  }
end

local function sendGetSC(pType, pSubscribe)
  local params = {
    systemCapabilityType = pType,
    subscribe = pSubscribe
  }
  local cid = common.getMobileSession():SendRPC("GetSystemCapability", params)
  common.getMobileSession():ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    systemCapability = systemCapabilityParams.systemCapability
  })
  :ValidIf(function(_, data)
      local info = "Subscribe parameter is ignored. "
        .. "Auto Subscription/Unsubscription is used for DISPLAY capability type."
      if pSubscribe ~= nil and data.payload.info ~= info then
        return false, "Info parameter is missing or has unexpected value"
      end
      if pSubscribe == nil and data.payload.info ~= nil then
        return false, "Info parameter is unexpected"
      end
      return true
    end)
end

local function createWindow(pWindowId)
  local disCap = systemCapabilityParams.systemCapability.displayCapabilities[1]
  local winCap = common.cloneTable(disCap.windowCapabilities[1])
  winCap.windowID = pWindowId
  winCap.templatesAvailable = { "Template_" .. pWindowId }
  table.insert(disCap.windowCapabilities, winCap)
  function common.getOnSystemCapabilityParams()
    local caps = common.cloneTable(systemCapabilityParams)
    caps.systemCapability.displayCapabilities[1].windowCapabilities = {
      [1] = winCap
    }
    return caps
  end
  common.createWindow(getWidgetParams(pWindowId))
end

local function deleteWindow(pId)
  local disCap = systemCapabilityParams.systemCapability.displayCapabilities[1]
  for k, v in pairs(disCap.windowCapabilities) do
    if v.windowID == pId then
      table.remove(disCap.windowCapabilities, k)
    end
  end
  common.deleteWindow(pId)
end

local function sendOnSCU()
  local winCap = systemCapabilityParams.systemCapability.displayCapabilities[1].windowCapabilities[1]
  winCap.windowID = 0
  winCap.templatesAvailable = { "Template_0" }
  local paramsToSDL = common.cloneTable(systemCapabilityParams)
  paramsToSDL.appID = common.getHMIAppId()
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", paramsToSDL)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", systemCapabilityParams)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("HMI sends capabilities for main window", sendOnSCU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for i = 1, 4 do
  common.Step("Create widget " .. i, createWindow, { i })
  common.Step("App sends GetSC RPC for DISPLAYS, subscribe=" .. tostring(subscription[i]), sendGetSC,
    { "DISPLAYS", subscription[i] })
end
for i = 1, 4 do
  common.Step("Delete widget " .. i, deleteWindow, { i })
  common.Step("App sends GetSC RPC for DISPLAYS, subscribe=" .. tostring(subscription[i]), sendGetSC,
    { "DISPLAYS", subscription[i] })
end

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
