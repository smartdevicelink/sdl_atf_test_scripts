--This script contains common functions that are used in many script.
--How to use:
--1. local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
--2. testCasesForPolicyTable:createPolicyTableWithoutAPI()
---------------------------------------------------------------------------------------------
config.defaultProtocolVersion = 2

local testCasesForPolicyTable = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local json = require('json')
local utils = require ('user_modules/utils')

--Policy template
local PolicyTableTemplate = "user_modules/shared_testcases/PolicyTables/DefaultPolicyTableWith_group1.json"

local PolicyTableTemplate2 = "user_modules/shared_testcases/PolicyTables/DefaultPolicyTableWith_group1_2.json"

--New policy table
local PolicyTable = "user_modules/shared_testcases/PolicyTables/TestingPolicyTable.json"

local APINameKeyWord = "APIName"
local appID = "0000001"
local defaultFunctionGroupName = "group1"

---------------------------------------------------------------------------------------------
------------------------------------------ Functions ----------------------------------------
---------------------------------------------------------------------------------------------
--List of group functions:
--1. createPolicyTableWithoutAPI
--2. createPolicyTable
--2b. createPolicyTableFile
--3. updatePolicy
--3a.updatePolicyInDifferentSessions
--4. userConsent
--5. updatePolicyAndAllowFunctionGroup
--6. flow_SUCCEESS_EXTERNAL_PROPRIETARY
--7. trigger_user_request_update_from_HMI
--8. trigger_getting_device_consent
--9. trigger_PTU_user_press_button_HMI
--10. Delete_Policy_table_snapshot
--11. AddApplicationToPTJsonFile
---------------------------------------------------------------------------------------------

--Create new policy table from a template without APIName
function testCasesForPolicyTable:createPolicyTableWithoutAPI(APIName)

  --New policy table with API
  PolicyTable = "user_modules/shared_testcases/PolicyTables/TestingPolicyTable192837465.json"

  -- Opens a file in read mode
  local file = io.open(PolicyTableTemplate, "r")

  -- Opens a file in write mode
  local file2 = io.open(PolicyTable, "w")

  --Rename API if it is exist
  while true do

    local line = file:read()
    if line == nil then break end

    if string.find(line, APIName) ~= nil then
      --rename API name if it is esist in template policy table
      line = string.gsub(line, APIName, APIName .. "1")
    end

    --Write line to new policy table
    file2:write(line)
  end

  file:close()
  file2:close()

  return PolicyTable
end

