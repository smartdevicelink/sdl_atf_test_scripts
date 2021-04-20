-------------------------------------------------------------------------------------------------
-------------------------------------------Updates of files -------------------------------------
-------------------------------------------------------------------------------------------------
print("")
print ("\27[31m !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \27[0m")
print ("\27[31m !!!!!!!!!!!!!!! Update of files sdl_preloaded_pt.json before start of SDL !!!!!!!!!!!!!!! \27[0m")
print ("\27[31m !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \27[0m")
print("")
  local commonSteps   = require('user_modules/shared_testcases/commonSteps')
  local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

  
function DeleteLog_app_info_dat_policy()
    commonSteps:CheckSDLPath()
    local SDLStoragePath = config.pathToSDL .. "storage/"

    --Delete app_info.dat and log files and storage
    if commonSteps:file_exists(config.pathToSDL .. "app_info.dat") == true then
      os.remove(config.pathToSDL .. "app_info.dat")
    end

    if commonSteps:file_exists(config.pathToSDL .. "SmartDeviceLinkCore.log") == true then
      os.remove(config.pathToSDL .. "SmartDeviceLinkCore.log")
    end

    if commonSteps:file_exists(SDLStoragePath .. "policy.sqlite") == true then
      os.remove(SDLStoragePath .. "policy.sqlite")
    end

    if commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true then
      os.remove(config.pathToSDL .. "policy.sqlite")
    end
print("path = " .."rm -r " ..config.pathToSDL .. "storage")
    os.execute("rm -r " ..config.pathToSDL .. "storage")
end

DeleteLog_app_info_dat_policy()

----------------------------------------------------------------------------------------------
-- make reserve copy of file (FileName) in specified folder
local function BackupSpecificFile(FileFolder , FileName)
    os.execute(" cp " .. FileFolder .. FileName .. " " .. FileFolder .. FileName .. "_origin" )
end

-- restore origin of file (FileName) in specified folder
local function RestoreSpecificFile(FileFolder, FileName)
  os.execute(" cp " .. FileFolder .. FileName .. "_origin " .. FileFolder .. FileName )
    os.execute( " rm -f " .. FileFolder .. FileName .. "_origin" )
end


--UPDATED: For each rpc that will be verified in test check and update BASE4 Group of sdl_preloaded_pt.json in bin of SDL
function UpdatePolicy()
    commonPreconditions:BackupFile("sdl_preloaded_pt.json")

    local src_preloaded_json = config.pathToSDL .."sdl_preloaded_pt.json"
    local dest               = "user_modules/shared_testcases/PolicyTables/PolicyTable_All_RPCs.json"
    
    local filecopy = "cp " .. dest .."  " .. src_preloaded_json

    os.execute(filecopy)
end

UpdatePolicy()

function CopyConfigurationFiles()
    local str_print
    -- backup initial sdl_preloaded_pt.json and copy the one from SDL build directory

    local src_preloaded_json = config.pathToSDL .."sdl_preloaded_pt.json"
    local dest               = "files/sdl_preloaded_pt.json"
    local dirPath            = "files/"
    local filecopy = "cp " .. src_preloaded_json .."  " .. dest

    if (commonSteps:file_exists(dest) == true) then
        print("\27[33m File " ..dest .. " exists \27[0m")
        FileExist_PreloadedPT = true
        BackupSpecificFile(dirPath, "sdl_preloaded_pt.json")
    else
        print("\27[33m File " ..dest .. " doesn't exist \27[0m")
    end
    
    os.execute(filecopy)
end
CopyConfigurationFiles()
-------------------------------------------------------------------------------------------------
-------------------------------------------END Updates of files ---------------------------------
-------------------------------------------------------------------------------------------------


Test = require('connecttest')
require('cardinalities')
local hmi_connection = require('hmi_connection')
local websocket      = require('websocket_connection')
local module         = require('testbase')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local RPC_ResponseTimeout = 10000

local iTimeout = 5000



config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local storagePath  = config.pathToSDL .. "storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"

local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
end

local FileExist_PreloadedPT = false


local function RestartSDL_ActivateApp()

    function Test:Precondition_StopSDL()
        print("")
        print ("\27[31m !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \27[0m")
        print ("\27[31m !!!!!!!!!!!!!!!!!!!!!!!!! Restart SDL and load new policy!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \27[0m")
        print ("\27[31m !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \27[0m")
        print("")
        StopSDL()
    end

    local function DeleteSDLFiles()
        
        local SDLStoragePath = config.pathToSDL .. "storage/"
        
        --Delete app_info.dat and log files and storage
        if commonSteps:file_exists(config.pathToSDL .. "app_info.dat") == true then
            os.remove(config.pathToSDL .. "app_info.dat")
        end

        
        if commonSteps:file_exists(SDLStoragePath .. "policy.sqlite") == true then
            os.remove(SDLStoragePath .. "policy.sqlite")
        end

        if commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true then
            os.remove(config.pathToSDL .. "policy.sqlite")
        end
    end
    function Test:Precondition_UpdatePolicy()
        DeleteSDLFiles()
    end

    function Test:Precondition_LoadNewPolicy()
        local src_preloaded_json = config.pathToSDL .."sdl_preloaded_pt.json"
        local dest               = "user_modules/shared_testcases/PolicyTables/PolicyTable_All_RPCs_1.json"
    
        local filecopy = "cp " .. dest .."  " .. src_preloaded_json

        os.execute(filecopy)
    end

    function Test:Precondition_StartSDL()
        StartSDL(config.pathToSDL, config.ExitOnCrash)
    end

    function Test:Precondition_InitHMI()  
        self:initHMI()
    end

    function Test:Precondition_InitHMI_onReady()
        self:initHMI_onReady()
    end

    function Test:Precondition_ConnectMobile()
        self:connectMobile()
    end

    function Test:Precondition_StartSession()
        self.mobileSession = mobile_session.MobileSession( self, self.mobileConnection)
        self.mobileSession:StartService(7)
    end
    
    function Test:RegisterAppInterface()
        local app_ID
        --mobile side: RegisterAppInterface request
        local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
        {
          syncMsgVersion =
                          {
                          majorVersion = 2,
                          minorVersion = 2,
                          },
          appName ="SyncProxyTester",
          ttsName ={
                       {
                        text ="SyncProxyTester",
                        type ="TEXT",
                        },
                    },
          ngnMediaScreenAppName ="SPT",
          vrSynonyms =
                      {
                       "VRSyncProxyTester",
                      },
          isMediaApplication = true,
          languageDesired ="EN-US",
          hmiDisplayLanguageDesired ="EN-US",
          appHMIType =
                      {
                       "NAVIGATION",
                      },
          appID ="12345",
          deviceInfo =
                      {
                        hardware = "hardware",
                        firmwareRev = "firmwareRev",
                        os = "os",
                        osVersion = "osVersion",
                        carrier = "carrier",
                        maxNumberRFCOMMPorts = 5
                      }

        })


          --hmi side: expected  BasicCommunication.OnAppRegistered
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
                        {
                            application =
                            {
                              appName = "SyncProxyTester",
                              ngnMediaScreenAppName ="SPT",
                              --ToDo: Shall be uncommented when APPLINK-16052 "ATF: TC is failed in case receiving message with nested struct" is fixed
                              --UPDATED
                              -- deviceInfo = 
                              -- {
                              --     transportType = "WIFI",
                              --     isSDLAllowed = true,
                              --     id = config.deviceMAC,
                              --     name = "127.0.0.1"
                              -- },
                              -- deviceInfo =
                              -- {
                              --   hardware = "hardware",
                              --   firmwareRev = "firmwareRev",
                              --   os = "os",
                              --   osVersion = "osVersion",
                              --   carrier = "carrier",
                              --   maxNumberRFCOMMPorts = 5
                              -- },
                              policyAppID = "12345",
                              hmiDisplayLanguageDesired ="EN-US",
                              isMediaApplication = true,
                              --UPDATED
                              --appHMIType =
                              appType = 
                              {
                                  "NAVIGATION"
                              },
                            },
                            ttsName =
                    {

                      {
                        text ="SyncProxyTester",
                        type ="TEXT",
                      }
                    },
                    vrSynonyms =
                    {
                      "VRSyncProxyTester",
                    }
                        })
          -- Set self.applications["SyncProxyTester"] variable
          :Do(function(_,data)
            
            app_ID = data.params.application.appID
            self.applications["SyncProxyTester"] = data.params.application.appID
            print ("self.applications[SyncProxyTester] = " .. app_ID)
            
            local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = app_ID } )
                      
                      EXPECT_HMIRESPONSE(RequestId)
          end)
--print ("2: self.applications[SyncProxyTester1] = " .. app_ID)
          --mobile side: RegisterAppInterface response
          -- EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
          --     :Timeout(2000)
          --         :Do(function(_,data)
          --           if(self.applications["SyncProxyTester1"] ~= nil) then
          --             print ("self.applications[SyncProxyTester1] = " .. self.applications["SyncProxyTester1"])
          --           else
          --             print("App id is empty!!!!!!!!!!!!!!!")
          --           end
          --             local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = app_ID } )
                      
          --             EXPECT_HMIRESPONSE(RequestId)
          --         end)
    end


