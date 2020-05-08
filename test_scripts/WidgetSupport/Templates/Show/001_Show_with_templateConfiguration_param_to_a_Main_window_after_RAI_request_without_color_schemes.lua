---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL proceed with "Show" RPC in case if no color schemes have been defined
-- during app registration
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered (no color schemes are defined)
-- 3) App is activated
-- Steps:
-- 1) App sends 1st Show request with templateConfiguration param to Main window
-- SDL does:
--  - Proceed with request successfully
-- 2) App sends 2nd Show request with different value for the templateConfiguration param to Main window
-- SDL does:
--  - Proceed with request successfully or not (depending on parameters)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local val = {
  NEW = 1,
  CURRENT = 2,
  MISSING = 3,
  MISSING_COLOR = 4,
  INVALID_TYPE = 5,
  EMPTY_VALUE = 6
}

local initial = { template = val.NEW, day = val.NEW, night = val.NEW, status = "SUCCESS" }
local testCases = {
  [001] = { template = val.NEW,     day = val.NEW,     night = val.NEW,     status = "SUCCESS" },
  [002] = { template = val.NEW,     day = val.CURRENT, night = val.CURRENT, status = "SUCCESS" },
  [003] = { template = val.NEW,     day = val.NEW,     night = val.CURRENT, status = "SUCCESS" },
  [004] = { template = val.NEW,     day = val.CURRENT, night = val.NEW,     status = "SUCCESS" },
  [005] = { template = val.CURRENT, day = val.CURRENT, night = val.CURRENT, status = "SUCCESS" },
  [006] = { template = val.CURRENT, day = val.NEW,     night = val.CURRENT, status = "REJECTED" },
  [007] = { template = val.CURRENT, day = val.CURRENT, night = val.NEW,     status = "REJECTED" },
  [008] = { template = val.CURRENT, day = val.NEW,     night = val.NEW,     status = "REJECTED" },
  [009] = { template = val.NEW,     day = val.MISSING, night = val.MISSING, status = "SUCCESS" },
  [010] = { template = val.NEW,     day = val.NEW,     night = val.MISSING, status = "SUCCESS" },
  [011] = { template = val.NEW,     day = val.MISSING, night = val.NEW,     status = "SUCCESS" },
  [012] = { template = val.CURRENT, day = val.MISSING, night = val.MISSING, status = "SUCCESS" },
  [013] = { template = val.CURRENT, day = val.NEW,     night = val.MISSING, status = "REJECTED" },
  [014] = { template = val.CURRENT, day = val.MISSING, night = val.NEW,     status = "REJECTED" },
  [015] = { template = val.MISSING, day = val.MISSING, night = val.MISSING, status = "INVALID_DATA" },
  [016] = { template = val.MISSING, day = val.NEW,     night = val.MISSING, status = "INVALID_DATA" },
  [017] = { template = val.MISSING, day = val.MISSING, night = val.NEW,     status = "INVALID_DATA" },
  [018] = { template = val.MISSING, day = val.NEW,     night = val.NEW,     status = "INVALID_DATA" },
  [019] = { template = val.NEW,     day = val.MISSING_COLOR, night = val.MISSING_COLOR, status = "INVALID_DATA" },
  [020] = { template = val.NEW,     day = val.NEW,           night = val.MISSING_COLOR, status = "INVALID_DATA" },
  [021] = { template = val.NEW,     day = val.MISSING_COLOR, night = val.NEW,           status = "INVALID_DATA" },
  [022] = { template = val.MISSING, day = val.MISSING_COLOR, night = val.MISSING_COLOR, status = "INVALID_DATA" },
  [023] = { template = val.MISSING, day = val.NEW,           night = val.MISSING_COLOR, status = "INVALID_DATA" },
  [024] = { template = val.MISSING, day = val.MISSING_COLOR, night = val.NEW,           status = "INVALID_DATA" },
  [025] = { template = val.MISSING, day = val.NEW,           night = val.NEW,           status = "INVALID_DATA" },
  [026] = { template = val.INVALID_TYPE, day = val.NEW,          night = val.NEW,          status = "INVALID_DATA" },
  [027] = { template = val.INVALID_TYPE, day = val.INVALID_TYPE, night = val.NEW,          status = "INVALID_DATA" },
  [028] = { template = val.INVALID_TYPE, day = val.NEW,          night = val.INVALID_TYPE, status = "INVALID_DATA" },
  [029] = { template = val.EMPTY_VALUE,  day = val.NEW,          night = val.NEW,          status = "INVALID_DATA" },
  [030] = { template = val.NEW,          day = val.NEW,          night = val.INVALID_TYPE, status = "INVALID_DATA" },
  [031] = { template = val.NEW,          day = val.INVALID_TYPE, night = val.NEW,          status = "INVALID_DATA" },
  [032] = { template = val.INVALID_TYPE, day = val.INVALID_TYPE, night = val.INVALID_TYPE, status = "INVALID_DATA" }
}

local id
local params = { }

local schemaTypes = {
  DAY = "day",
  NIGHT = "night"
}

--[[ Local Functions ]]
local function getTemplate(pValueType)
  if pValueType == val.NEW then
    return "Template" .. id
  end
  if pValueType == val.CURRENT then
    return params.templateConfiguration.template
  end
  if pValueType == val.INVALID_TYPE then
    return 123 -- invalid data type for template param
  end
  if pValueType == val.EMPTY_VALUE then
    return "" -- empty value for template param
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
  if pValueType == val.NEW then
    return {
      primaryColor = color
    }
  end
  if pValueType == val.CURRENT then
    return params.templateConfiguration[paramName]
  end
  if pValueType == val.MISSING_COLOR then
    color.blue = nil -- mandatory parameter missing
    return {
      primaryColor = color
    }
  end
  if pValueType == val.INVALID_TYPE then
    color.blue = "456" -- invalid data type for color param
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
  if not pWindowID then pWindowID = 0 end
  setParams(pTC, pWindowID)
  if pTC.status == "SUCCESS" then
    sendShow_SUCCESS()
  else
    sendShow_UNSUCCESS(pTC.status)
  end
end

local function setInitialState(pWindowID)
  id = 1
  sendShow(initial, pWindowID)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  common.Title("TC[" .. string.format("%03d", n) .. "/".. string.format("%03d", #testCases) .. "]")
  common.Title("Precondition")
  common.Step("Clean environment and Back-up/update PPT", common.precondition)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)

  common.Title("Test")
  common.Step("Set initial state", setInitialState)
  common.Step("App sends Show .." .. tc.status, sendShow, { tc })

  common.Title("Postconditions")
  common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
end