--Create new policy table from a template with API name and Hmi levels
function testCasesForPolicyTable:createPolicyTable(APIName, HmiLevels, keep_context, steal_focus, functionGroupName)

  if keep_context == nil then
    keep_context = false
  end
  if steal_focus == nil then
    steal_focus = false
  end

  if functionGroupName == nil then
    functionGroupName = defaultFunctionGroupName
  end

  local testCaseName = "CreatePolicyTable_AllowHmiLevels"
  for i = 1, #HmiLevels do
    testCaseName = testCaseName .. "_" .. HmiLevels[i]
  end

  testCaseName = testCaseName .. "_" .. "keep_context_is" .. tostring(keep_context) .. "_steal_focus_is" .. tostring(steal_focus)

  Test[testCaseName] = function(self)

    -- Opens a file in read mode
    local file = io.open(PolicyTableTemplate, "r")

    -- Opens a file in write mode
    local file2 = io.open(PolicyTable, "w")

    --Read policy table template and create new policy table with API name and HMI Levels
    while true do

      local line = file:read()
      if line == nil then break end

      line = string.gsub(line, defaultFunctionGroupName, functionGroupName)

      if string.find(line, APINameKeyWord) == nil then
        --rename API name if it is exist in template policy table
        line = string.gsub(line, APIName, APIName .. "1")

        --Write line to new policy table
        file2:write(line)

        if string.find(line, appID) ~= nil then
          --update keep_context and steal_focus
          line = "\t\t\t\t\"keep_context\" : " .. tostring(keep_context).. ",\n"
          file:read()
          file2:write(line)
          line = "\t\t\t\t\"steal_focus\" : " .. tostring(steal_focus).. ",\n"
          file:read()
          file2:write(line)

        end

      else

        --Update API name
        line = string.gsub(line, APINameKeyWord, APIName)
        file2:write(line)

        --Copy next line
        line = file:read()
        file2:write(line)

        --skip a next line (HMI Level)
        file:read()

        --Write HMI LEVELS
        if #HmiLevels >= 1 then
          for i = 1, #HmiLevels - 1 do
            line = "\t\t\t\t\t\t\t\"" .. HmiLevels[i] .. "\",\n"
            file2:write(line)
          end
          line = "\t\t\t\t\t\t\t\"" .. HmiLevels[#HmiLevels] .. "\"]\n"
          file2:write(line)
        else
          print("Error: HmiLevels should not be empty")
          break
        end

      end
    end

    file:close()
    file2:close()

    return true

  end

  return PolicyTable
end

--Use for adding permission for Base-4, group1, application (new function)
function testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, RenameAPIs)

  if RenameAPIs == nil then
    RenameAPIs = {}
  end

  local TestCaseName = "CreatePolicyTable"
  if PermissionLinesForBase4 ~= nil then TestCaseName = TestCaseName .. "_Add_APIs_To_Base4_Group" end
  if PermissionLinesForGroup1 ~= nil then TestCaseName = TestCaseName .. "_Add_APIs_To_group1_Group" end
  if PermissionLinesForApplication ~= nil then TestCaseName = TestCaseName .. "_Assign_Groups_To_App" end

  Test[TestCaseName] = function(self)

    -- Opens a file in read mode
    local file = io.open(PolicyTableTemplate2, "r")

    -- Opens a file in write mode
    local file2 = io.open(PolicyTable, "w")

    --1. Create PT with permission for group1 group
    if PermissionLinesForGroup1 ~= nil then
      while true do
        --look for '"user_consent_prompt" : "group1",' keyword and add permission for group1 group
        local keyword = '"user_consent_prompt" : "group1",'
        local line = file:read()
        if line == nil then break end

        --Write to new PT
        file2:write(line)

        if string.find(line, keyword) ~= nil then
          --Copy next line to new policy table
          line = file:read() --"rpcs" : {
          file2:write(line)

          --ignore next 4 lines
          file:read()
          file:read()
          file:read()
          file:read()

          --Add new APIs to new policy table
          file2:write(PermissionLinesForGroup1)
          break
        end
      end
    end

    --2. Create PT with permission for Base-4 group
    if PermissionLinesForBase4 ~= nil then
      --look for Base keyword and add permission for Base-4 group
      local keyword = '"Base'
      while true do
        local line = file:read()
        if line == nil then break end

        --Write to new PT
        file2:write(line)

        if string.find(line, keyword) ~= nil then
          --Copy next line to new policy table
          line = file:read() --"rpcs" : {
          file2:write(line)

          --Add new APIs to new policy table
          file2:write(PermissionLinesForBase4)
          break
        end
      end
    end

    --3. Create PT with permission for application
    if PermissionLinesForApplication ~= nil then
      --look for '"user_consent_prompt" : "group1",' keyword and add permission for group1 group
      local keyword = '"app_policies" : {'
      while true do

        local line = file:read()
        if line == nil then break end

        for j = 1, #RenameAPIs do
          if string.find(line, RenameAPIs[j]) ~= nil then
            --rename API name if it is esist in template policy table
            line = string.gsub(line, RenameAPIs[j], RenameAPIs[j] .. "_1")
          end
        end

        --Write to new PT
        file2:write(line)

        if string.find(line, keyword) ~= nil then

          --Add new APIs to new policy table
          file2:write(PermissionLinesForApplication)
          break
        end
      end
    end

    --4. Copy to the end of file
    while true do
      local line = file:read()
      if line == nil then break end

      for j = 1, #RenameAPIs do
        if string.find(line, RenameAPIs[j]) ~= nil then
          --rename API name if it is esist in template policy table
          line = string.gsub(line, RenameAPIs[j], RenameAPIs[j] .. "_1")
        end
      end

      --Write to new PT
      file2:write(line)
    end

    file:close()
    file2:close()
    return true
  end

  return PolicyTable
end

--Precondition: update policy with specified policy file, policy group name and return groupID of consent group.
function testCasesForPolicyTable:updatePolicy(PTName, iappID)

  Test["UpdatePolicy"] = function(self)

    if not iappID then
      iappID = self.applications[config.application1.registerAppInterfaceParams.appName]
    end

    --hmi side: sending SDL.GetPolicyConfigurationData request
    local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
        { policyType = "module_config", property = "endpoints" })

    --hmi side: expect SDL.GetPolicyConfigurationData response from HMI
    EXPECT_HMIRESPONSE(RequestIdGetURLS)
    :Do(function(_,_)
        --print("SDL.GetPolicyConfigurationData response is received")
        --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
        self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
          {
            requestType = "PROPRIETARY",
            fileName = "filename",
          }
        )
        --mobile side: expect OnSystemRequest notification
        EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function(_,_)
            --print("OnSystemRequest notification is received")
            --mobile side: sending SystemRequest request
            local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
              {
                fileName = "PolicyTableUpdate",
                requestType = "PROPRIETARY",
                appID = iappID
              },
              PTName)

            local systemRequestId
            --hmi side: expect SystemRequest request
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_,_data1)
                systemRequestId = _data1.id
                --print("BasicCommunication.SystemRequest is received")

                --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
                self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                  {
                    policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
                  }
                )
                local function to_run()
                  --hmi side: sending SystemRequest response
                  self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
                end

                RUN_AFTER(to_run, 500)
              end)

            --hmi side: expect SDL.OnStatusUpdate
            EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
            :ValidIf(function(exp,data)
                if
                exp.occurences == 1 and
                data.params.status == "UP_TO_DATE" then
                  return true
                elseif
                  exp.occurences == 1 and
                  data.params.status == "UPDATING" then
                    return true
                  elseif
                    exp.occurences == 2 and
                    data.params.status == "UP_TO_DATE" then
                      return true
                    else
                      if
                      exp.occurences == 1 then
                        print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
                      elseif exp.occurences == 2 then
                        print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
                      end
                      return false
                    end
                  end)
                :Times(Between(1,2))

                --mobile side: expect SystemRequest response
                EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
                :Do(function(_,_)
                    --print("SystemRequest is received")
                    --hmi side: sending SDL.GetUserFriendlyMessage request to SDL
                    local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})

                    --hmi side: expect SDL.GetUserFriendlyMessage response
                    --EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
                    -- textBody = "Up-To-Date" is not sent in SDL snapshot
                    EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
                  end)

              end)
          end)

    end
