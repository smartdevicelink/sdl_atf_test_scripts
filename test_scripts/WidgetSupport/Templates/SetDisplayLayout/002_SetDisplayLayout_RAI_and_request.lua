---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL proceed with "SetDisplayLayout" RPC according to req-ts
-- in case if color schemes have been defined during app registration
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered (color schemes are defined)
-- Steps:
-- 1) App sends "SetDisplayLayout" request with different parameters
-- SDL does:
--  - Proceed with request successfully or not (depending on parameters)
-- Note: since "SetDisplayLayout" is deprecated SDL has to respond with WARNINGS to mobile in success case
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

local initial = { layout = values.MISSING, day = values.NEW, night = values.NEW }
local testCases = {
  [001] = { layout = values.NEW,     day = values.NEW,     night = values.NEW,     status = "SUCCESS" },
  [002] = { layout = values.NEW,     day = values.CURRENT, night = values.CURRENT, status = "SUCCESS" },
  [003] = { layout = values.NEW,     day = values.NEW,     night = values.CURRENT, status = "SUCCESS" },
  [004] = { layout = values.NEW,     day = values.CURRENT, night = values.NEW,     status = "SUCCESS" },
  [005] = { layout = values.NEW,     day = values.MISSING, night = values.MISSING, status = "SUCCESS" },
  [006] = { layout = values.NEW,     day = values.NEW,     night = values.MISSING, status = "SUCCESS" },
  [007] = { layout = values.NEW,     day = values.MISSING, night = values.NEW,     status = "SUCCESS" },
  [008] = { layout = values.NEW,     day = values.INVALID, night = values.INVALID, status = "INVALID_DATA" },
  [009] = { layout = values.NEW,     day = values.NEW,     night = values.INVALID, status = "INVALID_DATA" },
  [010] = { layout = values.NEW,     day = values.INVALID, night = values.NEW,     status = "INVALID_DATA" },
}

local id
local params = { }

local schemaTypes = {
  DAY = "day",
  NIGHT = "night"
}

--[[ Local Functions ]]
local function getLayout(pValueType)
  if pValueType == values.NEW then
    return "Layout" .. id
  end
  if pValueType == values.CURRENT then
    return params.displayLayout
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
    return params[paramName]
  end
  if pValueType == values.INVALID then
    color.blue = nil -- mandatory parameter missing
    return {
      primaryColor = color
    }
  end
  return nil
end

local function setParams(pTC)
  params = {
    displayLayout = getLayout(pTC.layout),
    dayColorScheme = getColorScheme(schemaTypes.DAY, pTC.day),
    nightColorScheme = getColorScheme(schemaTypes.NIGHT, pTC.night)
  }
  id = id + 1
end

local function sendSetDisplayLayout_SUCCESS()
  local cid = common.getMobileSession():SendRPC("SetDisplayLayout", params)
  common.getHMIConnection():ExpectRequest("UI.SetDisplayLayout", params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS" })
end

local function sendSetDisplayLayout_UNSUCCESS(pResultCode)
  local cid = common.getMobileSession():SendRPC("SetDisplayLayout", params)
  common.getHMIConnection():ExpectRequest("UI.SetDisplayLayout")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode })
end

local function sendSetDisplayLayout(pTC)
  setParams(pTC)
  if pTC.status == "SUCCESS" then
    sendSetDisplayLayout_SUCCESS()
  else
    sendSetDisplayLayout_UNSUCCESS(pTC.status)
  end
end

local function setInitialState()
  id = 1
  setParams(initial)
  local appParams = common.getConfigAppParams()
  appParams.dayColorScheme = params.dayColorScheme
  appParams.nightColorScheme = params.nightColorScheme
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  common.Title("TC[" .. string.format("%03d", n) .. "/".. string.format("%03d", #testCases) .. "]")
  common.Title("Precondition")
  common.Step("Clean environment and Back-up/update PPT", common.precondition)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Set initial state", setInitialState)
  common.Step("App registration", common.registerAppWOPTU)

  common.Title("Test")
  common.Step("App sends SetDisplayLayout .." .. tc.status, sendSetDisplayLayout, { tc })

  common.Title("Postconditions")
  common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
end
