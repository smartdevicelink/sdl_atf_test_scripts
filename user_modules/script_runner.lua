local Test = require('user_modules/dummy_connecttest')
local testSettings = require('user_modules/test_settings')
local consts = require('user_modules/consts')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

local isInitialStep = true
local idx = 1
local skipReason = nil

local runner = {}

runner.testSettings = testSettings

Test.isTest = true
Test.caseTitles = { }

--[Utils]
local function existsInList (pList, pValue)
  for _, value in pairs(pList) do
    if value == pValue then
      return true
    end
  end
  return false
end

--[ATF]
local function buildTitle(titleText)
  local maxLength = 96
  local filler = "-"
  local resultTable = {}
  for line in titleText:gmatch("[^\n]+") do
    if line:len() >= maxLength then
      line = line:sub(1, maxLength - 1)
    end
    table.insert(resultTable, "--- " .. line .. " " .. filler:rep(maxLength - line:len(line)))
  end
  return table.concat(resultTable, "\n")
end

local function buildStepName(testStepName)
  if type(testStepName) == "string" and testStepName ~= "" then
    testStepName = testStepName:gsub("%W", "_")
    while testStepName:match("^[%d_]") do
      if #testStepName == 1 then
        return error("Test step name is incorrect!")
      end
      testStepName = testStepName:sub(2)
    end
    if testStepName:match("^%l") then
        testStepName = testStepName:sub(1, 1):upper() .. testStepName:sub(2)
    end
    return testStepName
  elseif type(testStepName) == "number" then
    return "Test_step_" .. testStepName
  else
    return error("Test step name is missing!")
  end
end

local function checkStepImplFunction(testStepImplFunction)
  if type(testStepImplFunction) == "function" then
    return testStepImplFunction
  else
    return error("Test step function is not specified!")
  end
end

local function extendedAddTestStep(testStepName, testStepImplFunction, paramsTable)
  testStepName = buildStepName(testStepName)
  local implFunctionsListWithParams = {}
  if not paramsTable then
    paramsTable = {}
  end
  table.insert(implFunctionsListWithParams, {implFunc = testStepImplFunction, params = paramsTable})
  local newTestStepImplFunction = function(self)
      for _, func in pairs(implFunctionsListWithParams) do
        if runner.testSettings.isSelfIncluded == true then
          table.insert(func.params, self)
        end
        func.implFunc(unpack(func.params, 1, table.maxn(func.params)))
      end
    end
  Test[testStepName] = checkStepImplFunction(newTestStepImplFunction)
end

local function isTestApplicable(testApplicableSdlSettings)
  if next(testApplicableSdlSettings) == nil then
   return true
  end
  local isMatched = true
  for _, sdlSettingsSet in pairs(testApplicableSdlSettings) do
    for sdlSettingsItem, listOfValuesForItem in pairs(sdlSettingsSet) do
      local sdlBuildOptionValue = Test.sdlBuildOptions[sdlSettingsItem]
      if sdlBuildOptionValue then
        if not existsInList(listOfValuesForItem, sdlBuildOptionValue) then
          isMatched = false
          break
        end
      else
        isMatched = false
        break
      end
    end
    if isMatched then
      return true
    end
    isMatched = true
  end
  return false
end

local function skipTest(reason)
  Test.caseTitles[idx] = nil
  Test.caseTitles[idx] = {}
  runner.Title("TEST SKIPPED")
  runner.Step(
      "Skip reason",
      function(skipRsn)
        commonFunctions:userPrint(consts.color.cyan, skipRsn)
        Test:SkipTest()
      end,
      { reason }
    )
end

local function prepareDescription(text, maxLength)
  if text:find("\n") or text:len() >= maxLength then
    return "\n" .. text
  end
  return text
end

local function printTestInformation()
  local maxLength = 101
  local filler = "="
  print(filler:rep(maxLength) ..
      "\nDescription: " ..
      prepareDescription(runner.testSettings.description, maxLength - string.len("Description")) ..
      "\nSeverity: " .. runner.testSettings.severity .. "\n" ..
      filler:rep(maxLength))
end

--[[ Title + Step approach]]
function runner.Title(titleText)
  if Test.caseTitles[idx] == nil then
    Test.caseTitles[idx] = {}
  end
  table.insert(Test.caseTitles[idx], buildTitle(titleText))
end

function runner.Step(testStepName, testStepImplFunction, paramsTable)
  local maxLength = 101
  local filler = "="
  if isInitialStep then
    printTestInformation()
    if skipReason ~= nil then
      isInitialStep = false
      skipTest(skipReason)
    elseif not isTestApplicable(runner.testSettings.restrictions.sdlBuildOptions) then
      local message = "Test is incompatible with current build configuration of SDL:\n" ..
          commonFunctions:convertTableToString(Test.sdlBuildOptions, 1) ..
          "\n\nTest is possible to run with SDL that was built with next build options:\n" ..
          commonFunctions:convertTableToString(runner.testSettings.restrictions.sdlBuildOptions, 1) .. "\n" ..
          filler:rep(maxLength)
      isInitialStep = false
      skipTest(message)
    else
      extendedAddTestStep(testStepName, testStepImplFunction, paramsTable)
      isInitialStep = false
    end
  else
    extendedAddTestStep(testStepName, testStepImplFunction, paramsTable)
  end
  idx = idx + 1
end

function runner.skipTest(message)
  skipReason = message
end

function runner.isTestApplicable(pSdlBuildOptions)
  runner.testSettings.restrictions.sdlBuildOptions = pSdlBuildOptions
  runner.Step("Check SDL policy mode", function() end)
end

return runner
