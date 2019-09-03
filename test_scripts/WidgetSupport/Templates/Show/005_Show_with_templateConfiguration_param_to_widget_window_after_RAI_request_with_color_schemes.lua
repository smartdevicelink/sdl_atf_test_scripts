---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL proceed with "Show" RPC to widget in case if color schemes have been defined
-- during app registration
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App registered and activated (color schemes are defined)
-- 3) App successfully created and activated Widget
-- Steps:
-- 1) App sends "Show" request to Widget with different parameters
-- SDL does:
--  - Proceed with request successfully or not (depending on parameters)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local values = {
  NEW = 1,
  CURRENT = 2,
  MISSING = 3,
  INVALID = 4
}

local initial = { template = values.MISSING, day = values.NEW, night = values.NEW }
local testCases = {
  [001] = { template = values.NEW,     day = values.NEW,     night = values.NEW,     status = "SUCCESS" },
  [002] = { template = values.NEW,     day = values.CURRENT, night = values.CURRENT, status = "SUCCESS" },
  [003] = { template = values.NEW,     day = values.NEW,     night = values.CURRENT, status = "SUCCESS" },
  [004] = { template = values.NEW,     day = values.CURRENT, night = values.NEW,     status = "SUCCESS" },
  [005] = { template = values.NEW,     day = values.MISSING, night = values.MISSING, status = "SUCCESS" },
  [006] = { template = values.NEW,     day = values.NEW,     night = values.MISSING, status = "SUCCESS" },
  [007] = { template = values.NEW,     day = values.MISSING, night = values.NEW,     status = "SUCCESS" },
  [008] = { template = values.NEW,     day = values.INVALID, night = values.INVALID, status = "INVALID_DATA" },
  [009] = { template = values.NEW,     day = values.NEW,     night = values.INVALID, status = "INVALID_DATA" },
  [010] = { template = values.NEW,     day = values.INVALID, night = values.NEW,     status = "INVALID_DATA" },
}

local paramsWidget = {
  windowID = 3,
  windowName = "Widget",
  type = "WIDGET"
}

local id
local params = { }

local schemaTypes = {
  DAY = "day",
  NIGHT = "night"
}

--[[ Local Functions ]]
local function getTemplate(pValueType)
  if pValueType == values.NEW then
    return "Template" .. id
  end
  if pValueType == values.CURRENT then
    return params.templateConfiguration.template
  end
  return nil
end

local function getColorScheme(pSchemaType, pValueType)
  local paramName = pSchemaType .. "ColorScheme"
  local shft
  if pSchemaType == schemaTypes.DAY then shft = 0 end
  if pSchemaType == schemaTypes.NIGHT then shft = 3 end
  local color = {
    red = id * 10 + 1 + shft,
    green = id * 10 + 2 + shft,
    blue = id * 10 + 3 + shft
  }
  if pValueType == values.NEW then
    return {
      primaryColor = color
    }
  end
  if pValueType == values.CURRENT then
    return params.templateConfiguration[paramName]
  end
  if pValueType == values.INVALID then
    color.blue = nil -- mandatory parameter missing
    return {
      primaryColor = color
    }
  end
  return nil
end

local function setParams(pTC, pWindowID)
  params = {
    windowID = pWindowID,
    templateConfiguration = {
      template = getTemplate(pTC.template),
      dayColorScheme = getColorScheme(schemaTypes.DAY, pTC.day),
      nightColorScheme = getColorScheme(schemaTypes.NIGHT, pTC.night)
    }
  }
  id = id + 1
end

local function sendShow_SUCCESS()
  local cid = common.getMobileSession():SendRPC("Show", params)
  common.getHMIConnection():ExpectRequest("UI.Show", params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function sendShow_UNSUCCESS(pResultCode)
  local cid = common.getMobileSession():SendRPC("Show", params)
  common.getHMIConnection():ExpectRequest("UI.Show")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode })
end

local function sendShow(pTC, pWindowID)
  setParams(pTC, pWindowID)
  if pTC.status == "SUCCESS" then
    sendShow_SUCCESS(pWindowID)
  else
    sendShow_UNSUCCESS(pTC.status, pWindowID)
  end
end

local function setInitialState()
  id = 1
  setParams(initial)
  local appParams = common.getConfigAppParams()
  appParams.dayColorScheme = params.templateConfiguration.dayColorScheme
  appParams.nightColorScheme = params.templateConfiguration.nightColorScheme
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  common.Title("TC[" .. string.format("%03d", n) .. "/".. string.format("%03d", #testCases) .. "]")
  common.Title("Precondition")
  common.Step("Clean environment and Back-up/update PPT", common.precondition)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Set initial state", setInitialState)
  common.Step("App registration", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)
  common.Step("Success create Widget window", common.createWindow, { paramsWidget })
  common.Step("Widget is activated", common.activateWidgetFromNoneToFULL, { paramsWidget.windowID, 1 })

  common.Title("Test")
  common.Step("App sends Show to Widget .." .. tc.status, sendShow, { tc, paramsWidget.windowID })

  common.Title("Postconditions")
  common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
end