end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
function Test:Activation()
  
  EXPECT_NOTIFICATION("OnHMIStatus")
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)

end
--End Precondition.1

  -----------------------------------------------------------------------------------------

  --Begin Precondition.2
  --Description: Putting file(PutFiles)
    function Test:PutFile_Precondition()
      local cid = self.mobileSession:SendRPC("PutFile",
      {
        syncFileName = "action.png",
        fileType  = "GRAPHIC_PNG",
        persistentFile = false,
        systemFile = false
      }, "files/action.png")
      EXPECT_RESPONSE(cid, { success = true})
    end
  --End Precondition.2

  -----------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
-------------------All_RPSs_and_Notifications: script sends all RPS, ------------------------
-------------------gets corresponding responses, sends all notifications --------------------
-------------------for checking correct SDL logging according to APPLINK-12699 --------------
---------------------------------------------------------------------------------------------

  --Begin Test suit All_RPSs_and_Responses
  --Description:
    -- in script sends all RPS, gets corresponding responses for checking correct SDL logging according to APPLINK-12699


  --Begin Test case All_RPSs_and_Responses.1
  --Description: Send RPCs with all parameters, positive scenarios


function Test:SetGlobalProperties()
    print ("-----Requests and Responses-------")
      --mobile side: sending SetGlobalProperties request
     
      local cid = self.mobileSession:SendRPC("SetGlobalProperties",
      {
        menuTitle = "Menu Title",
        timeoutPrompt =
        {
          {
            text = "Timeout prompt",
            type = "TEXT"
          }
        },
        vrHelp =
        {
          {
            position = 1,
            image =
            {
              value = "action.png",
              imageType = "DYNAMIC"
            },
            text = "VR help item"
          }
        },
        menuIcon =
        {
          value = "action.png",
          imageType = "DYNAMIC"
        },
        helpPrompt =
        {
          {
            text = "Help prompt",
            type = "TEXT"
          }
        },
        vrHelpTitle = "VR help title",
        keyboardProperties =
        {
          keyboardLayout = "QWERTY",
          keypressMode = "SINGLE_KEYPRESS",
          limitedCharacterList =
          {
          "a", "b", "c"
          },
          language = "EN-US",
          autoCompleteText = "Daemon, Freedom"
        }
        
      })


      --hmi side: expect TTS.SetGlobalProperties request
      EXPECT_HMICALL("TTS.SetGlobalProperties",
      {
        timeoutPrompt =
        {
          {
            text = "Timeout prompt",
            type = "TEXT"
          }
        },
        helpPrompt =
        {
          {
            text = "Help prompt",
            type = "TEXT"
          }
        }
      })
      :Do(function(_,data)
        --hmi side: sending UI.SetGlobalProperties response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

      --hmi side: expect UI.SetGlobalProperties request

      EXPECT_HMICALL("UI.SetGlobalProperties",
      {
        menuTitle = "Menu Title",
        vrHelp =
        {
          {
            position = 1,
            --ToDo: Shall be uncommented when APPLINK-16052 "ATF: TC is failed in case receiving message with nested struct" is fixed
            --image =
            --{
            --  imageType = "DYNAMIC",
            --  value = storagePath .. "action.png"
            --},
            text = "VR help item"
          }
        },
        -- menuIcon =
        -- {
        --     imageType = "DYNAMIC",
        --     value = storagePath .. "action.png"
        -- },
        vrHelpTitle = "VR help title",
        keyboardProperties =
        {
          keyboardLayout = "QWERTY",
          keypressMode = "SINGLE_KEYPRESS",
          --ToDo: Shall be uncommented when APPLINK-16047 "ATF: Wrong validation of some arrays" is fixed.
          --limitedCharacterList =
          --{
          --   "a", "b", "c"
          --},
          language = "EN-US",
          autoCompleteText = "Daemon, Freedom",
        },
        -- UPDATED: added appID check
        appID = self.applications["Test Application"]
      })
      :ValidIf(function(_,data)
          local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
          local value_menuIcon = path .. "action.png"
          
          if(data.params.menuIcon.imageType == "DYNAMIC") then
              return true
          else
              print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.menuIcon.imageType .. "\27[0m")
              return false
          end

          if(string.find(data.params.menuIcon.value, value_menuIcon) ) then
                  return true
              else
                  print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_menuIcon .. "; Real: " .. data.params.menuIcon.value .. "\27[0m")
                  return false
              end
      end)
      :Timeout(iTimeout)
      :Do(function(_,data)
        --hmi side: sending UI.SetGlobalProperties response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

      --mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
    end

  --End Test case
  ---------------------------------------------------------------------------------------


function Test:ResetGlobalProperties()

          --mobile side: sending ResetGlobalProperties request
          local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
          {
            properties =
            {
              "VRHELPTITLE",
              "MENUNAME",
              "MENUICON",
              "KEYBOARDPROPERTIES",
              "VRHELPITEMS",
              "HELPPROMPT",
              "TIMEOUTPROMPT"
            }
          })
          --hmi side: expect TTS.SetGlobalProperties request
          EXPECT_HMICALL("TTS.SetGlobalProperties",
          {
            timeoutPrompt =
            {
              {
                type = "TEXT",
                text = "Please speak one of the following commands,"
              },
              {
                type = "TEXT",
                text = "Please say a command,"
              }
            }
          })
          :Timeout(iTimeout)
          :Do(function(_,data)
            --hmi side: sending TTS.SetGlobalProperties response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --hmi side: expect UI.SetGlobalProperties request
          EXPECT_HMICALL("UI.SetGlobalProperties",
          {
            menuTitle = "",
            vrHelpTitle = "Test Application",
            keyboardProperties =
            {
              keyboardLayout = "QWERTY",
              autoCompleteText = "",
              language = "EN-US"
            }
          })

          :Do(function(_,data)
            --hmi side: sending UI.SetGlobalProperties response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)



          --mobile side: expect SetGlobalProperties response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end

      --End Test case
      ---------------------------------------------------------------------------------------

      function Test:AddCommand()
      --mobile side: sending AddCommand request
      local cid = self.mobileSession:SendRPC("AddCommand",
      {
        cmdID = 1,
        menuParams =
        {
          position = 0,
          menuName ="Command"
        },
          vrCommands =
              {
                "VRCommandonepositive"
              }
      })

      --hmi side: expect UI.AddCommand request
      EXPECT_HMICALL("UI.AddCommand",
      {
        cmdID = 1,
        menuParams =
        {
          position = 0,
          menuName ="Command"
        }
      })
      :Do(function(_,data)
        --hmi side: sending UI.AddCommand response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

      --hmi side: expect VR.AddCommand request
          EXPECT_HMICALL("VR.AddCommand",
                  {
                    cmdID = 1,
                    type = "Command",
                    vrCommands =
                    {
                      "VRCommandonepositive"
                    }
                  })
          :Do(function(_,data)
            --hmi side: sending VR.AddCommand response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

      --mobile side: expect AddCommand response
      EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
    end

  --End Test case
  -----------------------------------------------------------------------------------------


  function Test:DeleteCommand()
          --mobile side: sending DeleteCommand request
          local cid = self.mobileSession:SendRPC("DeleteCommand",
          {
            cmdID = 1
          })

          --hmi side: expect UI.DeleteCommand request
          EXPECT_HMICALL("UI.DeleteCommand",
          {
            cmdID = 1
          })
          :Do(function(_,data)
            --hmi side: sending UI.DeleteCommand response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --hmi side: expect VR.DeleteCommand request
          EXPECT_HMICALL("VR.DeleteCommand",
          {
            cmdID = 1
          })
          :Do(function(_,data)
            --hmi side: sending VR.DeleteCommand response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --mobile side: expect DeleteCommand response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end

      --End Test case
      -----------------------------------------------------------------------------------------


  function Test:AddSubMenu()
          --mobile side: sending AddSubMenu request
          local cid = self.mobileSession:SendRPC("AddSubMenu",
                              {
                                menuID = 1000,
                                position = 500,
                                menuName ="SubMenupositive"
                              })
          --hmi side: expect UI.AddSubMenu request
          EXPECT_HMICALL("UI.AddSubMenu",
                  {
                    menuID = 1000,
                    menuParams = {
                      position = 500,
                      menuName ="SubMenupositive"
                    }
                  })
          :Do(function(_,data)
            --hmi side: sending UI.AddSubMenu response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --mobile side: expect AddSubMenu response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

        end

      --End Test case
 -----------------------------------------------------------------------------------------


function Test:DeleteSubMenu()
            --mobile side: sending DeleteSubMenu request
            local cid = self.mobileSession:SendRPC("DeleteSubMenu",
                                {
                                  menuID = 1000
                                })
            --hmi side: expect UI.DeleteSubMenu request
            EXPECT_HMICALL("UI.DeleteSubMenu",
                    {
                      menuID = 1000
                    })
            :Do(function(_,data)
              --hmi side: sending UI.DeleteSubMenu response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
            end)

            --mobile side: expect DeleteSubMenu response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
          end

      --End Test case
  -----------------------------------------------------------------------------------------


      function Test:CreateInteractionChoiceSet()
            --mobile side: sending CreateInteractionChoiceSet request
          local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
                              {
                                interactionChoiceSetID = 1001,
                                choiceSet =
                                {

                                  {
                                    choiceID = 1001,
                                    menuName ="Choice1001",
                                    vrCommands =
                                    {
                                      "Choice1001",
                                    },
                                    image =
                                    {
                                      value ="action.png",
                                      imageType ="DYNAMIC",
                                    },
                                  }
                                }
                              })


          --hmi side: expect VR.AddCommand request
          EXPECT_HMICALL("VR.AddCommand",
                  {
                    cmdID = 1001,
                    appID = applicationID,
                    type = "Choice",
                    vrCommands = {"Choice1001" }
                  })
          :Do(function(_,data)
            --hmi side: sending VR.AddCommand response
            grammarIDValue = data.params.grammarID
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --mobile side: expect CreateInteractionChoiceSet response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end

    --End Test case
    -----------------------------------------------------------------------------------------


function Test:PerformInteraction()
  --mobile side: sending PerformInteraction request
  local cid = self.mobileSession:SendRPC("PerformInteraction",{
    initialText ="StartPerformInteraction",

    initialPrompt =
    {
      {
        text ="Makeyourchoice",
        type ="TEXT",
      },
    },

    interactionMode ="BOTH",

    interactionChoiceSetIDList =
      {
        1001,
      },

    helpPrompt =
    {
      {
        text ="ChoosethevariantonUI",
        type ="TEXT",
      },
    },

    timeoutPrompt =
      {
        {
          text ="Timeisout",
          type ="TEXT",
        },
      },

    timeout = 5000,

    vrHelp =
    {
      {
        text = "Help2",
        position = 1,
        image =
        {
          value ="action.png",
          imageType ="DYNAMIC",
        }
      },
    },
    interactionLayout = "ICON_ONLY"
  }
  )

  --  --hmi side: expect VR.PerformInteraction request
  EXPECT_HMICALL("VR.PerformInteraction", {})

  :Do(function(_,data)
  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)


  --hmi side: expect UI.PerformInteraction request
    EXPECT_HMICALL("UI.PerformInteraction", {})

    :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
   end)

--   --mobile side: expect PerformInteraction response
   EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

 --End Test case
-------------------------------------------------------------------


        function Test:DeleteInteractionChoiceSet()
        --mobile side: sending DeleteInteractionChoiceSet request
        local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
                                          {
                                            interactionChoiceSetID = 1001
                                          })

        --hmi side: expect VR.DeleteCommand request
        EXPECT_HMICALL("VR.DeleteCommand",
              {cmdID = 1001, type = "Choice"})
        :Do(function(_,data)
          --hmi side: sending VR.DeleteCommand response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end)

        --mobile side: expect DeleteInteractionChoiceSet response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
      end

    --End Test case
    -----------------------------------------------------------------------------------------


    function Test:Alert()

        --mobile side: Alert request
        local CorIdAlert = self.mobileSession:SendRPC("Alert",
                  {

                    alertText1 = "alertText1",
                    alertText2 = "alertText2",
                    alertText3 = "alertText3",
                    ttsChunks =
                    {

                      {
                        text = "TTSChunk",
                        type = "TEXT",
                      }
                    },
                    duration = 3000,
                    playTone = true,
                    progressIndicator = true,
                    softButtons =
                    {

                      {
                        type = "BOTH",
                        text = "Close",
                        
                        image =
                        {
                          value = "action.png",
                          imageType = "DYNAMIC",
                        },
                        isHighlighted = true,
                        softButtonID = 3,
                        systemAction = "DEFAULT_ACTION",
                      }
                    }

                  })

        local AlertId
        --hmi side: UI.Alert request
        EXPECT_HMICALL("UI.Alert",
              {
                alertStrings =
                {
                  {fieldName = "alertText1", fieldText = "alertText1"},
                      {fieldName = "alertText2", fieldText = "alertText2"},
                      {fieldName = "alertText3", fieldText = "alertText3"}
                  },
                  alertType = "BOTH",
                duration = 0,
                progressIndicator = true,
                softButtons =
                {

                  {
                    type = "BOTH",
                    text = "Close",
                    --ToDo: Shall be uncommented when APPLINK-16052 "ATF: TC is failed in case receiving message with nested struct" is fixed
                    --image =
                    --{
                    --  value = storagePath .. "action.png",
                    --  imageType = "DYNAMIC"
                    --},
                    isHighlighted = true,
                    softButtonID = 3,
                    systemAction = "DEFAULT_ACTION"
                  }
                }
              })
          :Do(function(_,data)
            SendOnSystemContext(self,"ALERT")
            AlertId = data.id

            local function alertResponse()
              self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

              SendOnSystemContext(self,"MAIN")
            end

            RUN_AFTER(alertResponse, 3000)
          end)

        local SpeakId
        --hmi side: TTS.Speak request
        EXPECT_HMICALL("TTS.Speak",
              {
                ttsChunks =
                {

                  {
                    text = "TTSChunk",
                    type = "TEXT"
                  }
                },
                speakType = "ALERT"
              })
          :Do(function(_,data)
            self.hmiConnection:SendNotification("TTS.Started")
            SpeakId = data.id

            local function speakResponse()
              self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

              self.hmiConnection:SendNotification("TTS.Stopped")
            end

            RUN_AFTER(speakResponse, 2000)

          end)
          :ValidIf(function(_,data)
            if #data.params.ttsChunks == 1 then
              return true
            else
              print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
              return false
            end
          end)


        --UPDATED: According to APPLINK-17388 BC.PlayTone is removed from HMI_API.xml
        --hmi side: BC.PlayTone request
        --EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})


          --mobile side: Alert response
          EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
      end

  --End Test case
  ------------------------------------------------------------------------------------------


  function Test:Show()

        --mobile side: sending Show request
        local cid = self.mobileSession:SendRPC("Show",
                            {
                              mediaClock = "12:34",
                              mainField1 = "Show Line 1",
                              mainField2 = "Show Line 2",
                              mainField3 = "Show Line 3",
                              mainField4 = "Show Line 4",
                              graphic =
                              {
                                value = "action.png",
                                imageType = "DYNAMIC"
                              },
                              softButtons =
                              {
                                 {
                                  text = "Close",
                                  systemAction = "KEEP_CONTEXT",
                                  type = "BOTH",
                                  isHighlighted = true,
                                  image =
                                  {
                                     imageType = "DYNAMIC",
                                     value = "action.png"
                                  },
                                  softButtonID = 1
                                 }
                               },
                              secondaryGraphic =
                              {
                                value = "action.png",
                                imageType = "DYNAMIC"
                              },
                              statusBar = "status bar",
                              mediaTrack = "Media Track",
                              alignment = "CENTERED",
                              customPresets =
                              {
                                "Preset1",
                                "Preset2",
                                "Preset3"
                              }
                            })
        --hmi side: expect UI.Show request
        EXPECT_HMICALL("UI.Show",
                {
                  alignment = "CENTERED",
                  customPresets =
                  {
                    "Preset1",
                    "Preset2",
                    "Preset3"
                  },
                  -- Checks are done below
                  -- graphic =
                  -- {
                  --  imageType = "DYNAMIC",
                  --  value = storagePath .. "action.png"
                  -- },
                  -- secondaryGraphic =
                  -- {
                  --  imageType = "DYNAMIC",
                  --  value = storagePath .. "action.png"
                  -- },
                  showStrings =
                  {
                    {
                    fieldName = "mainField1",
                    fieldText = "Show Line 1"
                    },
                    {
                    fieldName = "mainField2",
                    fieldText = "Show Line 2"
                    },
                    {
                    fieldName = "mainField3",
                    fieldText = "Show Line 3"
                    },
                    {
                    fieldName = "mainField4",
                    fieldText = "Show Line 4"
                    },
                    {
                    fieldName = "mediaClock",
                    fieldText = "12:34"
                    },
                    {
                      fieldName = "mediaTrack",
                      fieldText = "Media Track"
                    },
                    {
                      fieldName = "statusBar",
                      fieldText = "status bar"
                    }
                  },
                  softButtons =
                  {
                     {
                      text = "Close",
                      systemAction = "KEEP_CONTEXT",
                      type = "BOTH",
                      isHighlighted = true,
                      --ToDo: Shall be uncommented when APPLINK-16052 "ATF: TC is failed in case receiving message with nested struct" is fixed
                      --image =
                      --{
                      --   imageType = "DYNAMIC",
                      --   value = storagePath .. "action.png"
                      --},
                      softButtonID = 1
                     }
                   }
          })
          :ValidIf(function(_,data)
              local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
              local value_menuIcon = path .. "action.png"
              -- params graphic
              if(data.params.graphic.imageType == "DYNAMIC") then
                  return true
              else
                  print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.menuIcon.imageType .. "\27[0m")
                  return false
              end

              if(string.find(data.params.graphic.value, value_menuIcon) ) then
                  return true
              else
                  print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_menuIcon .. "; Real: " .. data.params.menuIcon.value .. "\27[0m")
                  return false
              end
              -- params secondaryGraphic
              if(data.params.secondaryGraphic.imageType == "DYNAMIC") then
                  return true
              else
                  print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.menuIcon.imageType .. "\27[0m")
                  return false
              end

              if(string.find(data.params.secondaryGraphic.value, value_menuIcon) ) then
                  return true
              else
                  print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_menuIcon .. "; Real: " .. data.params.menuIcon.value .. "\27[0m")
                  return false
              end
          end)
          :Do(function(_,data)
            --hmi side: sending UI.Show response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

        --mobile side: expect Show response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
      end

    --End Test case
     -------------------------------------------------------------------------------------

    function Test:Speak()
            --mobile side: sending Speak request
            local cid = self.mobileSession:SendRPC("Speak",
                                {
                                  ttsChunks =
                                  {

                                    {
                                      text ="SpeakFirst",
                                      type ="TEXT"
                                    },

                                    {
                                      text ="SpeakSecond",
                                      type ="TEXT"
                                    }
                                  }
                                }
                              )

            --hmi side: expect TTS.Speak request
            EXPECT_HMICALL("TTS.Speak",
            {
              ttsChunks =
              {

                {
                  text ="SpeakFirst",
                  type ="TEXT"
                },

                {
                  text ="SpeakSecond",
                  type ="TEXT"
                }
              }
            })
            :Do(function(_,data)
              self.hmiConnection:SendNotification("TTS.Started")
              SpeakId = data.id

              local function speakResponse()
                self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

                self.hmiConnection:SendNotification("TTS.Stopped")
              end
              RUN_AFTER(speakResponse, 2000)
            end)


            --mobile side: expect Speak response
            EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
          end

      --End Test case
      -----------------------------------------------------------------------------------------


      function Test:SetMediaClockTimer()

            --mobile side: sending SetMediaClockTimer request
            local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
            {
              startTime =
              {
                hours = 0,
                minutes = 1,
                seconds = 33
              },
              endTime =
              {
                hours = 0,
                minutes = 1 ,
                seconds = 35
              },
              updateMode = "COUNTUP"
            })

            --hmi side: expect UI.SetMediaClockTimer request
            EXPECT_HMICALL("UI.SetMediaClockTimer",
            {
              startTime =
              {
                hours = 0,
                minutes = 1,
                seconds = 33
              },
              endTime =
              {
                hours = 0,
                minutes = 1,
                seconds = 35
              },
              updateMode = "COUNTUP"
            })

            :Timeout(iTimeout)
            :Do(function(_,data)
              --hmi side: sending UI.SetMediaClockTimer response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
            end)

            --mobile side: expect SetMediaClockTimer response
            EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
      end

      --End Test case
      -----------------------------------------------------------------------------------------


    function Test:PerformAudioPassThru()
        local time_cid = 0
        local time_response = 0
        
        --mobile side: PerformAudioPassThru request
        local cid = self.mobileSession:SendRPC("PerformAudioPassThru",
        {
            initialPrompt =
            {
              {
                text ="Makeyourchoice",
                type ="TEXT",
              },
            },
            audioPassThruDisplayText1 ="DisplayText1",
            audioPassThruDisplayText2 ="DisplayText2",
            samplingRate ="8KHZ",
            maxDuration = 1000,
            bitsPerSample ="8_BIT",
            audioType ="PCM",
            muteAudio = true,
        })

        time_cid = timestamp()

        --hmi side: expect PerformAudioPassThru request
        EXPECT_HMICALL("UI.PerformAudioPassThru",
        {
            audioPassThruDisplayTexts = {
                                          {
                                            fieldName = "audioPassThruDisplayText1",
                                            fieldText = "DisplayText1"
                                          },
                                          {
                                            fieldName = "audioPassThruDisplayText2",
                                            fieldText = "DisplayText2"
                                          }
                                        },
            maxDuration = 1000,
            muteAudio = true
        })
        :Do(function(_,data)
            --hmi side: sending PerformAudioPassThru response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end)

        --mobile side: expect PerformAudioPassThru response
        --UPDATED: according to APPLINK-17008 and APPLINK-17728
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
        :Do(function(_,data)
            time_response = timestamp() 
                if( ( (time_response - time_cid) > RPC_ResponseTimeout) or ((time_response - time_cid) <= 0) )  then
                    print ("\27[33m WARNING: Response of RPC is not in specified time("..RPC_ResponseTimeout.."msec). Real: ".. (time_response - time_cid).." \27[0m")
                else
                    print ("\27[33m INFO: Response of RPC is in specified time("..RPC_ResponseTimeout.."msec). Real: ".. (time_response - time_cid).." \27[0m")
                end
          end)
        :Timeout(11000)


 