end

--! @brief Update Policy with specific session
--! @param PTName - file ptu
--! @param appName - name for registered app
--! @param mobile_session - session with registered app
function testCasesForPolicyTable:updatePolicyInDifferentSessions(self, PTName, appName, mobile_session)
    local iappID = self.applications[appName]
    --hmi side: sending SDL.GetPolicyConfigurationData request
    local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
        { policyType = "module_config", property = "endpoints" })

    --hmi side: expect SDL.GetPolicyConfigurationData response from HMI
    EXPECT_HMIRESPONSE(RequestIdGetURLS)
    :Do(function(_,_)
        --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
        self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
          {
            requestType = "PROPRIETARY",
            fileName = "filename",
          }
        )
        --mobile side: expect OnSystemRequest notification

        mobile_session:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function(_,_)
            --mobile side: sending SystemRequest request
            local CorIdSystemRequest = mobile_session:SendRPC("SystemRequest",
              {
                fileName = "PolicyTableUpdate",
                requestType = "PROPRIETARY",
                appID = iappID
              },
              PTName)

            local systemRequestId
            --hmi side: expect SystemRequest request
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_,_data1)
                systemRequestId = _data1.id
                --print("BasicCommunication.SystemRequest is received")

                --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
                self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                  {
                    policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
                  }
                )
                local function to_run()
                  --hmi side: sending SystemRequest response
                  self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
                end

                RUN_AFTER(to_run, 500)
              end)

            --hmi side: expect SDL.OnStatusUpdate
            EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
            :ValidIf(function(exp,data)
                if
                exp.occurences == 1  and
                  (data.params.status == "UP_TO_DATE" or data.params.status == "UPDATING"
                    or data.params.status == "UPDATE_NEEDED") then
                  return true
                  elseif
                    exp.occurences == 2 and
                    data.params.status == "UP_TO_DATE" then
                      return true
                    else
                      if
                      exp.occurences == 2 then
                        -- print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
                      -- elseif exp.occurences == 2 then
                      print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
                      return false
                    end
                    end
                  end)
                :Times(Between(1,2))

                --mobile side: expect SystemRequest response
                mobile_session:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
                :Do(function(_,_)
                    --hmi side: sending SDL.GetUserFriendlyMessage request to SDL
                    local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
                    --hmi side: expect SDL.GetUserFriendlyMessage response
                    EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
                  end)

              end)
          end)
end

    --Precondition: update policy with specified policy file on Genivi
