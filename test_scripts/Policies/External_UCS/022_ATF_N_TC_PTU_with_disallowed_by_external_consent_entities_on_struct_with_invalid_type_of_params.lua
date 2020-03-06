---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] External UCS: PTU with "disallowed_by_external_consent_entities_on" struct with invalid type of params
--
-- Description:
-- In case:
-- SDL receives PolicyTableUpdate with “disallowed_by_external_consent_entities_on:
-- [entityType: <any_type_except_Integer>, entityId: <any_type_except_Integer>]”
-- -> of "<functional grouping>" -> from "functional_groupings" section
-- SDL must:
-- a. consider this PTU as invalid
-- b. do not merge this invalid PTU to LocalPT.
--
-- Steps:
-- 1. Register app
-- 2. Activate app
-- 3. Perform PTU (make sure 'disallowed_by_external_consent_entities_on' section is defined
-- with invalid parameters)
-- 4. Verify status of update
--
-- Expected result:
-- PTU fails with UPDATE_NEEDED status
--
-- Note: Script is designed for EXTERNAL_PROPRIETARY flow
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForExternalUCS = require('user_modules/shared_testcases/testCasesForExternalUCS')
local sdl = require('SDL')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')

--[[ Local variables ]]
local grpId = "Location-1"
local checkedStatus = "UPDATE_NEEDED"
local checkedSection = "disallowed_by_external_consent_entities_on"

local params = { "entityId", "entityType" }
local values = {
  { v = "1", desc = "String" },
  { v = 1.23, desc = "Float" },
  { v = {}, desc = "Empty table" },
  { v = { entityType = 1, entityID = 1 }, desc = "Non-empty table" },
  { v = -1, desc = "Below Min" },
  { v = 129, desc = "Beyond Max" },
  { v = "", desc = "Blank" },
  { v = nil, desc = "Null" }
}

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForExternalUCS.removePTS()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:CheckSDLStatus()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.RUNNING)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

local n = 1
local startLine = 1

local function sequence(desc, updateFunc)

  local tcName = "TC[" .. string.format("%02d", n) .. "] - [" .. desc .. "] "
  tcName = tcName .. string.rep("-", 50 - string.len(tcName))

  Test[tcName] = function() end

  function Test.StopSDL()
    StopSDL()
    commonTestCases:DelayedExp(3000)
  end

  function Test:CheckSDLStatus()
    testCasesForExternalUCS.checkSDLStatus(self, sdl.STOPPED)
  end

  function Test.RemoveLPT()
    testCasesForExternalUCS.removeLPT()
  end

  function Test.StartSDL()
    StartSDL(config.pathToSDL, config.ExitOnCrash)
    os.execute("sleep 5")
  end

  function Test:CheckSDLStatus()
    testCasesForExternalUCS.checkSDLStatus(self, sdl.RUNNING)
  end

  function Test:InitHMI()
    self:initHMI()
  end

  function Test:InitHMI_onReady()
    self:initHMI_onReady()
  end

  function Test:ConnectMobile()
    self:connectMobile()
  end

  function Test:StartSession()
    testCasesForExternalUCS.startSession(self, 1)
  end

  function Test:RAI()
    testCasesForExternalUCS.registerApp(self, 1)
  end

  function Test:ActivateApp()
    testCasesForExternalUCS.activateApp(self, 1, checkedStatus, updateFunc)
  end

  function Test:CheckStatus_UPDATE_NEEDED()
    local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
    EXPECT_HMIRESPONSE(reqId, { status = checkedStatus })
  end

  function Test:CheckLog()
    local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not valid", startLine)
    if result ~= true then
      self:FailTestCase("Error message was not found in log file")
    end
    startLine = testCasesForPolicySDLErrorsStops.GetCountOfRows()
  end

  n = n + 1

end

local desc
local updateFunc

-- TCs: invalid values for one of parameters
for p = 1, #params do
  for i = 1, #values do
    desc = params[p] .. ": " .. values[i].desc
    updateFunc = function(pts)
      local function getParamValue(paramName)
        if paramName == params[p] then
          return values[i].v
        else
          return 1
        end
      end
      local function logParamValue(paramName)
        print(paramName .. ": '" .. tostring(getParamValue(paramName)) .. "'")
      end
      logParamValue("entityId")
      logParamValue("entityType")
      pts.policy_table.functional_groupings[grpId][checkedSection] = {
        {
          entityID = getParamValue("entityId"),
          entityType = getParamValue("entityType"),
        }
      }
    end
    sequence(desc, updateFunc)
  end
end

-- TC: both parameters = nil
desc = "Both parameters = nil"
updateFunc = function(pts)
  pts.policy_table.functional_groupings[grpId][checkedSection] = {
    {
      entityID = nil,
      entityType = nil
    }
  }
end
sequence(desc, updateFunc)

-- TC: Count of elements > 100
desc = "Max count of elements"
updateFunc = function(pts)
  pts.policy_table.functional_groupings[grpId][checkedSection] = { }
  local maxCount = 100
  for i = 1, maxCount + 1 do
    local element = {
      entityID = i,
      entityType = maxCount + 2 - i
    }
    table.insert(pts.policy_table.functional_groupings[grpId][checkedSection], element)
  end
end
sequence(desc, updateFunc)

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.StopSDL()
  StopSDL()
end

return Test