end

  --End Test case
  -----------------------------------------------------------------------------------------


  function Test:EndAudioPassThru()

    --mobile side: EndAudioPassThru request
    local cid = self.mobileSession:SendRPC("EndAudioPassThru", {})

      --hmi side: expect UI.EndAudioPassThru request
      --     EXPECT_HMICALL("UI.EndAudioPassThru")
      --     :Do(function(_,data)
      --       --hmi side: sending UI.EndAudioPassThru response
      --       self.hmiConnection:SendError(data.id, data.method, "REJECTED")
      --     end)

      --     --mobile side: expect EndAudioPassThru response
      --     EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
      -- end
      -- UPDATED: Because of previous step return Result code is INVALID_DATA
      --hmi side: expect UI.EndAudioPassThru request
          EXPECT_HMICALL("UI.EndAudioPassThru")
          :Do(function(_,data)
            --hmi side: sending UI.EndAudioPassThru response
            self.hmiConnection:SendError(data.id, data.method, "INVALID_DATA")
          end)

          --mobile side: expect EndAudioPassThru response
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
      end

  --End Test case
  -----------------------------------------------------------------------------------------


      function Test:SubscribeButton()
            --mobile side: sending SubscribeButton request
            local cid = self.mobileSession:SendRPC("SubscribeButton",
            {
              buttonName = "TUNEDOWN"

            })

            --mobile side: expect SubscribeButton response
            EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
      end

      --End Test case
      -----------------------------------------------------------------------------------------


         function Test:UnsubscribeButton()
            --mobile side: sending UnsubscribeButton request
            local cid = self.mobileSession:SendRPC("UnsubscribeButton",
            {
              buttonName = "TUNEDOWN"

            })

            --mobile side: expect UnsubscribeButton response
            EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
          end

  --End Test case
      -----------------------------------------------------------------------------------------


    function Test:SubscribeVehicleData()
          --mobile side: sending SubscribeVehicleData request
          local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
                              {
                                gps = true
                              })
          --hmi side: expect VehicleInfo.SubscribeVehicleData request
          EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
                  {
                    gps = true
                    }
                  )
          :Do(function(_,data)
            --hmi side: sending VehicleInfo.SubscribeVehicleData response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --mobile side: expect SubscribeVehicleData response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
     end

      --End Test case
      -----------------------------------------------------------------------------------------


        function Test:UnsubscribeVehicleData()
          --mobile side: sending UnsubscribeVehicleData request
          local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
                              {
                                gps = true
                              })
          --hmi side: expect VehicleInfo.UnsubscribeVehicleData request
          EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",
                  {
                    gps = true
                    }
                  )
          :Do(function(_,data)
            --hmi side: sending VehicleInfo.UnsubscribeVehicleData response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --mobile side: expect SubscribeVehicleData response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end

      --End Test case
      -----------------------------------------------------------------------------------------


        function Test:GetVehicleData()
          local time_hmicall = 0
          --mobile side: sending GetVehicleData request
          local cid = self.mobileSession:SendRPC("GetVehicleData",
                              {
                                speed = true
                              })
          local time_cid =  timestamp()
          --hmi side: expect VehicleInfo.GetVehicleData request
          EXPECT_HMICALL("VehicleInfo.GetVehicleData",
                  {
                    speed = true
                    }
                  )
          :Do(function(_,data)
                --hmi side: sending VehicleInfo.GetVehicleData response
                time_hmicall = timestamp() 
                if( ( (time_hmicall - time_cid) > RPC_ResponseTimeout) or ((time_hmicall - time_cid) <= 0) )  then
                    print ("\27[33m WARNING: Response of RPC is not in specified time("..RPC_ResponseTimeout.."msec). Real: ".. (time_hmicall - time_cid).." \27[0m")
                else
                    print ("\27[33m INFO: Response of RPC is in specified time("..RPC_ResponseTimeout.."msec). Real: ".. (time_hmicall - time_cid).." \27[0m")
                end
                
                self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {actual = false,
                    speed = 34.24                
                })
                --print("time_hmicall = "..time_hmicall)
              end):Timeout(11000)