function testCasesForPolicyTable:updatePolicyGenivi(self, PTName, iappID)
      -- Test["UpdatePolicy"] = function(self)

      if not iappID then
        iappID = self.applications[config.application1.registerAppInterfaceParams.appName]
      end

      --print("OnSystemRequest notification is received")
      --mobile side: sending SystemRequest request
      local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
        {
          fileName = "PolicyTableUpdate",
          requestType = "PROPRIETARY",
          appID = iappID
        },
        PTName)

      local systemRequestId
      --hmi side: expect SystemRequest request
      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function(_,data)
          systemRequestId = data.id
          --print("BasicCommunication.SystemRequest is received")

          --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
            {
              policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
            }
          )
          local function to_run()
            --hmi side: sending SystemRequest response
            self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
          end

          RUN_AFTER(to_run, 500)
        end)

      --hmi side: expect SDL.OnStatusUpdate
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
      :ValidIf(function(exp,data)
        if
          exp.occurences == 1 and
          data.params.status == "UP_TO_DATE" then
            return true
        elseif
            exp.occurences == 1 and
            data.params.status == "UPDATE_NEEDED" then
              return true
        elseif
              (exp.occurences == 1 or
                exp.occurences == 2 )and
              data.params.status == "UPDATING" then
                return true
        elseif
                (exp.occurences == 2 or
                  exp.occurences == 3) and
                data.params.status == "UP_TO_DATE" then
                  return true
        else
                  if
                  exp.occurences == 1 then
                    print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
                  elseif exp.occurences == 2 then
                    print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
                  elseif
                    exp.occurences == 3 then
                      print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in third occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
                  end
                  return false
        end
      end)
      :Times(Between(1,3))

              --mobile side: expect SystemRequest response
              EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
              :Do(function(_,_)
                  --print("SystemRequest is received")
                  --hmi side: sending SDL.GetUserFriendlyMessage request to SDL
                  local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})

                  --hmi side: expect SDL.GetUserFriendlyMessage response
                  EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
                end)

              -- end
end

            --User allowed or disallowed group policy
function testCasesForPolicyTable:userConsent(IsConsent, functionGroupName)
              Test["UserConsent_".. tostring(IsConsent)] = function(self)

                if functionGroupName == nil then
                  functionGroupName = defaultFunctionGroupName
                end

                --Get GetListOfPermissions
                --hmi side: sending SDL.GetListOfPermissions request to SDL
                local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})

                -- hmi side: expect SDL.GetListOfPermissions response
                --EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{name = functionGroupName}}}})
                EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions)
                :Do(function(_,data)

                    --Get groupID
                    local groupID
                    for i = 1, #data.result.allowedFunctions do
                      if data.result.allowedFunctions[i].name == functionGroupName then
                        groupID = data.result.allowedFunctions[i].id
                        break
                      end

                    end

                    if groupID == nil then
                      commonFunctions:printError("Error: userConsent function: function group name is not exist")
                    end

                    --hmi side: sending SDL.OnAppPermissionConsent
                    self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID = self.applications["Test Application"], consentedFunctions = {{ allowed = IsConsent, id = groupID, name = functionGroupName}}, source = "GUI"})

                    EXPECT_NOTIFICATION("OnPermissionsChange", {})
                  end)

              end
end

            --Print user consent group in policy table
function testCasesForPolicyTable:printUserConsent()
              Test["PrintUserConsent"] = function(self)

                local groupName = "group1"

                --Get GetListOfPermissions
                --hmi side: sending SDL.GetListOfPermissions request to SDL
                local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})

                -- hmi side: expect SDL.GetListOfPermissions response
                EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{name = groupName}}}})

              end
end

            --Verify DISALLOWED resultCode when API is not assigned to app
function testCasesForPolicyTable:checkPolicyWhenAPIIsNotExist(APIName)

              --Precondition: Build policy table file
              local PTName = testCasesForPolicyTable:createPolicyTableWithoutAPI(APIName)

              --Precondition: Update policy table
              testCasesForPolicyTable:updatePolicy(PTName)

              --Send request and check DISALLOWED resultCode
              Test[APIName .."_resultCode_DISALLOWED"] = function(self)

                --mobile side: sending the request
                local RequestParams = self.createRequest()
                local cid = self.mobileSession:SendRPC(APIName, RequestParams)

                --mobile side: expect response
                self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED"})

              end
end

            --Verify DISALLOWED resultCode when API is assigned to app but the group has not yet received user's consents.
            --Verify USER_DISALLOWED resultCode
function testCasesForPolicyTable:checkPolicyWhenUserDisallowed(HmiLevels, keep_context, steal_focus, APIName)

              --Case 1: Verify DISALLOWED resultCode when API is assigned to app but the group has not yet received user's consents.

              --Precondition: Build policy table file
              local PTName = testCasesForPolicyTable:createPolicyTable(APIName, HmiLevels, keep_context, steal_focus)

              --Precondition: Update policy table
              testCasesForPolicyTable:updatePolicy(PTName)

              --Send request and check DISALLOWED resultCode
              Test[APIName .."_resultCode_DISALLOWED"] = function(self)

                --mobile side: sending the request
                local RequestParams = self.createRequest()
                local cid = self.mobileSession:SendRPC(APIName, RequestParams)

                --mobile side: expect response
                self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED"})

              end

              --Case 2: Verify USER_DISALLOWED resultCode

              --Precondition: User does not allow function group
              testCasesForPolicyTable:userConsent(false)

              --Send request and check USER_DISALLOWED resultCode
              Test[APIName .."_resultCode_USER_DISALLOWED"] = function(self)
                --mobile side: sending the request
                local Request = self.createRequest()
                local cid = self.mobileSession:SendRPC(APIName, Request)

                --mobile side: expect response
                self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "USER_DISALLOWED"})
              end

              --Postcondition: User allows function group
              testCasesForPolicyTable:userConsent(true)
