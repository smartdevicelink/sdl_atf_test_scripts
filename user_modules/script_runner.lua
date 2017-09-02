local Test = require('user_modules/dummy_connecttest')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

local isPrintTitle = false
local title
local runner = {}

Test.isTest = true

--[ATF]
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

local function addTestStep(testStepName, testStepImplFunction)
  testStepName = buildStepName(testStepName)
  testStepImplFunction = checkStepImplFunction(testStepImplFunction)
  Test[testStepName] = testStepImplFunction
end

local function extendedAddTestStep(testStepName, testStepImplFunction, paramsTable)
  local implFunctionsListWithParams = {}
  if isPrintTitle then
    table.insert(implFunctionsListWithParams, {implFunc = commonFunctions.userPrint, params = {0, 32, title, "\n"}})
    isPrintTitle = false
  end
  if not paramsTable then
    paramsTable = {}
  end
  table.insert(implFunctionsListWithParams, {implFunc = testStepImplFunction, params = paramsTable})
  local newTestStepImplFunction = function(self)
      for _, func in pairs(implFunctionsListWithParams) do
        table.insert(func.params, self)
        func.implFunc(unpack(func.params, 1, table.maxn(func.params)))
      end
    end
  addTestStep(testStepName, newTestStepImplFunction)
end

--[[ Title + Step approach]]
local function buildTitle(titleText)
  local maxLength = 101
  local filler = "-"
  local resultTable = {}
  for line in titleText:gmatch("[^\n]+") do
    local lineLength = #line
    if lineLength >= maxLength then
      table.insert(resultTable, line)
    else
      local tailLength = math.fmod(maxLength - lineLength, 2)
      local emtyLineSideLength = math.floor((maxLength - lineLength) / 2)
      table.insert(resultTable, filler:rep(emtyLineSideLength) .. line .. filler:rep(emtyLineSideLength + tailLength))
    end
  end
  return table.concat(resultTable, "\n")
end

function runner.Title(titleText)
  if isPrintTitle == true then
    title = title .. "\n" .. titleText
  else
    title = titleText
    isPrintTitle = true
  end
  title = buildTitle(title)
end

function runner.Step(testStepName, testStepImplFunction, paramsTable)
  extendedAddTestStep(testStepName, testStepImplFunction, paramsTable)
end

return runner