--:ValidIf(function(exp,data)
                   
  --                end)
          
          --mobile side: expect GetVehicleData response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

        
              

        

        end

      --End Test case
      -----------------------------------------------------------------------------------------

      function Test:ReadDID()
          --mobile side: sending ReadDID request
          local cid = self.mobileSession:SendRPC("ReadDID",
                              {
                                didLocation = { 56832 },
                                ecuName = 2000
                              })
          --hmi side: expect VehicleInfo.ReadDID request
          EXPECT_HMICALL("VehicleInfo.ReadDID",
                            {
                                didLocation = { 56832 },
                                ecuName = 2000
                            }
                            )
          :Do(function(_,data)
            --hmi side: sending VehicleInfo.ReadDID response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
              didResult = {{
              resultCode = "SUCCESS",
              didLocation = 22,
              data = "dsasdas"
                    }
                  }})
          end)

          --mobile side: expect ReadDID response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end

      --End Test case
      -----------------------------------------------------------------------------------------


      function Test:GetDTCs()
          --mobile side: sending GetDTCs request
          local cid = self.mobileSession:SendRPC("GetDTCs",
                              {
                                dtcMask = 100 ,
                                ecuName = 2000
                              })
          --hmi side: expect VehicleInfo.GetDTCs request
          EXPECT_HMICALL("VehicleInfo.GetDTCs",
                            {
                                dtcMask =  100,
                                ecuName = 2000
                            }
                            )
          :Do(function(_,data)
            --hmi side: sending VehicleInfo.GetDTCs response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {dtc = { "line 0", "line 1", "line 2" },  ecuHeader = 2})
          end)

          --mobile side: expect GetDTCs response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end

      --End Test case
      -----------------------------------------------------------------------------------------


      function Test:ScrollableMessage()
          --mobile side: sending ScrollableMessage request
          local cid = self.mobileSession:SendRPC("ScrollableMessage",
                              {
                                scrollableMessageBody = "dkdkdksldsdljlsjdglkjlskjdfspdfosjpdfdsjkllkj",
                                timeout = 1000
                              })
          --hmi side: expect UI.ScrollableMessage request
          EXPECT_HMICALL("UI.ScrollableMessage",
                            {
                                messageText = {
                                  fieldName = "scrollableMessageBody",
                                  fieldText = "dkdkdksldsdljlsjdglkjlskjdfspdfosjpdfdsjkllkj"
                                          },
                                timeout = 1000
                            }
                            )
          :Do(function(_,data)
            --hmi side: sending UI.ScrollableMessage response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --mobile side: expect ScrollableMessage response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end

      --End Test case
      -----------------------------------------------------------------------------------------


       function Test:Slider()
        local cid = self.mobileSession:SendRPC ("Slider",
        {
          numTicks = 7,
          position = 6,
          sliderHeader ="sliderHeader"
        }
        )

      --hmi side: Slider request
      EXPECT_HMICALL("UI.Slider",
      {
        numTicks = 7,
        position = 6,
        sliderHeader ="sliderHeader"
      }
      )
      :Do(function(_,data)
      --hmi side: sending UI.Slider response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
      --mobile side: expect Slider response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
      end

    --End Test case
    ---------------------------------------------------------------------------------


    function Test:ShowConstantTBT()
        local cid = self.mobileSession:SendRPC ("ShowConstantTBT", {
                        navigationText1 ="navigationText1",
                        navigationText2 ="navigationText2",
                        eta ="12:34",
                        totalDistance ="100miles",
                        turnIcon =
                          {
                            value ="action.png",
                            imageType ="DYNAMIC"
                          },
                        nextTurnIcon =
                          {
                            value ="action.png",
                            imageType ="DYNAMIC",
                          },
                        distanceToManeuver = 50.50,
                        distanceToManeuverScale = 100.6,
                        maneuverComplete = false,
                        softButtons =
                          {
                            {
                              type ="BOTH",
                              text ="Close",
                              image =
                                 {
                                   value ="action.png",
                                   imageType ="DYNAMIC",
                                 },
                              isHighlighted = true,
                              softButtonID = 44,
                            systemAction ="DEFAULT_ACTION",
                          },
                        }
                      }
      )
      
      

      --hmi side: Navigation.ShowConstantTBT request
      EXPECT_HMICALL("Navigation.ShowConstantTBT",
      {
        navigationTexts = {
          {
            fieldName = "navigationText1",
            fieldText = "navigationText1"
          },
          {
            fieldName = "navigationText2",
            fieldText = "navigationText2"
          },
          {
            fieldName = "ETA",
            fieldText = "12:34"
          },
          {
            fieldName = "totalDistance",
            fieldText = "100miles"
          }
          },
        --Checked below
        -- turnIcon =
        --   {
        --   --UPDATED
        --     --value ="/home/sdl/Project/FORD/github/develop/bin/storage/8675308_12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0/action.png",
        --     value = storagePath .."action.png",
        --     imageType ="DYNAMIC"
        --   },
        -- nextTurnIcon =
        --   {
        --   --UPDATED
        --     --value ="/home/sdl/Project/FORD/github/develop/bin/storage/8675308_12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0/action.png",
        --     value = storagePath .."action.png",
        --     imageType ="DYNAMIC"
        --   },
        distanceToManeuver = 50.50,
        distanceToManeuverScale = 100.6,
        maneuverComplete = false,
        softButtons =
          {
            {
              type ="BOTH",
              text ="Close",
              --ToDo: Shall be uncommented when APPLINK-16052 "ATF: TC is failed in case receiving message with nested struct" is fixed
              -- image =
              --   {
              --     value ="/home/sdl/Project/FORD/github/develop/bin/storage/8675308_12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0/action.png",
              --     imageType ="DYNAMIC",
              --   },
              isHighlighted = true,
              softButtonID = 44,
              systemAction ="DEFAULT_ACTION",
             },
          }
      }
      )
      :ValidIf(function(_,data)
          local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
          local value_menuIcon = path .. "action.png"
          -- params turnIcon
          if(data.params.turnIcon.imageType == "DYNAMIC") then
              return true
          else
              print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.menuIcon.imageType .. "\27[0m")
              return false
          end

          if(string.find(data.params.turnIcon.value, value_menuIcon) ) then
              return true
          else
              print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_menuIcon .. "; Real: " .. data.params.menuIcon.value .. "\27[0m")
              return false
          end
          -- params nextTurnIcon
          if(data.params.nextTurnIcon.imageType == "DYNAMIC") then
              return true
          else
              print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.menuIcon.imageType .. "\27[0m")
              return false
          end

          if(string.find(data.params.nextTurnIcon.value, value_menuIcon) ) then
              return true
          else
              print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_menuIcon .. "; Real: " .. data.params.menuIcon.value .. "\27[0m")
              return false
          end
      end)
      :Do(function(_,data)
      --hmi side: sending Navigation.ShowConstantTBT response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
      --mobile side: expect ShowConstantTBT response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
      end

    --End Test case
    ---------------------------------------------------------------------------------


    function Test:AlertManeuver()
        local cid = self.mobileSession:SendRPC ("AlertManeuver", {
              ttsChunks =
                {

                  {
                    text ="FirstAlert",
                    type ="TEXT",
                  },

                  {
                    text ="SecondAlert",
                    type ="TEXT",
                  },
                },
                      }
        )

      --hmi side: Navigation.AlertManeuver request
      EXPECT_HMICALL("Navigation.AlertManeuver",
      {}
      )
      :Do(function(_,data)
      --hmi side: sending UI.Slider response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

      --hmi side: TTS.Speak request
      EXPECT_HMICALL("TTS.Speak",
            {
              speakType =  "ALERT_MANEUVER",
              ttsChunks =
              {

                {
                  text ="FirstAlert",
                  type ="TEXT"
                },

                {
                  text ="SecondAlert",
                  type ="TEXT"
                }
              }
            })
            :Do(function(_,data)
              self.hmiConnection:SendNotification("TTS.Started")
              SpeakId = data.id

              local function speakResponse()
                self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

                self.hmiConnection:SendNotification("TTS.Stopped")
              end
              RUN_AFTER(speakResponse, 2000)
            end)

      :Do(function(_,data)
      --hmi side: sending Navigation.AlertManeuver response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
      --mobile side: expect AlertManeuver response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
      end

    --End Test case
    ---------------------------------------------------------------------------------


    function Test:UpdateTurnList()
        local cid = self.mobileSession:SendRPC ("UpdateTurnList",
        {
                turnList =
                    {
                      {
                        navigationText ="Text",
                        turnIcon =
                        {
                          value ="action.png",
                          imageType ="DYNAMIC",
                        },
                      },
                    },
                    softButtons =
                    {
                      {
                        type ="BOTH",
                        text ="Close",
                        image =
                        {
                          value ="action.png",
                          imageType ="DYNAMIC",
                        },
                        isHighlighted = true,
                        softButtonID = 111,
                        systemAction ="DEFAULT_ACTION",
                      },
                    },
        }
        )

      --hmi side: Navigation.UpdateTurnList request
      EXPECT_HMICALL("Navigation.UpdateTurnList",
      {
                --ToDo: Shall be uncommented when APPLINK-16052 "ATF: TC is failed in case receiving message with nested struct" is fixed
                -- turnList =
                --     {
                --       {
                --         navigationText =
                --         {
                --           fieldName = "turnText",
                --           fieldText ="Text"
                --         },
                --         turnIcon =
                --         {
                --           value =config.SDLStoragePath .."action.png",
                --           imageType ="DYNAMIC",
                --         },
                --       },
                --     },
                    softButtons =
                    {
                      {
                        type ="BOTH",
                        text ="Close",
                        --ToDo: Shall be uncommented when APPLINK-16052 "ATF: TC is failed in case receiving message with nested struct" is fixed
                        --image =
                        --{
                          --value ="/home/sdl/Project/FORD/github/develop/bin/storage/8675308_12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0/action.png",
                          --imageType ="DYNAMIC",
                        --},
                        isHighlighted = true,
                        softButtonID = 111,
                        systemAction ="DEFAULT_ACTION",
                      },
                    },
      }
      )
      :Do(function(_,data)
      --hmi side: sending Navigation.UpdateTurnList response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
      --mobile side: expect UpdateTurnList response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
      end

    --End Test case
    ---------------------------------------------------------------------------------


     function Test:ChangeRegistration()
        local cid = self.mobileSession:SendRPC ("ChangeRegistration",
        {
        language ="EN-US",
        hmiDisplayLanguage ="EN-US",
        appName ="SyncProxyTester",
        ttsName =
        {

          {
            text ="SyncProxyTester",
            type ="TEXT",
          },
        },
        ngnMediaScreenAppName ="SPT",
        vrSynonyms =
        {
          "VRSyncProxyTester",
        },
      }
        )

      --hmi side: UI.ChangeRegistration request
      EXPECT_HMICALL("UI.ChangeRegistration",
      {
        appName ="SyncProxyTester",
        language ="EN-US",
        ngnMediaScreenAppName ="SPT"
      }
      )
      :Do(function(_,data)
      --hmi side: sending UI.ChangeRegistration response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

      --hmi side: VR.ChangeRegistration request
      EXPECT_HMICALL("VR.ChangeRegistration",
      {
        language ="EN-US",
        vrSynonyms =
          {
            "VRSyncProxyTester",
          }
      }
      )
      :Do(function(_,data)
      --hmi side: sending VR.ChangeRegistration response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

      --hmi side: VR.ChangeRegistration request
      EXPECT_HMICALL("TTS.ChangeRegistration",
      {
        language ="EN-US",
        ttsName =
    {

      {
        text ="SyncProxyTester",
        type ="TEXT",
      },
    }
      }
      )
      :Do(function(_,data)
      --hmi side: sending VR.ChangeRegistration response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

      --mobile side: expect ChangeRegistration response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
      end

    --End Test case
    ---------------------------------------------------------------------------------


    function Test:PutFile()
      local cid = self.mobileSession:SendRPC("PutFile",
      {
        syncFileName = "action.png",
        fileType  = "GRAPHIC_PNG",
        persistentFile = false,
        systemFile = false
      }, "files/action.png")
      EXPECT_RESPONSE(cid, { success = true})
    end

    --End Test case
    ---------------------------------------------------------------------------------


     function Test:ListFiles()
      local cid = self.mobileSession:SendRPC("ListFiles", {})

      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", filenames = {"action.png"} })
    end

    --End Test case
    ---------------------------------------------------------------------------------


    function Test:SetAppIcon()

    --mobile side: sending SetAppIcon request
    local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "action.png" })

    --hmi side: expect UI.SetAppIcon request
    EXPECT_HMICALL("UI.SetAppIcon",
    {
      -- syncFileName =
      -- {
      --   imageType = "DYNAMIC",
      --   value = storagePath .. "action.png"
      -- }
    })
    :ValidIf(function(_,data)
          local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
          local value_menuIcon = path .. "action.png"
          
          if(data.params.syncFileName.imageType == "DYNAMIC") then
              return true
          else
              print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.menuIcon.imageType .. "\27[0m")
              return false
          end

          if(string.find(data.params.syncFileName.value, value_menuIcon) ) then
                  return true
              else
                  print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_menuIcon .. "; Real: " .. data.params.menuIcon.value .. "\27[0m")
                  return false
              end
      end)
      
    :Timeout(iTimeout)
    :Do(function(_,data)
      --hmi side: sending UI.SetAppIcon response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    --mobile side: expect SetAppIcon response
    EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })
  end

    --End Test case
    ---------------------------------------------------------------------------------


    function Test:DeleteFile()
      local cid = self.mobileSession:SendRPC("DeleteFile",
      {
        syncFileName = "action.png"
      }
      )
      EXPECT_RESPONSE(cid, { success = true})
    end

    --End Test case
    ---------------------------------------------------------------------------------


    function Test:SetDisplayLayout()

          --mobile side: sending SetDisplayLayout request
          local cid = self.mobileSession:SendRPC("SetDisplayLayout",
          {
            displayLayout = "ONSCREEN_PRESETS"
          })


          --hmi side: expect UI.SetDisplayLayout request
          EXPECT_HMICALL("UI.SetDisplayLayout",
          {
            displayLayout = "ONSCREEN_PRESETS"
          })
          :Timeout(iTimeout)
          :Do(function(_,data)
            --hmi side: sending UI.SetDisplayLayout response
            --local responsedParams = createDefaultResponseParamsValues()
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --mobile side: expect SetDisplayLayout response
          --local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

          EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })
        end

    --End Test case
    ---------------------------------------------------------------------------------


      function Test:DiagnosticMessage()
        local time_cid = 0
        local time_response = 0
        local cid = self.mobileSession:SendRPC ("DiagnosticMessage",
        {
          targetID = 7,
          messageLength = 1,
          messageData =
            {
              1
            }
        }
        )

        time_cid = timestamp()
      --hmi side: VehicleInfo.DiagnosticMessage request
      EXPECT_HMICALL("VehicleInfo.DiagnosticMessage",
      {
          targetID = 7,
          messageLength = 1,
          messageData =
            {
              1
            }
      }
      )
      :Do(function(_,data)
      --hmi side: sending VehicleInfo.DiagnosticMessage response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {messageDataResult = {12}})
      end)
      --mobile side: expect DiagnosticMessage response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
      : Do(function(_,data)
                time_response = timestamp() 
                if( ( (time_response - time_cid) > RPC_ResponseTimeout) or ((time_response - time_cid) <= 0) )  then
                    print ("\27[33m WARNING: Response of RPC is not in specified time("..RPC_ResponseTimeout.."msec). Real: ".. (time_response - time_cid).." \27[0m")
                else
                    print ("\27[33m INFO: Response of RPC is in specified time("..RPC_ResponseTimeout.."msec). Real: ".. (time_response - time_cid).." \27[0m")
                end
          end)
      :Timeout(11000)
      end

    --End Test case
    ---------------------------------------------------------------------------------


    function Test:SystemRequest()
        local cid = self.mobileSession:SendRPC ("SystemRequest",
        {
                requestType = "HTTP",
                fileName = "sdl_preloaded_pt.json"
        }, "files/sdl_preloaded_pt.json"
        )

      --mobile side: expect DiagnosticMessage response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
      end

    --End Test case
    ---------------------------------------------------------------------------------


    function Test:SendLocation()
        local cid = self.mobileSession:SendRPC ("SendLocation",
        {
          longitudeDegrees = 1.1,
          latitudeDegrees = 1.1
        }
        )

      --hmi side: Navigation.SendLocation request
      EXPECT_HMICALL("Navigation.SendLocation",
      {
        longitudeDegrees = 1.1,
        latitudeDegrees = 1.1
      }
      )

      :Do(function(_,data)
      --hmi side: sending Navigation.SendLocation response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
      --mobile side: expect SendLocation response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
      end

    --End Test case
    ---------------------------------------------------------------------------------

--TODO: Uncomment after APPLINK-25154(cloned from APPLINK-17601) will be fixed

 
    -- function Test:GenericResponse()
    --     --mobile side: sending GenericResponse request


    --     local msg =
    --      {
    --        serviceType      = 7,
    --        frameInfo        = 0,
    --        rpcType          = 0,
    --        rpcFunctionId    = 31,
    --        rpcCorrelationId = 3,
    --        payload          = '{}'
    --      }

    --      self.mobileSession:Send(msg)


    --     --mobile side: expect GenericResponse response
    --     EXPECT_RESPONSE(3, { success = false, resultCode = "INVALID_DATA" })
    --     end

      --End Test case
      ---------------------------------------------------------------------------------------


      -- Note!: The DialNumber is not supported by ATF 2.1.3-r1 version. For WA add string: '["DialNumber"] =40,' below string '["SendLocation"] = 39,' in /modules/function_id.lua file
          function Test:DialNumber()
            --request from mobile side
            local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
                                      {
                                        DialNumber = 40,
                                        SendLocation = 39,
                                        number = "#3804567654*"
                                      })

            --hmi side: request, response
              EXPECT_HMICALL("BasicCommunication.DialNumber",

                      {
                          number = "#3804567654*",
                          appID = self.applications["Test Application"]
                        })
              :Do(function(_,data)
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
              end)

            --response on mobile side
            EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
              :Timeout(2000)
        end

  --End Test case
 -----------------------------------------------------------------------------------------


   function Test:UnregisterAppInterface()

        --mobile side: UnregisterAppInterface request
        local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

        --hmi side: expected  BasicCommunication.OnAppUnregistered
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID, unexpectedDisconnect = false})

        --mobile side: UnregisterAppInterface response
        EXPECT_RESPONSE("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
      end

  --End Test case
  -----------------------------------------------------------------------------------------


  function Test:RegisterAppInterface()

          --mobile side: RegisterAppInterface request
          local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
                                {

                                  syncMsgVersion =
                                  {
                                    majorVersion = 2,
                                    minorVersion = 2,
                                  },
                                  appName ="SyncProxyTester",
                                  ttsName =
                                  {

                                    {
                                      text ="SyncProxyTester",
                                      type ="TEXT",
                                    },
                                  },
                                  ngnMediaScreenAppName ="SPT",
                                  vrSynonyms =
                                  {
                                    "VRSyncProxyTester",
                                  },
                                  isMediaApplication = true,
                                  languageDesired ="EN-US",
                                  hmiDisplayLanguageDesired ="EN-US",
                                  appHMIType =
                                  {
                                    "NAVIGATION",
                                  },
                                  appID ="8675308",
                                  deviceInfo =
                                  {
                                    hardware = "hardware",
                                    firmwareRev = "firmwareRev",
                                    os = "os",
                                    osVersion = "osVersion",
                                    carrier = "carrier",
                                    maxNumberRFCOMMPorts = 5
                                  }

                                })


          --hmi side: expected  BasicCommunication.OnAppRegistered
            EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
                        {
                            application =
                            {
                              appName = "SyncProxyTester",
                              ngnMediaScreenAppName ="SPT",
                              --ToDo: Shall be uncommented when APPLINK-16052 "ATF: TC is failed in case receiving message with nested struct" is fixed
                              --UPDATED
                              -- deviceInfo = 
                              -- {
                              --   transportType = "WIFI",
                              --   isSDLAllowed = true,
                              --   id = config.deviceMAC,
                              --   name = "127.0.0.1"
                              -- },
                              -- deviceInfo =
                              -- {
                              --   hardware = "hardware",
                              --   firmwareRev = "firmwareRev",
                              --   os = "os",
                              --   osVersion = "osVersion",
                              --   carrier = "carrier",
                              --   maxNumberRFCOMMPorts = 5
                              -- },
                              policyAppID = "8675308",
                              hmiDisplayLanguageDesired ="EN-US",
                              isMediaApplication = true,
                              --UPDATED
                              --appHMIType =
                              appType = 
                              {
                                  "NAVIGATION"
                              },
                            },
                            ttsName =
                            {

                              {
                                text ="SyncProxyTester",
                        type ="TEXT",
                      }
                    },
                    vrSynonyms =
                    {
                      "VRSyncProxyTester",
                    }
                        })
          -- Set self.applications["SyncProxyTester"] variable
          :Do(function(_,data)
            self.applications["SyncProxyTester"] = data.params.application.appID
          end)

          --ToDo: Shall be uncommented when APPLINK-24902: Genivi: Unexpected unregistering application at resumption after closing session. is fixed
          --mobile side: RegisterAppInterface response
    --       EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
    --         :Timeout(2000)
    --         :Do(function(_,data)
    --           local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["SyncProxyTester"]})
    -- EXPECT_HMIRESPONSE(RequestId)
    --         end)
        end
    --End Test case


      function Test:RegisterAppInterfaceAgain()

          --mobile side: RegisterAppInterface request
          local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
                                {

                                  syncMsgVersion =
                                  {
                                    majorVersion = 2,
                                    minorVersion = 2,
                                  },
                                  appName ="SyncProxyTester",
                                  ttsName =
                                  {

                                    {
                                      text ="SyncProxyTester",
                                      type ="TEXT",
                                    },
                                  },
                                  ngnMediaScreenAppName ="SPT",
                                  vrSynonyms =
                                  {
                                    "VRSyncProxyTester",
                                  },
                                  isMediaApplication = true,
                                  languageDesired ="EN-US",
                                  hmiDisplayLanguageDesired ="EN-US",
                                  appHMIType =
                                  {
                                    "NAVIGATION",
                                  },
                                  appID ="8675308",
                                  deviceInfo =
                                  {
                                    hardware = "hardware",
                                    firmwareRev = "firmwareRev",
                                    os = "os",
                                    osVersion = "osVersion",
                                    carrier = "carrier",
                                    maxNumberRFCOMMPorts = 5
                                  }

                                })


          --hmi side: expected  BasicCommunication.OnAppRegistered
            EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
                        {
                            application =
                            {
                              appName = "SyncProxyTester",
                              ngnMediaScreenAppName ="SPT",
                              --ToDo: Shall be uncommented when APPLINK-16052 "ATF: TC is failed in case receiving message with nested struct" is fixed
                              --UPDATED
                              -- deviceInfo = 
                              -- {
                              --     transportType = "WIFI",
                              --     isSDLAllowed = true,
                              --     id = config.deviceMAC,
                              --     name = "127.0.0.1"
                              -- },
                              -- deviceInfo =
                              -- {
                              --   hardware = "hardware",
                              --   firmwareRev = "firmwareRev",
                              --   os = "os",
                              --   osVersion = "osVersion",
                              --   carrier = "carrier",
                              --   maxNumberRFCOMMPorts = 5
                              -- },
                              policyAppID = "8675308",
                              hmiDisplayLanguageDesired ="EN-US",
                              isMediaApplication = true,
                              --UPDATED
                              --appHMIType =
                              appType = 
                              {
                                  "NAVIGATION"
                              },
                            },
                            ttsName =
                    {

                      {
                        text ="SyncProxyTester",
                        type ="TEXT",
                      }
                    },
                    vrSynonyms =
                    {
                      "VRSyncProxyTester",
                    }
                        })
          -- Set self.applications["SyncProxyTester"] variable
          :Do(function(_,data)
            self.applications["SyncProxyTester"] = data.params.application.appID
          end)

          --mobile side: RegisterAppInterface response
          EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
            :Timeout(2000)
            :Do(function(_,data)
              local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["SyncProxyTester"]})
    EXPECT_HMIRESPONSE(RequestId)
            end)
        end

    --End Test case
  -- -----------------------------------------------------------------------------------------
  -- ---------------Description: Test part of checking notifications logging------------------

  
  --ToDo: Shall be removed when APPLINK-25060 is fixed and update file PolicyTable_All_RPCs.json with all required RPCs
  RestartSDL_ActivateApp()

  function Test:Notification_OnHashChange()
  print ("------------Notifications-------------")
        --mobile side: sending AddCommand request
            local cid = self.mobileSession:SendRPC("AddCommand",
            {
              cmdID = 0,
              menuParams =
              {
                parentID = 0,
                position = 0,
                menuName ="Null"
              },
              vrCommands =
              {
                "Null"
              },

            })

            --hmi side: expect UI.AddCommand request
            EXPECT_HMICALL("UI.AddCommand",
            {
              cmdID = 0,

              menuParams =
              {
                parentID = 0,
                position = 0,
                menuName ="Null"
              }
            })
            :Do(function(_,data)
              --hmi side: sending UI.AddCommand response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
            end)

            --hmi side: expect VR.AddCommand request
            EXPECT_HMICALL("VR.AddCommand",
            {
              cmdID = 0,
              type = "Command",
              vrCommands =
              {
                "Null"
              }
            })
            :Do(function(_,data)
              --hmi side: sending response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
            end)

            EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
            EXPECT_NOTIFICATION("OnHashChange")
          end

  --End Test case
  -----------------------------------------------------------------------------------------

  --ToDo: Shall be removed when APPLINK-25060 is fixed and update file PolicyTable_All_RPCs.json with all required RPCs
  function Test:Precondition_AddCommand()
      --mobile side: sending AddCommand request
      local cid = self.mobileSession:SendRPC("AddCommand",
      {
        cmdID = 1,
        menuParams =
        {
          position = 0,
          menuName ="Command"
        },
          vrCommands =
              {
                "VRCommandonepositive"
              }
      })

      --hmi side: expect UI.AddCommand request
      EXPECT_HMICALL("UI.AddCommand",
      {
        cmdID = 1,
        menuParams =
        {
          position = 0,
          menuName ="Command"
        }
      })
      :Do(function(_,data)
        --hmi side: sending UI.AddCommand response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

      --hmi side: expect VR.AddCommand request
          EXPECT_HMICALL("VR.AddCommand",
                  {
                    cmdID = 1,
                    type = "Command",
                    vrCommands =
                    {
                      "VRCommandonepositive"
                    }
                  })
          :Do(function(_,data)
            --hmi side: sending VR.AddCommand response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

      --mobile side: expect AddCommand response
      EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
    end

  --End Test case
  -----------------------------------------------------------------------------------------

  function Test:Notification_OnCommand()
           --UPDATED:
           self.hmiConnection:SendNotification("UI.OnCommand",{ cmdID = 1, appID = self.applications["SyncProxyTester"]})
           --hmi side: UI.OnCommand notification
            -- self.hmiConnection:SendNotification("UI.OnCommand",{ cmdID = 0, appID = self.applications["SyncProxyTester"]})


              --mobile side: OnCommand notifications
            EXPECT_NOTIFICATION("OnCommand")
          end

    --End Test case
  -----------------------------------------------------------------------------------------


        function Test:Notification_OnHMIStatus()
        --mobile side: sending AddCommand request

          --hmi side: sending response
          SendOnSystemContext(self,"VRSESSION")

          --mobile side: OnHMIStatus notifications
          EXPECT_NOTIFICATION("OnHMIStatus",

    { systemContext = "VRSESSION",  hmiLevel = "FULL" })
      end

    --End Test case
  -----------------------------------------------------------------------------------------


     function Test:Notification_OnButtonEvent()

              --Precondition, mobile side: sending SubscribeButton request
            local cid = self.mobileSession:SendRPC("SubscribeButton",
            {
              buttonName = "TUNEDOWN"

            })

              --Precondition, mobile side: expect SubscribeButton response
            EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
            :Do(function(_,data)

        --hmi side: OnButtonEvent notification
              self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "TUNEDOWN", mode = "BUTTONDOWN"})
          end)

            --mobile side: OnButtonEvent notifications
            EXPECT_NOTIFICATION("OnButtonEvent")
          end


      --End Test case
      -----------------------------------------------------------------------------------------


      function Test:Notification_OnButtonPress()

              --hmi side: Buttons.OnButtonPress notification
              self.hmiConnection:SendNotification("Buttons.OnButtonPress",{ name = "TUNEDOWN", mode = "LONG"})


              --mobile side: OnButtonPress notifications
            EXPECT_NOTIFICATION("OnButtonPress")
          end

      --End Test case
      -----------------------------------------------------------------------------------------


      function Test:Notification_OnVehicleData()

              --Precondition, mobile side: sending SubscribeVehicleData request
          local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
                              {
                                speed = true
                              })
          --Precondition, hmi side: expect VehicleInfo.SubscribeVehicleData request
          EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
                  {
                    speed = true
                    }
                  )
          :Do(function(_,data)
            --Precondition, hmi side: sending VehicleInfo.SubscribeVehicleData response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --Precondition, mobile side: expect SubscribeVehicleData response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
          :Do(function(_,data)

              --hmi side: VehicleInfo.OnVehicleData notification
              self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData",{ speed = 22.33})
          end)

              --mobile side: OnVehicleData notification
            EXPECT_NOTIFICATION("OnVehicleData"):Timeout(11000)
          end

      --End Test case
      -----------------------------------------------------------------------------------------


       function Test:Notification_OnTBTClientState()

              --hmi side: Navigation.OnTBTClientState notification
              self.hmiConnection:SendNotification("Navigation.OnTBTClientState",{ state = "ROUTE_ACCEPTED"})

              --mobile side: OnTBTClientState notifications
            EXPECT_NOTIFICATION("OnTBTClientState")
          end

      --End Test case
      -----------------------------------------------------------------------------------------


       function Test:Notification_OnDriverDistraction()

              --hmi side: UI.OnTBTClientState notification
              self.hmiConnection:SendNotification("UI.OnDriverDistraction",{ state = "DD_OFF"})

              --mobile side: OnDriverDistraction notifications
            EXPECT_NOTIFICATION("OnDriverDistraction")
          end

      --End Test case
      -----------------------------------------------------------------------------------------


          function Test:Notification_OnTouchEvent()

              --hmi side: UI.OnTBTClientState notification
              self.hmiConnection:SendNotification("UI.OnTouchEvent",{ type = "BEGIN", event = {{id = 1, ts = {111,111}, c = {{x = 5, y = 5}}}}})

             --mobile side: OnTouchEvent notifications
            EXPECT_NOTIFICATION("OnTouchEvent")
          end

      --End Test case
      -----------------------------------------------------------------------------------------


  function Test:Notification_OnKeyboardInput()

              --hmi side: UI.OnKeyboardInput notification
              self.hmiConnection:SendNotification("UI.OnKeyboardInput",{ data = "ffff", event = "KEYPRESS"})

              --mobile side: OnKeyboardInput notifications
            EXPECT_NOTIFICATION("OnKeyboardInput")
  end

  --End Test case
  -----------------------------------------------------------------------------------------

  
  function Test:Notification_OnAudioPassThru()
      local time_response = 0
      --mobile side: PerformAudioPassThru request
      local cid = self.mobileSession:SendRPC("PerformAudioPassThru",
      {

          audioPassThruDisplayText1 ="DisplayText1",
          audioPassThruDisplayText2 ="DisplayText2",
          samplingRate ="8KHZ",
          maxDuration = 5000,
          bitsPerSample ="8_BIT",
          audioType ="PCM",
          muteAudio = true,
      }
      )
      local time_cid = timestamp()
      
      
      --hmi side: expect PerformAudioPassThru request
      EXPECT_HMICALL("UI.PerformAudioPassThru",
      {
          audioPassThruDisplayTexts = {
                                        {
                                            fieldName = "audioPassThruDisplayText1",
                                            fieldText = "DisplayText1"
                                        },
                                        {
                                            fieldName = "audioPassThruDisplayText2",
                                            fieldText = "DisplayText2"
                                        }
                                      },
                                      maxDuration = 5000,
                                      muteAudio = true,
                                      appID = self.applications["SyncProxyTester"]

      })
      :Do(function(_,data)
              --mobile side: expect PerformAudioPassThru response
              
              time_response = timestamp() 
              if( ( (time_response - time_cid) > RPC_ResponseTimeout) or ((time_response - time_cid) <= 0) )  then
                  print ("\27[33m WARNING: Response of RPC is not in specified time("..RPC_ResponseTimeout.."msec). Real: ".. (time_response - time_cid).." \27[0m")
              else
                  print ("\27[33m INFO: Response of RPC is in specified time("..RPC_ResponseTimeout.."msec). Real: ".. (time_response - time_cid).." \27[0m")
              end

              local function to_be_run()
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
              end
              RUN_AFTER(to_be_run,5000)
          end)
      

      --ToDo: Shall be uncommented when     APPLINK-24972 "ATF: ATF returns "Timeout expired" of OnAudioPassThru but it exists in logs of SDL." is fixed"
      --mobile side: expect PerformAudioPassThru response
      --EXPECT_NOTIFICATION("OnAudioPassThru"): 
      --Times(AtLeast(1))
      
          
  end

  --End Test case
  -----------------------------------------------------------------------------------------


  function Test:Notification_OnLanguageChange()

              --hmi side: UI.OnLanguageChange notification
              self.hmiConnection:SendNotification("UI.OnLanguageChange",{ language = "ES-MX"})

              --mobile side: OnLanguageChange notifications
            EXPECT_NOTIFICATION("OnLanguageChange")
  end

      --End Test case
      -----------------------------------------------------------------------------------------


      function Test:Notification_OnAppInterfaceUnregistered()

          --mobile side: RegisterAppInterface request
          local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
                                {

                                  syncMsgVersion =
                                  {
                                    majorVersion = 2,
                                    minorVersion = 2,
                                  },
                                  appName ="SyncProxyTester",
                                  ttsName =
                                  {

                                    {
                                      text ="SyncProxyTester",
                                      type ="TEXT",
                                    },
                                  },
                                  ngnMediaScreenAppName ="SPT",
                                  vrSynonyms =
                                  {
                                    "VRSyncProxyTester",
                                  },
                                  isMediaApplication = true,
                                  languageDesired ="ES-MX",
                                  hmiDisplayLanguageDesired ="ES-MX",
                                  appHMIType =
                                  {
                                    "NAVIGATION",
                                  },
                                  appID ="8675308",
                                  deviceInfo =
                                  {
                                    hardware = "hardware",
                                    firmwareRev = "firmwareRev",
                                    os = "os",
                                    osVersion = "osVersion",
                                    carrier = "carrier",
                                    maxNumberRFCOMMPorts = 5
                                  }

                                })

          --hmi side: expected  BasicCommunication.OnAppRegistered
            EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {})

          --mobile side: RegisterAppInterface response
          EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "WRONG_LANGUAGE"})
            :Timeout(2000)

          :Do(function(_,data)
           --hmi side: BasicCommunication.OnExitAllApplications notification
              self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "MASTER_RESET"})
           end)

              --mobile side: OnAppInterfaceUnregistered notifications
            EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
          end

      --End Test case
      -----------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions-------------------------------------
---------------------------------------------------------------------------------------------

function Test:RemoveConfigurationFiles()
  
    -- remove used sdl_preloaded_pt.json from files, restore initial one if exists.
    local dirPath            = "files/"
    

    if (FileExist_PreloadedPT == true) then
        FileExist_PreloadedPT = false
        RestoreSpecificFile(dirPath, "sdl_preloaded_pt.json")
    else
        os.execute("rm ".. dirPath .. "sdl_preloaded_pt.json")
    end

    commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end