end

            --Update policy and user consent
function testCasesForPolicyTable:updatePolicyAndAllowFunctionGroup(HmiLevels, keep_context, steal_focus, consentGroup, APIName)

              if consentGroup == nil then
                consentGroup = defaultFunctionGroupName
              end

              --Precondition: Build policy table file
              local PTName = testCasesForPolicyTable:createPolicyTable(APIName, HmiLevels, keep_context, steal_focus, consentGroup)

              --Precondition: Update policy table
              testCasesForPolicyTable:updatePolicy(PTName)

              --Postcondition: User allows function group
              testCasesForPolicyTable:userConsent(true, consentGroup)
end

            --Update PT for precondition of each test case.
function testCasesForPolicyTable:precondition_updatePolicyAndAllowFunctionGroup(HmiLevels, keep_context, steal_focus)

              local consentGroupName = "group_precondition"

              testCasesForPolicyTable:updatePolicyAndAllowFunctionGroup(HmiLevels, keep_context, steal_focus, consentGroupName)

end

            --testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})
function testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves(HmiLevels, APIName)

              local temp = "\"" .. HmiLevels[1] .. "\""

              for i=2, #HmiLevels do
                temp = temp .. "," .. "\"" .. HmiLevels[i] .. "\""
              end

              local PermissionLines = "\""..APIName.. "\": { \"hmi_levels\": [" .. temp .. "]}"

              local PermissionLinesForBase4 = PermissionLines .. ",\n"
              local PermissionLinesForGroup1 = nil
              local PermissionLinesForApplication = nil
              local PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {APIName})
              testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)
end

function testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, RenameAPIs)

              if RenameAPIs == nil then
                RenameAPIs = {}
              end

              -- local TestCaseName = "CreatePolicyTable"
              -- if PermissionLinesForBase4 ~= nil then TestCaseName = TestCaseName .. "_Add_APIs_To_Base4_Group" end
              -- if PermissionLinesForGroup1 ~= nil then TestCaseName = TestCaseName .. "_Add_APIs_To_group1_Group" end
              -- if PermissionLinesForApplication ~= nil then TestCaseName = TestCaseName .. "_Assign_Groups_To_App" end

              -- Test[TestCaseName] = function(self)

              -- Opens a file in read mode
              local file = io.open(PolicyTableTemplate2, "r")

              -- Opens a file in write mode
              local file2 = io.open(PolicyTable, "w")

              --1. Create PT with permission for group1 group
              if PermissionLinesForGroup1 ~= nil then
                while true do
                  --look for '"user_consent_prompt" : "group1",' keyword and add permission for group1 group
                  local keyword = '"user_consent_prompt" : "group1",'
                  local line = file:read()
                  if line == nil then break end

                  --Write to new PT
                  file2:write(line)

                  if string.find(line, keyword) ~= nil then
                    --Copy next line to new policy table
                    line = file:read() --"rpcs" : {
                    file2:write(line)

                    --ignore next 4 lines
                    file:read()
                    file:read()
                    file:read()
                    file:read()

                    --Add new APIs to new policy table
                    file2:write(PermissionLinesForGroup1)
                    break
                  end
                end
              end

              --2. Create PT with permission for Base-4 group
              if PermissionLinesForBase4 ~= nil then
                --look for Base keyword and add permission for Base-4 group
                local keyword = '"Base'
                while true do
                  local line = file:read()
                  if line == nil then break end

                  --Write to new PT
                  file2:write(line)

                  if string.find(line, keyword) ~= nil then
                    --Copy next line to new policy table
                    line = file:read() --"rpcs" : {
                    file2:write(line)

                    --Add new APIs to new policy table
                    file2:write(PermissionLinesForBase4)
                    break
                  end
                end
              end

              --3. Create PT with permission for application
              if PermissionLinesForApplication ~= nil then
                --look for '"user_consent_prompt" : "group1",' keyword and add permission for group1 group
                local keyword = '"app_policies" : {'
                while true do

                  local line = file:read()
                  if line == nil then break end

                  for j = 1, #RenameAPIs do
                    if string.find(line, RenameAPIs[j]) ~= nil then
                      --rename API name if it is esist in template policy table
                      line = string.gsub(line, RenameAPIs[j], RenameAPIs[j] .. "_1")
                    end
                  end

                  --Write to new PT
                  file2:write(line)

                  if string.find(line, keyword) ~= nil then

                    --Add new APIs to new policy table
                    file2:write(PermissionLinesForApplication)
                    break
                  end
                end
              end

              --4. Copy to the end of file
              while true do
                local line = file:read()
                if line == nil then break end

                for j = 1, #RenameAPIs do
                  if string.find(line, RenameAPIs[j]) ~= nil then
                    --rename API name if it is esist in template policy table
                    line = string.gsub(line, RenameAPIs[j], RenameAPIs[j] .. "_1")
                  end
                end

                --Write to new PT
                file2:write(line)
              end

              file:close()
              file2:close()
              --return true
              --end

              return PolicyTable
end

function testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)

              local pt_fileName = "sdl_preloaded_pt.json"

              --Backup sdl_preloaded_pt.json file
              commonPreconditions:BackupFile(pt_fileName)

              --Copy new policy table to /sdl/bin folder
              local cmd = " cp -f " .. PTName .. " " .. commonPreconditions:GetPathToSDL() .. pt_fileName
              if not os.execute(cmd) then
                commonFunctions:printError("Preloaded was not updated")
              end

              --Delete policy table
              commonSteps:DeletePolicyTable()
            end

function testCasesForPolicyTable:Restore_preloaded_pt()

              Test["PostCondition_Restore_preloaded_pt"] = function(self)

                local pt_fileName = "sdl_preloaded_pt.json"
                commonPreconditions:RestoreFile(pt_fileName)
              end
end

----------------------------------------------------------------------------------------------------------------------------
-- The function is used only in case when PTU EXTERNAL_PROPRIETARY should have as result: UP_TO_DATE
-- The funcion will be used when PTU is triggered.
-- 1. It is assumed that notification is recevied: EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
-- 2. It is assumed that request/response is received: EXPECT_HMICALL("BasicCommunication.PolicyUpdate",
-- 3. Function will use default endpoints
-- Difference with PROPRIETARY flow is clarified in "Can you clarify is PTU flows for External_Proprietary and Proprietary have differences?"
-- But this should be checked in appropriate scripts
function testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self, app_id, device_id, hmi_app_id, ptu_file_path, ptu_file_name, ptu_file)
  if (app_id == nil) then app_id = config.application1.registerAppInterfaceParams.fullAppID end
  if (device_id == nil) then device_id = utils.getDeviceMAC() end
  if (hmi_app_id == nil) then hmi_app_id = self.applications[config.application1.registerAppInterfaceParams.appName] end
  if (ptu_file_path == nil) then ptu_file_path = "files/" end
  if (ptu_file_name == nil) then ptu_file_name = "PolicyTableUpdate" end
  if (ptu_file == nil) then ptu_file = "ptu.json" end
  --[[Start get data from PTS]]
  local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
  local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")

  -- Check SDL snapshot is created correctly and get needed data
  testCasesForPolicyTableSnapshot:verify_PTS(true, {app_id}, {device_id}, {hmi_app_id})

  local endpoints = {}
  for i = 1, #testCasesForPolicyTableSnapshot.pts_endpoints do
    if (testCasesForPolicyTableSnapshot.pts_endpoints[i].service == "0x07") then
      endpoints[1] = { url = testCasesForPolicyTableSnapshot.pts_endpoints[i].value, appID = nil}
    end
  end
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :ValidIf(function(e, d)
      if e.occurences == 1 and d.params.status == "UP_TO_DATE" then return true end
      local msg = table.concat({"Unexpected occurence '", e.occurences, "' of SDL.OnStatusUpdate with status '", d.params.status, "'"})
      return false, msg
    end)
  :Times(1)
  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(RequestId_GetUrls,{result = {code = 0, method = "SDL.GetPolicyConfigurationData" } } )
  :ValidIf(function(_,data)
      return commonFunctions:validateUrls(commonFunctions:getUrlsTableFromPtFile(), data)
    end)
  :Do(function(_,_)
    self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = "PROPRIETARY", fileName = SystemFilesPath .. pts_file_name})
    EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
    :Do(function(_, d2)
      if not (d2.binaryData ~= nil and string.len(d2.binaryData) > 0) then
        self:FailTestCase("PTS was not sent to Mobile in payload of OnSystemRequest")
      end
      local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = ptu_file_name, appID = app_id}, ptu_file_path..ptu_file)
      EXPECT_HMICALL("BasicCommunication.SystemRequest",{ requestType = "PROPRIETARY", fileName = SystemFilesPath..ptu_file_name })
      :Do(function(_,_data1)
        self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
        self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = SystemFilesPath..ptu_file_name})
      end)
      EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
      EXPECT_HMICALL("VehicleInfo.GetVehicleData", { odometer = true })
    end)
  end)
end

---------------------------------------------------------------------------------------------------------------------------
-- The function is used as trigger to PTU when user request update from HMI: SDL.OnPolicyUpdate
function testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
  local is_test_fail = false
  --function is created only for one app due to luck of time should not be updated at the moment.
  local hmi_app1_id = self.applications[config.application1.registerAppInterfaceParams.appName]
  testCasesForPolicyTable.time_trigger = 0
  testCasesForPolicyTable.time_onstatusupdate = 0
  testCasesForPolicyTable.time_policyupdate = 0

  self.hmiConnection:SendNotification("SDL.OnPolicyUpdate", {} )

  testCasesForPolicyTable.time_trigger = timestamp()

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
  :Do(function(_,_) testCasesForPolicyTable.time_onstatusupdate = timestamp() end)

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", { file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"})
  :Do(function(_,data)
    testCasesForPolicyTableSnapshot:verify_PTS(true,
    {config.application1.registerAppInterfaceParams.fullAppID },
    {utils.getDeviceMAC()},
    {hmi_app1_id})

    local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
    local seconds_between_retries = {}
    for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
      seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
      if(seconds_between_retries[i] ~= data.params.retry[i]) then
        commonFunctions:printError("Error: data.params.retry["..i.."]: "..data.params.retry[i] .."ms. Expected: "..seconds_between_retries[i].."ms")
        is_test_fail = true
      end
    end
    if(data.params.timeout ~= timeout_after_x_seconds) then
      commonFunctions:printError("Error: data.params.timeout = "..data.params.timeout.."ms. Expected: "..timeout_after_x_seconds.."ms.")
      is_test_fail = true
    end
    if(is_test_fail == true) then
      self:FailTestCase("Test is FAILED. See prints.")
    end
    testCasesForPolicyTable.time_policyupdate = timestamp()
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

---------------------------------------------------------------------------------------------------------------------------
-- The function is used as trigger to PTU when device is consented: SDL.OnSDLConsentNeeded
-- app_name: name of application that is activated on device
-- device_ID: ID of device that needs consent
-- This function is applicable ONLY for EXTENDED_PROPRIETARY flow.
function testCasesForPolicyTable:trigger_getting_device_consent(self, app_name, device_ID)
  local is_test_fail = false
  local hmi_app1_id = self.applications[config.application1.registerAppInterfaceParams.appName]
  testCasesForPolicyTable.time_trigger = 0
  testCasesForPolicyTable.time_onstatusupdate = 0
  testCasesForPolicyTable.time_policyupdate = 0

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[app_name]})

  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)

    local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
    --hmi side: expect SDL.GetUserFriendlyMessage message response
    EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
    :Do(function(_,_)
      testCasesForPolicyTable.time_trigger = timestamp()

      self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
        {allowed = true, source = "GUI", device = {id = device_ID, name = utils.getDeviceName(), isSDLAllowed = true}})
    end)

    EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"})
    :Do(function(_,data)
      testCasesForPolicyTableSnapshot:verify_PTS(true,
      {config.application1.registerAppInterfaceParams.fullAppID },
      {utils.getDeviceMAC()},
      {hmi_app1_id})

      local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
      local seconds_between_retries = {}
      for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
        seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
        if(seconds_between_retries[i] ~= data.params.retry[i]) then
          commonFunctions:printError("Error: data.params.retry["..i.."]: "..data.params.retry[i] .."ms. Expected: "..seconds_between_retries[i].."ms")
          is_test_fail = true
        end
      end
      if(data.params.timeout ~= timeout_after_x_seconds) then
        commonFunctions:printError("Error: data.params.timeout = "..data.params.timeout.."ms. Expected: "..timeout_after_x_seconds.."ms.")
        is_test_fail = true
      end
      if(is_test_fail == true) then
        self:FailTestCase("Test is FAILED. See prints.")
      end

      testCasesForPolicyTable.time_policyupdate = timestamp()
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATING" })
    end)
  end)
  EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(Between(0,1))
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

---------------------------------------------------------------------------------------------------------------------------
-- The function is used as trigger to PTU when user press button on HMI: SDL.UpdateSDL
-- executed_mode: for EXTERNAL_PROPRIETARY, notification for UPDATE_NEEDED should not be sent
function testCasesForPolicyTable:trigger_PTU_user_press_button_HMI(self, executed_mode)
  local is_test_fail
  local hmi_app1_id = self.applications[config.application1.registerAppInterfaceParams.appName]
  testCasesForPolicyTable.time_trigger = 0
  testCasesForPolicyTable.time_onstatusupdate = 0
  testCasesForPolicyTable.time_policyupdate = 0

  local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")
  EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})

  testCasesForPolicyTable.time_trigger = timestamp()

  if(executed_mode ~= "EXTERNAL_PROPRIETARY") then
    EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
    :Do(function(_,_) testCasesForPolicyTable.time_onstatusupdate = timestamp() end)
  end

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"})
  :Do(function(_,data)
    testCasesForPolicyTableSnapshot:verify_PTS(true,
      {config.application1.registerAppInterfaceParams.fullAppID },
      {utils.getDeviceMAC()},
      {hmi_app1_id})

    local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
    local seconds_between_retries = {}
    for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
      seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
      if(seconds_between_retries[i] ~= data.params.retry[i]) then
        commonFunctions:printError("Error: data.params.retry["..i.."]: "..data.params.retry[i] .."ms. Expected: "..seconds_between_retries[i].."ms")
        is_test_fail = true
      end
    end
    if(data.params.timeout ~= timeout_after_x_seconds) then
      commonFunctions:printError("Error: data.params.timeout = "..data.params.timeout.."ms. Expected: "..timeout_after_x_seconds.."ms.")
      is_test_fail = true
    end
    if(is_test_fail == true) then
      self:FailTestCase("Test is FAILED. See prints.")
    end
    testCasesForPolicyTable.time_policyupdate = timestamp()
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end


function testCasesForPolicyTable.Delete_Policy_table_snapshot()
  if( commonSteps:file_exists("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json") ~= false) then
    print("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json exists will be deleted!")
    os.execute("rm /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json")
  else
    print("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json does not exist")
  end
end
-----------------------------------------------------------------------------
--! @brief Add specific application to policy file
--! @param basic_file - basic json file which include all nessesary params. E.g. can be used files/json.lua
--! @param new_pt_file - file which will include new application
--! @param app_name - appID
--! @param app_ - parameters for appID
function testCasesForPolicyTable:AddApplicationToPTJsonFile(basic_file, new_pt_file, app_name, app_)
  local pt = io.open(basic_file, "r")
    if pt == nil then
      error("PTU file not found")
    end
  local pt_string = pt:read("*all")
  pt:close()

  local pt_table = json.decode(pt_string)
  pt_table["policy_table"]["app_policies"][app_name] = app_
  pt_table["policy_table"]["functional_groupings"]["DataConsent-2"]["rpcs"] =  json.null
  pt_json = json.encode(pt_table)
  local new_ptu = io.open(new_pt_file, "w")

  new_ptu:write(pt_json)
  new_ptu:close()
end

----------------------------------------------------------------------------------------------------------------------------
-- The function is used only in case when PTU HTTP should have as result: UP_TO_DATE
-- The funcion will be used when PTU is triggered.
-- 1. It is assumed that notification is recevied: EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status="UPDATE_NEEDED"})
-- 2. It is assumed that notification is recevied: EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "HTTP"})
-- 3. It is assumed that notification is recevied: EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status="UPDATING"})
function testCasesForPolicyTable:flow_PTU_SUCCEESS_HTTP (self)
  commonFunctions:check_ptu_sequence_partly(self, "files/ptu.json", "PolicyTableUpdate")
end

--! @brief Add specific application to policy file
--! @param basic_file - basic json file which include all nessesary params. E.g. can be used files/json.lua
--! @param new_pt_file - file which will include new application
--! @param app_name - appID
--! @param app_ - parameters for appID
function testCasesForPolicyTable:AddApplicationToPTJsonFile(basic_file, new_pt_file, app_name, app_)
  local pt = io.open(basic_file, "r")
    if pt == nil then
      error("PTU file not found")
    end
  local pt_string = pt:read("*all")
  pt:close()

  local pt_table = json.decode(pt_string)
  pt_table["policy_table"]["app_policies"][app_name] = app_
  -- Workaround. null value in lua table == not existing value. But in json file it has to be
  pt_table["policy_table"]["functional_groupings"]["DataConsent-2"]["rpcs"] = "tobedeletedinjsonfile"
  local pt_json = json.encode(pt_table)

  pt_json = string.gsub(pt_json, "\"tobedeletedinjsonfile\"", "null")
  local new_ptu = io.open(new_pt_file, "w")

  new_ptu:write(pt_json)
  new_ptu:close()
end

return testCasesForPolicyTable
