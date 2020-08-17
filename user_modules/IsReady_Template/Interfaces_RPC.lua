local interfaces = { }
-- APPLINK-28518: Script is updated according to clarification. Update of requirement is waiting. After update RPCs should be checked again.
-- APPLINK-29356: Can you clarify is there a priority from where SDL should take capabilities params when HMI does not reply to <Interface>.IsReady
-- APPLINK-29351: Expected error message for Navigation Interface

local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
-- Read paramaters from hmi_capabilities.json
local HmiCapabilities_file = commonPreconditions:GetPathToSDL() .. "hmi_capabilities.json"
f = assert(io.open(HmiCapabilities_file, "r"))
fileContent = f:read("*all")
f:close()
      
local json = require("modules/json")
local HmiCapabilities = json.decode(fileContent)

local storagePath = config.SDLStoragePath..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"

local function image_field(name, width, heigth)
          xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
          return
          {
              name = name,
              imageTypeSupported =
              {
                "GRAPHIC_BMP",
                "GRAPHIC_JPEG",
                "GRAPHIC_PNG"
              },
              imageResolution =
              {
                resolutionWidth = width or 64,
                resolutionHeight = height or 64
              }
          }
end

-- in case  interface is not responded expected parameters of RAI response shall be taken from HMI_capabilities files
-- parameters that shall be checked
interfaces.RAI = {
                    {
                      -- VR.IsReady is missing
                      name = "VR",
                      params = {
                                  success = true,
                                  resultCode = "UNSUPPORTED_RESOURCE",
                                  info = "VR is not supported",
                                  --provide the value of VR related params. 
                                  vrCapabilities = { "TEXT" },
                                  language       = "EN-US"
                                }

                    },
                    {
                      -- UI.IsReady is missing
                      name = "UI",
                      params = {
                                  success = true,
                                  resultCode = "UNSUPPORTED_RESOURCE",
                                  info = "UI is not supported",
                                  --provide the value of UI related params. 
                                  hmiDisplayLanguage        = "EN-US",
                                  displayCapabilities       = {
                                                                displayType = "GEN2_8_DMA",
                                                                displayName = "GENERIC_DISPLAY",
                                                                textFields =
                                                                {
                                                                  { name = "mainField1", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "mainField2", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "mainField3", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "mainField4", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "statusBar", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "mediaClock", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "mediaTrack", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "alertText1", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "alertText2", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "alertText3", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "scrollableMessageBody", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "initialInteractionText", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "navigationText1", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "navigationText2", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "ETA",             characterSet = "UTF_8", width = 500, rows = 1},
                                                                  { name = "totalDistance", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  --{ name = "audioPassThruDisplayText1", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  --{ name = "audioPassThruDisplayText2", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  --{ name = "sliderHeader", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  --{ name = "sliderFooter", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  --{ name = "notificationText", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  --{ name = "menuName", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  --{ name = "secondaryText", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  --{ name = "tertiaryText", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  --{ name = "timeToDestination", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  --{ name = "turnText", characterSet = "UTF_8", width = 500, rows = 1},
                                                                  --{ name = "menuTitle", characterSet = "UTF_8", width = 500, rows = 1}
                                                                },
                                                                --ToDo: Check parameters additional investigation. Commented because not in scope of CRQ, but may be SDL problem
                                                                --[[imageFields =
                                                                {
                                                                  { name = "softButtonImage", imageTypeSupported = { "GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG"}, imageResolution = { resolutionWidth = 64, resolutionHeight = 64} },
                                                                  { name = "choiceImage", imageTypeSupported = { "GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG"}, imageResolution = { resolutionWidth = 64, resolutionHeight = 64} },
                                                                  { name = "choiceSecondaryImage", imageTypeSupported = { "GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG"}, imageResolution = { resolutionWidth = 64, resolutionHeight = 64} },
                                                                  { name = "vrHelpItem", imageTypeSupported = { "GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG"}, imageResolution = { resolutionWidth = 64, resolutionHeight = 64} },
                                                                  { name = "turnIcon", imageTypeSupported = { "GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG"}, imageResolution = { resolutionWidth = 64, resolutionHeight = 64} },
                                                                  { name = "menuIcon", imageTypeSupported = { "GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG"}, imageResolution = { resolutionWidth = 64, resolutionHeight = 64} },
                                                                  { name = "cmdIcon", imageTypeSupported = { "GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG"}, imageResolution = { resolutionWidth = 64, resolutionHeight = 64} },
                                                                  { name = "showConstantTBTIcon", imageTypeSupported = { "GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG"}, imageResolution = { resolutionWidth = 64, resolutionHeight = 64} },
                                                                  { name = "showConstantTBTNextTurnIcon", imageTypeSupported = { "GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG"}, imageResolution = { resolutionWidth = 64, resolutionHeight = 64} }
                                                                },
                                                                imageCapabilities = { "DYNAMIC", "STATIC" },
                                                                templatesAvailable = { "TEMPLATE" },
                                                                screenParams =
                                                                {
                                                                  resolution = { resolutionWidth = 800, resolutionHeight = 480 },
                                                                  touchEventAvailable =
                                                                  {
                                                                    pressAvailable = true,
                                                                    multiTouchAvailable = true,
                                                                    doublePressAvailable = false
                                                                  }
                                                                },
                                                                numCustomPresetsAvailable = 10]]
                                                                mediaClockFormats =
                                                                {
                                                                  "CLOCK1",
                                                                  "CLOCK2",
                                                                  "CLOCK3",
                                                                  "CLOCKTEXT1",
                                                                  "CLOCKTEXT2",
                                                                  "CLOCKTEXT3",
                                                                  "CLOCKTEXT4"
                                                                },
                                                                graphicSupported = true
                                                              },
                                  audioPassThruCapabilities = { { samplingRate = "44KHZ", bitsPerSample = "8_BIT", audioType = "PCM"} },
                                  hmiCapabilities = { 
                                                        navigation = false,
                                                        phoneCall  = false,
                                                        steeringWheelLocation = "CENTER"
                                                      }
                                }

                    },
                    {
                      -- TTS.IsReady is missing
                      name = "TTS",
                      params = {
                                  success = true,
                                  resultCode = "UNSUPPORTED_RESOURCE",
                                  info = "TTS is not supported",
                                  --provide the value of TTS related params. 
                                  language           = "EN-US" ,
                                  speechCapabilities = { "TEXT", "PRE_RECORDED" },
                                  prerecordedSpeech = { "HELP_JINGLE","INITIAL_JINGLE","LISTEN_JINGLE","POSITIVE_JINGLE","NEGATIVE_JINGLE" }
                                }

                    },
                    {
                      -- VehicleInfo.IsReady is missing
                      name = "VehicleInfo",
                      params = {
                                  success = true,
                                  resultCode = "UNSUPPORTED_RESOURCE",
                                  info = "VehicleInfo is not supported",
                                  --provide the value of VehicleInfo related params.                                   
                                  -- TODO: Check the appropriate parameter in hmi_capabilities!
                                  vehicleType =
                                                {
                                                  make = "Ford",
                                                  model = "Fiesta",
                                                  modelYear = "2013",
                                                  trim = "SE"
                                                }
                                }

                    }
}
-- UI: APPLINK-25042 / APPLINK-25043 / APPLINK-25044
interfaces.mobile_req = {
                          --AddCommand
                          {
                            name = "AddCommand", 
                            splitted = true,
                            single = true,
                            description = "AddCommand with all parameters",
                            hashChange = true,
                            params = {
                                        cmdID = 1,
                                        vrCommands = { "vrCommands_12" },
                                        menuParams = {position = 1, menuName ="Command 1"}
                                        --cmdIcon = { value = "icon.png", imageType = "DYNAMIC" }
                                      }
                          },
                          --DeleteCommand
                          {
                            name = "DeleteCommand", 
                            splitted = true,
                            single = true,
                            description = "DeleteCommand with all parameters",
                            hashChange = true,
                            params = {
                                        cmdID = 1,
                                     },
                          },
                          --PerformInteraction
                          {
                            name = "PerformInteraction", 
                            splitted = true,
                            single = false,
                            description = "PerformInteraction with all parameters",
                            hashChange = false,
                            params = {
                                        initialText = "StartPerformInteraction", --<param name="initialText" type="String" maxlength="500" >
                                        initialPrompt = {
                                                          --TTSChunk
                                                          {
                                                            text = "Makeyourchoice", --<param name="text" minlength="0" maxlength="500" type="String">
                                                            type = "TEXT", --<param name="type" type="SpeechCapabilities">
                                                          }
                                                      },
                                        interactionMode = "BOTH", --<param name="interactionMode" type="InteractionMode">:"MANUAL_ONLY" / "VR_ONLY" / "BOTH"
                                        interactionChoiceSetIDList = {2}, --<param name="interactionChoiceSetIDList" type="Integer" minsize="0" maxsize="100" minvalue="0" maxvalue="2000000000" array="true">
                                        helpPrompt = {--<param name="helpPrompt" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false">
                                                      --TTSChunk
                                                      {
                                                        text = "Choosethevarianton", --<param name="text" minlength="0" maxlength="500" type="String">
                                                        type = "TEXT", --<param name="type" type="SpeechCapabilities">
                                                      }
                                                    },
                                        timeoutPrompt = { --<param name="timeoutPrompt" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false">
                                                          --TTSChunk
                                                          {
                                                            text = "Timeisout", --<param name="text" minlength="0" maxlength="500" type="String">
                                                            type = "TEXT", --<param name="type" type="SpeechCapabilities">
                                                          }
                                                        },
                                        timeout = 5000, -- <param name="timeout" type="Integer" minvalue="5000" maxvalue="100000" defvalue="10000" mandatory="false">
                                        vrHelp = { --<param name="vrHelp" type="VrHelpItem" minsize="1" maxsize="100" array="true" mandatory="false">
                                                    -- VrHelpItem
                                                    {
                                                      text = "Help2",
                                                      -- SDL image verification failed
                                                      --image = {value = "action.png", imageType = "DYNAMIC"},
                                                      position = 1
                                                    }
                                                  },
                                        interactionLayout = "ICON_ONLY", --  "ICON_WITH_SEARCH" / "LIST_ONLY" / "LIST_WITH_SEARCH"  / "KEYBOARD"                                      
                                     },
                          },
                          --ChangeRegistration
                          {
                            name = "ChangeRegistration", 
                            splitted = true,
                            single = false,
                            description = "ChangeRegistration with all parameters",
                            hashChange = false,
                            params = {
                                        language = "EN-US",--<param name="language" type="Language" mandatory="true">
                                        hmiDisplayLanguage ="EN-US",--<param name="hmiDisplayLanguage" type="Language" mandatory="true">
                                        --appName ="SyncProxyTester",--<param name="appName" type="String" maxlength="100" mandatory="false">
                                        ttsName ={
                                                    {
                                                      text ="SyncProxyTester",
                                                      type ="TEXT"
                                                    }
                                                  },--<param name="ttsName" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false" >
                                        ngnMediaScreenAppName ="SPT",--<param name="ngnMediaScreenAppName" type="String" maxlength="100" mandatory="false">
                                        vrSynonyms = { "VRSyncProxyTester" },--<param name="vrSynonyms" type="String" maxlength="40" minsize="1" maxsize="100" array="true" mandatory="false">
                                     },
                          },
                          --Alert
                          {
                            name = "Alert",
                            splitted = true,
                            single = false,
                            description = "Alert with all parameters",
                            hashChange = false,
                            params = {
                                        alertText1 = "alertText1", --<param name="alertText1" type="String" maxlength="500" mandatory="false">
                                        alertText2 = "alertText2", --<param name="alertText2" type="String" maxlength="500" mandatory="false">
                                        alertText3 = "alertText3", --<param name="alertText3" type="String" maxlength="500" mandatory="false">
                                        ttsChunks = { --<param name="ttsChunks" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false">
                                                      { 
                                                        text = "TTSChunk",
                                                        type = "TEXT",
                                                      } 
                                                    },
                                        duration = 3000,
                                        playTone = false,
                                        progressIndicator = false,
                                        -- softButtons = { -- <param name="softButtons" type="SoftButton" minsize="0" maxsize="4" array="true" mandatory="false">
                                        --                 { 
                                        --                   type = "TEXT",
                                        --                   text = "Keep",
                                        --                   isHighlighted = true,
                                        --                   softButtonID = 4,
                                        --                   systemAction = "KEEP_CONTEXT",
                                        --                 }
                                        --               }
                                      }
                          },
                          --show
                          {
                            name = "Show",
                            -- APPLINK-28518 - RPC is not split
                            splitted = false,
                            single = true,
                            description = "Show with all parameters",
                            hashChange = false,
                            params = {
                                        mainField1 = "a",--<param name="mainField1" type="String" minlength="0" maxlength="500" mandatory="false">
                                        mainField2 = "a",--<param name="mainField2" type="String" minlength="0" maxlength="500" mandatory="false">
                                        mainField3 = "a",--<param name="mainField3" type="String" minlength="0" maxlength="500" mandatory="false">
                                        mainField4 = "a",--<param name="mainField4" type="String" minlength="0" maxlength="500" mandatory="false">
                                        alignment  = "CENTERED",--<param name="alignment" type="TextAlignment" mandatory="false">
                                        statusBar  = "a",--<param name="statusBar" type="String" minlength="0" maxlength="500" mandatory="false">
                                        mediaClock = "a",--<param name="mediaClock" type="String" minlength="0" maxlength="500" mandatory="false">
                                        mediaTrack = "a",--<param name="mediaTrack" type="String" minlength="0" maxlength="500" mandatory="false">
                                        graphic    = {--<param name="graphic" type="Image" mandatory="false">
                                                        imageType = "DYNAMIC",
                                                        value = "a"
                                                      },
                                        secondaryGraphic = {--<param name="secondaryGraphic" type="Image" mandatory="false">
                                                              imageType = "DYNAMIC",
                                                              value = "a"
                                                            }
                                        --softButtons = {},--<param name="softButtons" type="SoftButton" minsize="0" maxsize="8" array="true" mandatory="false">
                                        --customPresets = {}--<param name="customPresets" type="String" maxlength="500" minsize="0" maxsize="10" array="true" mandatory="false">
                          }
                          },
                          --AddSubMenu
                          {
                            name = "AddSubMenu",
                            -- APPLINK-28518 - RPC is not split
                            splitted = false,
                            single = true,
                            description = "AddSubMenu with all parameters",
                            hashChange = true,
                            params = {
                                        menuID = 1000,--<param name="menuID" type="Integer" minvalue="1" maxvalue="2000000000">
                                        position = 500,--<param name="position" type="Integer" minvalue="0" maxvalue="1000" defvalue="1000" mandatory="false">
                                        menuName = "SubMenupositive"--<param name="menuName" maxlength="500" type="String">
                                      }
                          },
                          --DeleteSubMenu
                          {
                            name = "DeleteSubMenu",
                            -- APPLINK-28518 - RPC is not split
                            splitted = false,
                            single = true,
                            description = "DeleteSubMenu with all parameters",
                            hashChange = true,
                            params = {
                                        menuID = 1000
                                      }
                          },
                          --SetMediaClockTimer
                          {
                            name = "SetMediaClockTimer",
                            -- APPLINK-28518 - RPC is not split
                            splitted = false,
                            single = true,
                            description = "SetMediaClockTimer with all parameters",
                            hashChange = false,
                            params = {
                                        startTime = {--<param name="startTime" type="StartTime" mandatory="false">
                                                      hours = 1,
                                                      minutes = 1,
                                                      seconds = 33
                                                    },
                                        endTime = {--<param name="endTime" type="StartTime" mandatory="false">
                                                    hours = 0,
                                                    minutes = 1 ,
                                                    seconds = 35
                                                  },
                                        updateMode = "COUNTDOWN"--<param name="updateMode" type="UpdateMode" mandatory="true">
                                    }
                          },
                          --SetGlobalProperties
                          {
                            name = "SetGlobalProperties",
                            splitted = true,
                            single = true,
                            description = "SetGlobalProperties with all parameters",
                            hashChange = true,
                            params = {
                                        helpPrompt = {--<param name="helpPrompt" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false" >
                                                        {
                                                          text = "Help prompt",
                                                          type = "TEXT"
                                                        }
                                                      },
                                        timeoutPrompt = { --<param name="timeoutPrompt" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false" >
                                                          {
                                                            text = "Timeout prompt",
                                                            type = "TEXT"
                                                          }
                                                        },
                                        vrHelpTitle = "VR help title",--<param name="vrHelpTitle" type="String" maxlength="500" mandatory="false">
                                        vrHelp = {--<param name="vrHelp" type="VrHelpItem" minsize="1" maxsize="100" array="true" mandatory="false">
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
                                        menuTitle = "Menu Title", --<param name="menuTitle" maxlength="500" type="String" mandatory="false">
                                        menuIcon = {--<param name="menuIcon" type="Image" mandatory="false">
                                                      value = "action.png",
                                                      imageType = "DYNAMIC"
                                                    },
                                        keyboardProperties = {--<param name="keyboardProperties" type="KeyboardProperties" mandatory="false">
                                                                keyboardLayout = "QWERTY",
                                                                keypressMode = "SINGLE_KEYPRESS",
                                                                limitedCharacterList = 
                                                                {
                                                                  "a"
                                                                },
                                                                language = "EN-US",
                                                                autoCompleteText = "Daemon, Freedom"
                                                              }
                                      }
                          },
                          --SetAppIcon
                          {
                            name = "SetAppIcon",
                            -- APPLINK-28518 - RPC is not split
                            splitted = false,
                            single = true,
                            description = "SetAppIcon with all parameters",
                            hashChange = false,
                            params = {
                                        syncFileName = "icon.png"--<param name="syncFileName" type="String" maxlength="500" mandatory="true">
                                      }
                          },
                          --SetDisplayLayout
                          {
                            name = "SetDisplayLayout",
                            -- APPLINK-28518 - RPC is not split
                            splitted = false,
                            single = true,
                            description = "SetDisplayLayout with all parameters",
                            hashChange = false,
                            params = {
                                        displayLayout = "ONSCREEN_PRESETS"--<param name="displayLayout" type="String" maxlength="500" mandatory="true">
                          }
                          },
                          --Slider
                          {
                            name = "Slider",
                            -- APPLINK-28518 - RPC is not split
                            splitted = false,
                            single = true,
                            description = "Slider with all parameters",
                            hashChange = false,
                            params = {
                                        numTicks = 3,--<param name="numTicks" type="Integer" minvalue="2" maxvalue="26" mandatory="true">
                                        position = 2,--<param name="position" type="Integer" minvalue="1" maxvalue="26" mandatory="true">
                                        sliderHeader ="sliderHeader",--<param name="sliderHeader" type="String" maxlength="500" mandatory="true">
                                        sliderFooter = {"1", "2", "3"},--<param name="sliderFooter" type="String" maxlength="500"  minsize="1" maxsize="26" array="true" mandatory="false">
                                        timeout = 5000--<param name="timeout" type="Integer" minvalue="1000" maxvalue="65535" defvalue="10000" mandatory="false">
                                      }
                          },
                          --ScrollableMessage
                          {
                            name = "ScrollableMessage",
                            -- APPLINK-28518 - RPC is not split
                            splitted = false,
                            single = true,
                            description = "ScrollableMessage with all parameters",
                            hashChange = false,
                            params = {
                                        scrollableMessageBody = "abc",--<param name="scrollableMessageBody" type="String" maxlength="500">
                                        timeout = 5000, --<param name="timeout" type="Integer" minvalue="1000" maxvalue="65535" defvalue="30000" mandatory="false">
                                        softButtons = {--<param name="softButtons" type="SoftButton" minsize="0" maxsize="8" array="true" mandatory="false">
                                                        {
                                                          softButtonID = 1,
                                                          text = "Button1",
                                                          type = "IMAGE",
                                                          image =
                                                          {
                                                            value = "action.png",
                                                            imageType = "DYNAMIC"
                                                          },
                                                          isHighlighted = false,
                                                          systemAction = "DEFAULT_ACTION"
                                                        }                                        
                                                      }
                                      }
                          },
                          --PerformAudioPassThru
                          {
                            name = "PerformAudioPassThru",
                            splitted = true,
                            single = false,
                            description = "PerformAudioPassThru with all parameters",
                            hashChange = false,
                            params = {
                                        initialPrompt = {----<param name="initialPrompt" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false">
                                                          {
                                                            text ="Makeyourchoice",
                                                            type ="TEXT",
                                                          }
                                                        },
                                        audioPassThruDisplayText1 ="DisplayText1",--<param name="audioPassThruDisplayText1" type="String" mandatory="false" maxlength="500">
                                        audioPassThruDisplayText2 ="DisplayText2",--<param name="audioPassThruDisplayText2" type="String" mandatory="false" maxlength="500">
                                        samplingRate ="8KHZ",--<param name="samplingRate" type="SamplingRate" mandatory="true">
                                        maxDuration = 2000,--<param name="maxDuration" type="Integer" minvalue="1" maxvalue="1000000" mandatory="true">
                                        bitsPerSample ="8_BIT",--<param name="bitsPerSample" type="BitsPerSample" mandatory="true">
                                        audioType ="PCM",--<param name="audioType" type="AudioType" mandatory="true">
                                        muteAudio = true--<param name="muteAudio" type="Boolean" mandatory="false">
                                      }
                          },
                          --EndAudioPassThru
                          {
                            name = "EndAudioPassThru",
                            -- APPLINK-28518 - RPC is not split
                            splitted = false,
                            single = true,
                            description = "EndAudioPassThru with all parameters",
                            hashChange = false,
                            --No params
                            params = { fakeparams = nil }
                          },
                          --Speak
                          {
                            name = "Speak",
                            splitted = false,
                            single = true,
                            description = "Speak with all parameters",
                            hashChange = false,
                            params = {
                                        ttsChunks = {
                                                      {
                                                        text ="a",
                                                        type ="TEXT"
                                                      }
                                                    }--<param name="ttsChunks" type="TTSChunk" minsize="1" maxsize="100" array="true">
                                      }
                          },
                          --ReadDID
                          {
                            name = "ReadDID",
                            splitted = false,
                            single = true,
                            description = "ReadDID with all parameters",
                            hashChange = false,
                            params = {
                                        ecuName = 2000, --<param name="ecuName" type="Integer" minvalue="0" maxvalue="65535" mandatory="true">
                                        didLocation = { 56832 }--<param name="didLocation" type="Integer" minvalue="0" maxvalue="65535" minsize="1" maxsize="1000" array="true" mandatory="true">
                                      }
                          },
                          --GetDTCs
                          {
                            name = "GetDTCs",
                            splitted = false,
                            single = true,
                            description = "GetDTCs with all parameters",
                            hashChange = false,
                            params = {
                                        ecuName = 0 --<param name="ecuName" type="Integer" minvalue="0" maxvalue="65535" mandatory="true">
                                        --<param name="dtcMask" type="Integer" minvalue="0" maxvalue="255" mandatory="false">
                                      }
                          },
                          --DiagnosticMessage
                          {
                            name = "DiagnosticMessage",
                            splitted = false,
                            single = true,
                            description = "DiagnosticMessage with all parameters",
                            hashChange = false,
                            params = {
                                        targetID = 42,    --<param name="targetID" type="Integer" minvalue="0" maxvalue="65535" mandatory="true">
                                        messageLength = 8,--<param name="messageLength" type="Integer" minvalue="0" maxvalue="65535" mandatory="true">
                                        messageData =  {1, 2, 3, 5, 6, 7, 9, 10, 24, 25, 34, 62} --<param name="messageData" type="Integer" minvalue="0" maxvalue="255" minsize="1" maxsize="65535" array="true" mandatory="true">
                                      }
                          },
                          --SubscribeVehicleData
                          {
                            name = "SubscribeVehicleData",
                            splitted = false,
                            single = true,
                            description = "SubscribeVehicleData with gps parameter",
                            hashChange = true,
                            params = {
                                        gps = true --<param name="gps" type="Boolean" mandatory="false">
                                      }
                          },
                          --GetVehicleData
                          {
                            name = "GetVehicleData",
                            splitted = false,
                            single = true,
                            description = "GetVehicleData with gps parameter",
                            hashChange = false,
                            params = {
                                        gps = true --<param name="gps" type="Boolean" mandatory="false">
                                      }
                          },
                          --UnsubscribeVehicleData
                          {
                            name = "UnsubscribeVehicleData",
                            splitted = false,
                            single = true,
                            description = "UnsubscribeVehicleData with gps parameter",
                            hashChange = true,
                            params = {
                                        gps = true --<param name="gps" type="Boolean" mandatory="false">
                                      }
                          },
                          --SendLocation
                          {
                            name = "SendLocation",
                            splitted = false,
                            single = true,
                            description = "SendLocation with all parameters",
                            hashChange = false,
                            params = {
                                        longitudeDegrees = 1.1,--<param name="longitudeDegrees" type="Double" minvalue="-180" maxvalue="180" mandatory="false">
                                        latitudeDegrees = 1.1, --<param name="latitudeDegrees" type="Double" minvalue="-90" maxvalue="90" mandatory="false">
                                        -- locationName = "location Name",-- <param name="locationName" type="String" maxlength="500" mandatory="false">
                                        -- locationDescription = "location Description", --<param name="locationDescription" type="String" maxlength="500" mandatory="false">
                                        -- addressLines = { 
                                        --                     "line1",
                                        --                     "line2",
                                        --                   },--<param name="addressLines" type="String" maxlength="500" minsize="0" maxsize="4" array="true" mandatory="false">
                                        -- phoneNumber = "phone Number",--<param name="phoneNumber" type="String" maxlength="500" mandatory="false">
                                        -- locationImage =  { -- <param name="locationImage" type="Image" mandatory="false">
                                        --                     value = "icon.png",
                                        --                     imageType = "DYNAMIC",
                                        --                   },
                                        -- timestamp = {--<param name="timeStamp" type="DateTime" mandatory="false">
                                        --               second = 40,
                                        --               minute = 30,
                                        --               hour = 14,
                                        --               day = 25,
                                        --               month = 5,
                                        --               year = 2017,
                                        --               tz_hour = 5,
                                        --               tz_minute = 30
                                        --             },
                                        -- address = {--<param name="address" type="OASISAddress" mandatory="false">
                                        --             countryName = "countryName",
                                        --             countryCode = "countryName",
                                        --             postalCode = "postalCode",
                                        --             administrativeArea = "administrativeArea",
                                        --             subAdministrativeArea = "subAdministrativeArea",
                                        --             locality = "locality",
                                        --             subLocality = "subLocality",
                                        --             thoroughfare = "thoroughfare",
                                        --             subThoroughfare = "subThoroughfare"
                                        --           },
                                        -- deliveryMode = "PROMPT"--<param name="deliveryMode" type="DeliveryMode" mandatory="false">
                                      }
                          },
                          --ShowConstantTBT
                          {
                            name = "ShowConstantTBT",
                            splitted = false,
                            single = true,
                            description = "ShowConstantTBT with gps parameter",
                            hashChange = false,
                            params = {
                                        navigationText1 ="navigationText1",--<param name="navigationText1" type="String" minlength="0" maxlength="500" mandatory="false">
                                        navigationText2 ="navigationText2",--<param name="navigationText2" type="String" minlength="0" maxlength="500" mandatory="false">
                                        eta ="12:34",--<param name="eta" type="String" minlength="0" maxlength="500" mandatory="false">
                                        --<param name="timeToDestination" type="String" minlength="0" maxlength="500" mandatory="false">
                                        totalDistance ="100miles",--<param name="totalDistance" type="String" minlength="0" maxlength="500" mandatory="false">
                                        turnIcon = {--<param name="turnIcon" type="Image" mandatory="false">
                                                      value ="icon.png",
                                                      imageType ="DYNAMIC",
                                                    },
                                        nextTurnIcon = {--<param name="nextTurnIcon" type="Image" mandatory="false">
                                                          value ="action.png",
                                                          imageType ="DYNAMIC",
                                                        },
                                        distanceToManeuver = 50.5, --<param name="distanceToManeuver" type="Float" minvalue="0" maxvalue="1000000000" mandatory="false">
                                        distanceToManeuverScale = 100.5, --<param name="distanceToManeuverScale" type="Float" minvalue="0" maxvalue="1000000000" mandatory="false">
                                        maneuverComplete = false, --<param name="maneuverComplete" type="Boolean" mandatory="false">
                                        softButtons = { --<param name="softButtons" type="SoftButton" minsize="0" maxsize="3" array="true" mandatory="false">
                                                        {
                                                          type ="BOTH",
                                                          text ="Close",
                                                          image =
                                                          {
                                                            value ="icon.png",
                                                            imageType ="DYNAMIC",
                                                          },
                                                          isHighlighted = true,
                                                          softButtonID = 44,
                                                          systemAction ="DEFAULT_ACTION",
                                                        },
                                                      }
                                      }
                          },
                          --AlertManeuver
                          {
                            name = "AlertManeuver",
                            splitted = true,
                            single = false,
                            description = "AlertManeuver with gps parameter",
                            hashChange = false,
                            params = {
                                        ttsChunks = { --<param name="ttsChunks" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false">
                                                      { 
                                                        text ="FirstAlert",
                                                        type ="TEXT",
                                                      }, 
                                                      { 
                                                        text ="SecondAlert",
                                                        type ="TEXT",
                                                      }, 
                                                    }, 
                                        softButtons = { --<param name="softButtons" type="SoftButton" minsize="0" maxsize="3" array="true" mandatory="false">
                                                        { 
                                                          type = "BOTH",
                                                          text = "Close",
                                                           image = 
                                                           { 
                                                             value = "icon.png",
                                                             imageType = "DYNAMIC",
                                                          }, 
                                                          isHighlighted = true,
                                                          softButtonID = 821,
                                                          systemAction = "DEFAULT_ACTION",
                                                        }, 
                                                        { 
                                                          type = "BOTH",
                                                          text = "AnotherClose",
                                                          image = 
                                                          { 
                                                            value = "icon.png",
                                                            imageType = "DYNAMIC",
                                                          }, 
                                                          isHighlighted = false,
                                                          softButtonID = 822,
                                                          systemAction = "DEFAULT_ACTION",
                                                        }
                                                      }
                                        
                                      }
                          },
                          --UpdateTurnList
                          {
                            name = "UpdateTurnList",
                            splitted = false,
                            single = true,
                            description = "UpdateTurnList with gps parameter",
                            hashChange = false,
                            params = { 
                                        turnList = { --<param name="turnList" type="Turn" minsize="1" maxsize="100" array="true" mandatory="false">
                                                      {
                                                        navigationText ="Text",
                                                        turnIcon =
                                                        {
                                                          value ="icon.png",
                                                          imageType ="DYNAMIC",
                                                        }
                                                      }
                                                    },
                                        softButtons = { --<param name="softButtons" type="SoftButton" minsize="0" maxsize="1" array="true" mandatory="false">
                                                        {
                                                          type ="BOTH",
                                                          text ="Close",
                                                          image =
                                                          {
                                                            value ="icon.png",
                                                            imageType ="DYNAMIC",
                                                          },
                                                          isHighlighted = true,
                                                          softButtonID = 111,
                                                          systemAction ="DEFAULT_ACTION",
                                                        }
                                                      }
                                      }
                          },
                          --GetWayPoints
                          {
                            name = "GetWayPoints",
                            splitted = false,
                            single = true,
                            description = "GetWayPoints with all parameters",
                            hashChange = false,
                            params = { wayPointType = "ALL" }
                          },
                          --SubscribeWayPoints
                          {
                            name = "SubscribeWayPoints",
                            splitted = false,
                            single = true,
                            description = "SubscribeWayPoints with all parameters",
                            hashChange = true,
                            params = { }--no parameters 
                          },
                          --UnsubscribeWayPoints
                          {
                            name = "UnsubscribeWayPoints",
                            splitted = false,
                            single = true,
                            description = "UnsubscribeWayPoints with all parameters",
                            hashChange = true,
                            params = { }-- no parameters 
                          },
                          --StartStream
                          {
                            name = "StartStream",
                            splitted = false,
                            single = true,
                            description = "StartStream as result of StartService(11)",
                            hashChange = false,
                            params = { }-- no parameters 
                          },
                          --StopStream
                          {
                            name = "StopStream",
                            splitted = false,
                            single = true,
                            description = "StartStream as result of StartService(11)",
                            hashChange = false,
                            params = { }-- no parameters 
                          },
                          --StartAudioStream
                          {
                            name = "StartAudioStream",
                            splitted = false,
                            single = true,
                            description = "StartAudioStream as result of StartService(11)",
                            hashChange = false,
                            params = { }-- no parameters 
                          },
                          --StopAudioStream
                          {
                            name = "StopAudioStream",
                            splitted = false,
                            single = true,
                            description = "StopAudioStream as result of StartService(11)",
                            hashChange = false,
                            params = { }-- no parameters 
                          },
                          --StopSpeaking
                          {
                            name = "StopSpeaking",
                            splitted = true,
                            -- APPLINK-29183: StopSpeaking is part of SplitRPC
                            single = false,
                            description = "StopSpeaking with all parameters",
                            hashChange = false,
                            params = {
                                        ttsChunks = {
                                                      {
                                                        text ="a",
                                                        type ="TEXT"
                                                      }
                                                    }--<param name="ttsChunks" type="TTSChunk" minsize="1" maxsize="100" array="true">
                                      }
                          }
                          -- GetSupportedLanguages is not sent by application
                            --Checked in initHMI_onReady_Interfaces_IsReady
                              -- <description>Method is invoked at system start-up by SDL. Response must provide the information about TTS supported languages.</description> 
                              -- Tested at InitHMIOnReady but only at side SLD <-> HMI
                          -- GetLanguage is not sent by application
                            --Checked in initHMI_onReady_Interfaces_IsReady
                              -- <description>Request from SmartDeviceLink to HMI to get currently active  VR language</description>
                              -- Tested at InitHMIOnReady but only at side SLD <-> HMI
                          -- GetCapabilities is not sent by application
                            --Checked in initHMI_onReady_Interfaces_IsReady
                              -- <description>Method is invoked at system start-up. SDL requests the information about all supported hardware buttons and their capabilities</description>
                              -- Tested at InitHMIOnReady but only at side SLD <-> HMI
                          -- ClosePopUp is not sent by application
                          -- GetVehicleType is not sent by application
                            --Checked in initHMI_onReady_Interfaces_IsReady
                          --TTS.Started / TTS.Stoped are notifications sent by HMI. Not in scope of CRQ testing TTS interface. Behaviour is checked in RPC Alert.
                        }

interfaces.RPC = {
                    --VR
                    {
                      interface = "VR",
                      usedRPC = {
                                  --AddCommand
                                  {
                                    name = "AddCommand",
                                    splitted = true,
                                    params = {
                                                cmdID = 1,
                                                vrCommands = { "vrCommands_1" },
                                                type = "Command",
                                                --grammarID = 1, --  <param name="grammarID" type="Integer" minvalue="0" maxvalue="2000000000" mandatory="true">
                                                appID = 1 -- will be assigned during the test: self.applications[config.application1.registerAppInterfaceParams.appName]
                                              }
                                  },
                                  --DeleteCommand
                                  {
                                    name = "DeleteCommand",
                                    splitted = true,
                                    params = {
                                                cmdID = 1,
                                                type = "Command",
                                                grammarID = 1,
                                                appID = 1 -- will be assigned during the test: self.applications[config.application1.registerAppInterfaceParams.appName]
                                              }
                                  },
                                  --PerformInteraction
                                  {
                                    name = "PerformInteraction",
                                    splitted = true,
                                    params = {
                                                helpPrompt = {--<param name="helpPrompt" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false">
                                                                --TTSChunk
                                                                {
                                                                  text = "Choosethevarianton", --<param name="text" minlength="0" maxlength="500" type="String">
                                                                  type = "TEXT", --<param name="type" type="SpeechCapabilities">
                                                                }
                                                              },
                                                initialPrompt = {
                                                                  --TTSChunk
                                                                  {
                                                                    text = "Makeyourchoice", --<param name="text" minlength="0" maxlength="500" type="String">
                                                                    type = "TEXT", --<param name="type" type="SpeechCapabilities">
                                                                  }
                                                                },               
                                                timeoutPrompt = { --<param name="timeoutPrompt" type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false">
                                                                  --TTSChunk
                                                                  {
                                                                    text = "Timeisout", --<param name="text" minlength="0" maxlength="500" type="String">
                                                                    type = "TEXT", --<param name="type" type="SpeechCapabilities">
                                                                  }
                                                                },
                                                timeout = 5000, 
                                                grammarID = {1},--<param name="grammarID" type="Integer" minvalue="0" maxvalue="2000000000" minsize="1" maxsize="100" array="true" mandatory="false">
                                                appID = 1
                                              }
                                  },
                                  --ChangeRegistration
                                  {
                                    name = "ChangeRegistration",
                                    splitted = true,
                                    params = {
                                                vrSynonyms = { "VRSyncProxyTester" }, --<param name="vrSynonyms" type="String" maxlength="40" minsize="1" maxsize="100" array="true" mandatory="false">
                                                language =  "EN-US",--<param name="language" type="Common.Language" mandatory="true">
                                                appID = 1
                                              }
                                  },
                                  --Alert
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Show
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --AddSubMenu
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --DeleteSubMenu
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetMediaClockTimer
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetGlobalProperties
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetAppIcon
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetDisplayLayout
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Slider
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ScrollableMessage
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --PerformAudioPassThru
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --EndAudioPassThru
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Speak
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ReadDID
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --GetDTCs
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --DiagnosticMessage
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SubscribeVehicleData
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --GetVehicleData
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --UnsubscribeVehicleData
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SendLocation
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                   --ShowConstantTBT
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --AlertManeuver
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --UpdateTurnList
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --GetWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SubscribeWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --UnsubscribeWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StartStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StartAudioStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopAudioStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopSpeaking
                                  {

                                    name = "Not applicable"
                                  },
                                  --Started
                                  {
                                   
                                    name = "Not applicable"
                                  },
                                  --Stopped
                                  {
                                    name = "Not applicable"
                                  }
                                          
                                }
                    },
                    -- UI
                    {
                      interface = "UI",
                      usedRPC = {
                                  --AddCommand
                                  {
                                    name = "AddCommand",
                                    splitted = true,
                                    params = {
                                                cmdID = 1,
                                                menuParams = {position = 1, menuName ="Command 1"},
                                                --Problem with storage folder
                                                --cmdIcon = { value = "icon.png", imageType = "DYNAMIC" },
                                                appID = 1 -- will be assigned during the test: self.applications[config.application1.registerAppInterfaceParams.appName]
                                              }
                                  },
                                  --DeleteCommand
                                  {
                                    name = "DeleteCommand",
                                    splitted = true,
                                    params = {
                                              cmdID = 1,
                                              appID = 1 -- will be assigned during the test: self.applications[config.application1.registerAppInterfaceParams.appName]
                                            }
                                  },
                                  --PerformInteraction
                                  {
                                    name = "PerformInteraction",
                                    splitted = true,
                                    params = {
                                                initialText = {
                                                                  fieldName = "initialInteractionText",
                                                                  fieldText = "StartPerformInteraction"
                                                                  
                                                                },  
                                                choiceSet = {
                                                              { choiceID = 2, menuName = "Choice2" }
                                                            },
                                                vrHelpTitle = "StartPerformInteraction",
                                                vrHelp = { --<param name="vrHelp" type="Common.VrHelpItem" minsize="1" maxsize="100" array="true" mandatory="false">
                                                            {
                                                              text = "Help2", 
                                                              position = 1, 
                                                            }
                                                          },
                                                timeout = 5000,   
                                                interactionLayout = "ICON_ONLY", -- <param name="interactionLayout" type="Common.LayoutMode" mandatory="false">
                                                appID = 1
                                              }
                                  },
                                  --ChangeRegistration
                                  {
                                    name = "ChangeRegistration",
                                    splitted = true,
                                    params = {
                                                --appName = "SyncProxyTester",
                                                ngnMediaScreenAppName = "SPT",
                                                language =  "EN-US",--<param name="language" type="Common.Language" mandatory="true">
                                                -- APPPLINK-28533: verification of this parameter is not in scope of CRQs
                                                --appHMIType = "MEDIA",
                                                appID = 1                                            
                                              }
                                  },
                                  --Alert
                                  {
                                    
                                    name = "Alert",
                                    splitted = true, -- TTS.Speak - the second RPC
                                    params = {
                                                alertStrings = 
                                                                {
                                                                  {fieldName = "alertText1", fieldText = "alertText1"},
                                                                  {fieldName = "alertText2", fieldText = "alertText2"},
                                                                  {fieldName = "alertText3", fieldText = "alertText3"}
                                                                },
                                                alertType = "BOTH",
                                                duration = 3000,
                                                progressIndicator = false,
                                                -- softButtons = {
                                                --                 { 
                                                --                   type = "TEXT",
                                                --                   text = "Keep",
                                                --                   isHighlighted = true,
                                                --                   softButtonID = 4,
                                                --                   systemAction = "KEEP_CONTEXT"
                                                --                 }
                                                --               }
                                              }
                                  },
                                  --Show
                                  {
                                    
                                    name = "Show",
                                    splitted = false,
                                    params = {
                                                --showStrings = {"a"},--
                                                alignment = "CENTERED",
                                                graphic = {
                                                            imageType = "DYNAMIC",
                                                            --as verification should be done with ValidIf and is not in scope of these CRQ
                                                            --value = "a"
                                                          },
                                                secondaryGraphic = {
                                                                      imageType = "DYNAMIC",
                                                                      --as verification should be done with ValidIf and is not in scope of these CRQ
                                                                      --value = "a"
                                                                    },
                                                --softButtons,
                                                --customPresets,
                                                appID = 1
                                              }
                                  },
                                  --AddSubMenu
                                  {
                                    
                                    name = "AddSubMenu",
                                    splitted = false,
                                    params = {
                                                menuID = 1000,
                                                menuParams ={
                                                              position = 500,
                                                              menuName ="SubMenupositive"
                                                            },
                                                appID = 1
                                              }
                                  },
                                  --DeleteSubMenu
                                  {
                                    
                                    name = "DeleteSubMenu",
                                    splitted = false,
                                    params = {
                                                menuID = 1000,
                                                appID = 1
                                              }
                                  },
                                  --SetMediaClockTimer
                                  {
                                    
                                    name = "SetMediaClockTimer",
                                    splitted = false,
                                    params = {
                                                startTime = {--<param name="startTime" type="StartTime" mandatory="false">
                                                              hours = 1,
                                                              minutes = 1,
                                                              seconds = 33
                                                            },
                                                endTime = {--<param name="endTime" type="StartTime" mandatory="false">
                                                            hours = 0,
                                                            minutes = 1,
                                                            seconds = 35
                                                          },
                                                updateMode = "COUNTDOWN",--<param name="updateMode" type="UpdateMode" mandatory="true">
                                                appID = 1
                                              }
                                  },
                                  --SetGlobalProperties
                                  {
                                    
                                    name = "SetGlobalProperties",
                                    splitted = false,
                                    params = {
                                                vrHelpTitle = "VR help title",--<param name="vrHelpTitle" type="String" maxlength="500" mandatory="false">
                                                vrHelp = {--<param name="vrHelp" type="Common.VrHelpItem" minsize="1" maxsize="100" array="true" mandatory="false">
                                                            {
                                                              position = 1,
                                                              image = 
                                                              {
                                                                imageType = "DYNAMIC",
                                                                --as verification should be done with ValidIf and is not in scope of these CRQ
                                                                --value = storagePath .. "action.png"
                                                              },
                                                              text = "VR help item"
                                                            }
                                                          },
                                                menuTitle = "Menu Title",--<param name="menuTitle" maxlength="500" type="String" mandatory="false">                                                
                                                menuIcon = {--<param name="menuIcon" type="Common.Image" mandatory="false">
                                                              imageType = "DYNAMIC",
                                                              -- as verification should be done with ValidIf and is not in scope of these CRQ
                                                              -- value = strAppFolder .. "action.png"
                                                            },
                                                keyboardProperties = { --<param name="keyboardProperties" type="Common.KeyboardProperties" mandatory="false">
                                                                        keyboardLayout = "QWERTY",
                                                                        keypressMode = "SINGLE_KEYPRESS",
                                                                        limitedCharacterList = {"a"},
                                                                        language = "EN-US",
                                                                        autoCompleteText = "Daemon, Freedom"
                                                                      },
                                                appID = 1
                                              }
                                  },
                                  --SetAppIcon
                                  {
                                    
                                    name = "SetAppIcon",
                                    splitted = false,
                                    params = {
                                                syncFileName = {--<param name="syncFileName" type="Common.Image" mandatory="true">
                                                                  imageType = "DYNAMIC",
                                                                  -- as verification should be done with ValidIf and is not in scope of these CRQ
                                                                  -- value = storagePath .. "icon.png"
                                                                } ,
                                                appID = 1
                                              }
                                  },
                                  --SetDisplayLayout
                                  {
                                    
                                    name = "SetDisplayLayout",
                                    splitted = false,
                                    params = {
                                                displayLayout = "ONSCREEN_PRESETS", --<param name="displayLayout" type="String" maxlength="500" mandatory="true">
                                                appID = 1
                                              }
                                  },
                                  --Slider
                                  {
                                    name = "Slider",
                                    splitted = false,
                                    params = {
                                                numTicks = 3,--<param name="numTicks" type="Integer" minvalue="2" maxvalue="26" mandatory="true">
                                                position = 2,--<param name="position" type="Integer" minvalue="1" maxvalue="26" mandatory="true">
                                                sliderHeader ="sliderHeader",---<param name="sliderHeader" type="String" maxlength="500" mandatory="true">
                                                sliderFooter = {"1", "2", "3"},--<param name="sliderFooter" type="String" maxlength="500"  minsize="1" maxsize="26" array="true" mandatory="false">
                                                timeout = 5000,--<param name="timeout" type="Integer" minvalue="1000" maxvalue="65535" mandatory="true">
                                                appID = 1
                                              }
                                  },
                                  --ScrollableMessage
                                  {
                                    name = "ScrollableMessage",
                                    splitted = false,
                                    params = {
                                                messageText ={ --<param name="messageText" type="Common.TextFieldStruct" mandatory="true">
                                                                fieldName = "scrollableMessageBody",
                                                                fieldText = "abc"
                                                              },
                                                timeout = 5000,--<param name="timeout" type="Integer" minvalue="0" maxvalue="65535" mandatory="true">
                                                softButtons = {--<param name="softButtons" type="Common.SoftButton" minsize="0" maxsize="8" array="true" mandatory="false">
                                                                {
                                                                  softButtonID = 1,
                                                                  --text = "Button1",
                                                                  type = "IMAGE",
                                                                  image =
                                                                  {
                                                                    -- as verification should be done with ValidIf and is not in scope of these CRQ
                                                                    --value = "action.png",
                                                                    imageType = "DYNAMIC"
                                                                  },
                                                                  isHighlighted = false,
                                                                  systemAction = "DEFAULT_ACTION"
                                                                }                                        
                                                              },
                                                appID = 1
                                              }
                                  },
                                  --PerformAudioPassThru
                                  {
                                    name = "PerformAudioPassThru",
                                    splitted = true, --TTS.Speak
                                    params = {
                                                appID = 1,
                                                audioPassThruDisplayTexts = {--<param name="audioPassThruDisplayTexts" type="Common.TextFieldStruct" mandatory="true" minsize="0" maxsize="2" array="true">
                                                                              {
                                                                                fieldName = "audioPassThruDisplayText1",
                                                                                fieldText = "DisplayText1"
                                                                              },
                                                                              {
                                                                                fieldName = "audioPassThruDisplayText2",
                                                                                fieldText = "DisplayText2"
                                                                              }
                                                                            },
                                                maxDuration = 2000,--<param name="maxDuration" type="Integer" minvalue="1" maxvalue="1000000" mandatory="true">
                                                muteAudio = true-- <param name="muteAudio" type="Boolean" mandatory="true">
                                              }
                                  },
                                  --EndAudioPassThru
                                  {
                                    name = "EndAudioPassThru",
                                    splitted = false,
                                    --No params
                                    params = {fakeparams = nil}
                                  },
                                  --Speak
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ReadDID
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --GetDTCs
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --DiagnosticMessage
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SubscribeVehicleData
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --GetVehicleData
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --UnsubscribeVehicleData
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SendLocation
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ShowConstantTBT
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --AlertManeuver
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --UpdateTurnList
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --GetWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SubscribeWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --UnsubscribeWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StartStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StartAudioStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopAudioStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopSpeaking
                                  {

                                    name = "Not applicable"
                                  },
                                }
                    },
                    --TTS
                    {
                      interface = "TTS",
                      usedRPC = {
                                  --AddCommand
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --DeleteCommand
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --PerformInteraction
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ChangeRegistration
                                  {
                                    name = "ChangeRegistration",
                                    splitted = true,
                                    params = {
                                                ttsName = {
                                                            {
                                                              text ="SyncProxyTester",
                                                              type = "TEXT"
                                                            }
                                                          },
                                                language =  "EN-US",--<param name="language" type="Common.Language" mandatory="true">
                                                appID = 1
                                              }
                                  },
                                  --Alert
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Show
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --AddSubMenu
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --DeleteSubMenu
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetMediaClockTimer
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetGlobalProperties
                                  {
                                    
                                    name = "SetGlobalProperties",
                                    splitted = false,
                                    params = {
                                                timeoutPrompt = {
                                                                  {
                                                                    text = "Timeout prompt",
                                                                    type = "TEXT"
                                                                  }
                                                                },
                                                helpPrompt = {
                                                               {
                                                                  text = "Help prompt",
                                                                  type = "TEXT"
                                                                }
                                                              },
                                                appID = 1
                                              }
                                  },
                                  --SetAppIcon
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetDisplayLayout
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Slider
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ScrollableMessage
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --PerformAudioPassThru
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --EndAudioPassThru
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Speak
                                  {
                                    
                                    name = "Speak",
                                    splitted = false,
                                    params = {
                                                appID = 1,
                                                ttsChunks = {--<param name="ttsChunks" type="Common.TTSChunk" mandatory="true" array="true" minsize="1" maxsize="100">
                                                              {
                                                                text ="a",
                                                                type ="TEXT"
                                                              }
                                                            }
                                              }
                                  },
                                  --ReadDID
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --GetDTCs
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --DiagnosticMessage
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SubscribeVehicleData
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --GetVehicleData
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --UnsubscribeVehicleData
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SendLocation
                                  {
                                    
                                    name = "Not applicable"
                                  }, 
                                  --ShowConstantTBT
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --AlertManeuver
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --UpdateTurnList
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --GetWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SubscribeWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --UnsubscribeWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StartStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StartAudioStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopAudioStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopSpeaking
                                  {

                                    name = "StopSpeaking",
                                    splitted = false,
                                    params = {""}
                                  }
                                }
                    },
                    --VehicleInfo
                    {
                      interface = "VehicleInfo",
                      usedRPC = {
                                  --AddCommand
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --DeleteCommand
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --PerformInteraction
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ChangeRegistration
                                  {

                                    name = "Not applicable"
                                  },
                                  --Alert
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Show
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --AddSubMenu
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --DeleteSubMenu
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetMediaClockTimer
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetGlobalProperties
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetAppIcon
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetDisplayLayout
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Slider
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ScrollableMessage
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --PerformAudioPassThru
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --EndAudioPassThru
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Speak
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ReadDID
                                  {
                                    
                                    name = "ReadDID",
                                    splitted = false,
                                    params = {
                                                ecuName = 2000, --<param name="ecuName" type="Integer" minvalue="0" maxvalue="65535" mandatory="true">
                                                didLocation = { 56832 }--<param name="didLocation" type="Integer" minvalue="0" maxvalue="65535" minsize="1" maxsize="1000" array="true" mandatory="true">
                                              }
                                  },
                                  --GetDTCs
                                  {
                                    name = "GetDTCs",
                                    splitted = false,
                                    params = {
                                                ecuName = 0, --<param name="ecuName" type="Integer" minvalue="0" maxvalue="65535" mandatory="true">
                                                --<param name="dtcMask" type="Integer" minvalue="0" maxvalue="255" mandatory="false">
                                                appID = 1 
                                              },
                                    mandatory_params = {
                                                          ecuHeader = 2
                                                        },
                                    string_mandatory_params = ' "ecuHeader":2'
                                  },
                                  --DiagnosticMessage
                                  {
                                    name = "DiagnosticMessage",
                                    splitted = false,
                                    params = {
                                                targetID = 42,    --<param name="targetID" type="Integer" minvalue="0" maxvalue="65535" mandatory="true">
                                                messageLength = 8,--<param name="messageLength" type="Integer" minvalue="0" maxvalue="65535" mandatory="true">
                                                messageData =  {1, 2, 3, 5, 6, 7, 9, 10, 24, 25, 34, 62}, --<param name="messageData" type="Integer" minvalue="0" maxvalue="255" minsize="1" maxsize="65535" array="true" mandatory="true">
                                                appID = 1--<param name="appID" type="Integer" mandatory="true">
                                              },
                                    mandatory_params = {
                                                          messageDataResult = {200}
                                                        },
                                    string_mandatory_params = ' "messageDataResult":[200]'
                                  },
                                  --SubscribeVehicleData
                                  {
                                    name = "SubscribeVehicleData",
                                    splitted = false,
                                    params = { gps = true }
                                  },
                                  --GetVehicleData
                                  {
                                    name = "GetVehicleData",
                                    splitted = false,
                                    params = { gps = true }
                                  },
                                  --UnsubscribeVehicleData
                                  {
                                    name = "UnsubscribeVehicleData",
                                    splitted = false,
                                    params = { gps = true }
                                  },
                                  --SendLocation
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ShowConstantTBT
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --AlertManeuver
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --UpdateTurnList
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --GetWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SubscribeWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --UnsubscribeWayPoints
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StartStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StartAudioStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopAudioStream
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --StopSpeaking
                                  {

                                    name = "Not applicable"
                                  },
                                  
                                }
                    },
                    --Navigation
                    {
                      interface = "Navigation",
                      usedRPC = {
                                  --AddCommand
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --DeleteCommand
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --PerformInteraction
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ChangeRegistration
                                  {

                                    name = "Not applicable"
                                  },
                                  --Alert
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Show
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --AddSubMenu
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --DeleteSubMenu
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetMediaClockTimer
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetGlobalProperties
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetAppIcon
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --SetDisplayLayout
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Slider
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ScrollableMessage
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --PerformAudioPassThru
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --EndAudioPassThru
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --Speak
                                  {
                                    
                                    name = "Not applicable"
                                  },
                                  --ReadDID
                                  {
                                                                        
                                    name = "Not applicable"
                                  },
                                  --GetDTCs
                                  {
                                                                       
                                    name = "Not applicable"
                                  },
                                  --DiagnosticMessage
                                  {
                                                                        
                                    name = "Not applicable"
                                  },
                                  --SubscribeVehicleData
                                  {
                                                                        
                                    name = "Not applicable"
                                  },
                                  --GetVehicleData
                                  {
                                                                        
                                    name = "Not applicable"
                                  },
                                  --UnsubscribeVehicleData
                                  {
                                                                        
                                    name = "Not applicable"
                                  },
                                  --SendLocation
                                  {
                                    name = "SendLocation",
                                    splitted = false,
                                    params = { 
                                                appID = 1,--<param name="appID" type="Integer" mandatory="true">
                                                longitudeDegrees = 1.1,--<param name="longitudeDegrees" type="Float" minvalue="-180" maxvalue="180" mandatory="false">
                                                latitudeDegrees = 1.1, --<param name="latitudeDegrees" type="Float" minvalue="-90" maxvalue="90" mandatory="false">
                                                -- locationName = "location Name",--<param name="locationName" type="String" maxlength="500" mandatory="false">
                                                -- locationDescription = "location Description",--<param name="locationDescription" type="String" maxlength="500" mandatory="false">
                                                -- addressLines = { --<param name="addressLines" type="String" maxlength="500" minsize="0" maxsize="4" array="true" mandatory="false">
                                                --                  "line1",
                                                --                  "line2",
                                                --                },
                                                -- phoneNumber = "phone Number",--<param name="phoneNumber" type="String" maxlength="500" mandatory="false">
                                                -- locationImage =  { --<param name="locationImage" type="Common.Image" mandatory="false">
                                                --                    value = "icon.png",
                                                --                    imageType = "DYNAMIC",
                                                --                  },
                                                -- timestamp = {--<param name="timeStamp" type="Common.DateTime" mandatory="false">
                                                --               second = 40,
                                                --               minute = 30,
                                                --               hour = 14,
                                                --               day = 25,
                                                --               month = 5,
                                                --               year = 2017,
                                                --               tz_hour = 5,
                                                --               tz_minute = 30
                                                --             },
                                                --  address = {--<param name="address" type="Common.OASISAddress" mandatory="false">
                                                --               countryName = "countryName",
                                                --               countryCode = "countryName",
                                                --               postalCode = "postalCode",
                                                --               administrativeArea = "administrativeArea",
                                                --               subAdministrativeArea = "subAdministrativeArea",
                                                --               locality = "locality",
                                                --               subLocality = "subLocality",
                                                --               thoroughfare = "thoroughfare",
                                                --               subThoroughfare = "subThoroughfare"
                                                --             },
                                                -- deliveryMode = "PROMPT"--<param name="deliveryMode" type="Common.DeliveryMode" mandatory="false">
                                            }
                                  },
                                  --ShowConstantTBT
                                  {
                                    name = "ShowConstantTBT",
                                    splitted = false,
                                    params = { 
                                                navigationTexts = { --<param name="navigationTexts" type="Common.TextFieldStruct" mandatory="true" array="true" minsize="0" maxsize="5">
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
                                                                    }
                                                                  },
                                                turnIcon = {-- <param name="turnIcon" type="Common.Image" mandatory="false">
                                                              --as verification should be done with ValidIf and is not in scope of these CRQ
                                                              --value ="icon.png",
                                                              imageType ="DYNAMIC",
                                                            },
                                                nextTurnIcon = {-- <param name="nextTurnIcon" type="Common.Image" mandatory="false">
                                                                  --as verification should be done with ValidIf and is not in scope of these CRQ
                                                                  --value ="action.png",
                                                                  imageType ="DYNAMIC",
                                                                },                                                
                                                distanceToManeuver = 50.5,--<param name="distanceToManeuver" type="Float" minvalue="0" maxvalue="1000000000" mandatory="true">
                                                distanceToManeuverScale = 100.5,--<param name="distanceToManeuverScale" type="Float" minvalue="0" maxvalue="1000000000" mandatory="true">
                                                maneuverComplete = false,--<param name="maneuverComplete" type="Boolean" mandatory="false">
                                                -- softButtons = { --<param name="softButtons" type="Common.SoftButton" minsize="0" maxsize="3" array="true" mandatory="false">
                                                --                 type ="BOTH",
                                                --                 text ="Close",
                                                --                 image =
                                                --                 {
                                                --                   --as verification should be done with ValidIf and is not in scope of these CRQ
                                                --                   --value ="icon.png",
                                                --                   imageType ="DYNAMIC",
                                                --                 },
                                                --                 isHighlighted = true,
                                                --                 softButtonID = 44,
                                                --                 systemAction ="DEFAULT_ACTION",
                                                --               },
                                                appID = 1--<param name="appID" type="Integer" mandatory="true">
                                              }
                                  },
                                  --AlertManeuver
                                  {
                                    name = "AlertManeuver",
                                    splitted = false,
                                    params = {
                                                softButtons = {--<param name="softButtons" type="Common.SoftButton" minsize="0" maxsize="3" array="true" mandatory="false">
                                                                { 
                                                                  type = "BOTH",
                                                                  text = "Close",
                                                                  -- image = 
                                                                  -- { 
                                                                  --   value = pathToIconFolder .. "/icon.png",
                                                                  --   imageType = "DYNAMIC",
                                                                  -- },
                                                                  isHighlighted = true,
                                                                  softButtonID = 821,
                                                                  systemAction = "DEFAULT_ACTION",
                                                                }, 
                                                                { 
                                                                  type = "BOTH",
                                                                  text = "AnotherClose",
                                                                  -- image = 
                                                                  -- { 
                                                                  --   value = pathToIconFolder.. "/icon.png",
                                                                  --   imageType = "DYNAMIC",
                                                                  -- },
                                                                  isHighlighted = false,
                                                                  softButtonID = 822,
                                                                  systemAction = "DEFAULT_ACTION",
                                                                } 
                                                              },
                                                appID = 1 --<param name="appID" type="Integer" mandatory="true"> }
                                              }
                                  },
                                  --UpdateTurnList
                                  {
                                    name = "UpdateTurnList",
                                    splitted = false,
                                    params = {
                                                -- turnList = { --<param name="turnList" type="Common.Turn" minsize="1" maxsize="100" array="true" mandatory="false">
                                                --               {
                                                --                 navigationText ="Text",
                                                --                 -- turnIcon =
                                                --                 -- {
                                                --                 --   value ="icon.png",
                                                --                 --   imageType ="DYNAMIC",
                                                --                 -- }
                                                --               }
                                                --             },
                                                softButtons = { --<param name="softButtons" type="Common.SoftButton" minsize="0" maxsize="1" array="true" mandatory="false">
                                                              {
                                                                type ="BOTH",
                                                                text ="Close",
                                                                -- image =
                                                                -- {
                                                                --   value ="icon.png",
                                                                --   imageType ="DYNAMIC",
                                                                -- },
                                                                isHighlighted = true,
                                                                softButtonID = 111,
                                                                systemAction ="DEFAULT_ACTION",
                                                              }
                                                            },
                                                appID = 1 --<param name="appID" type="Integer" mandatory="true">
                                              }
                                  },
                                  --GetWayPoints
                                  {
                                    name = "GetWayPoints",
                                    splitted = false,
                                    params = {
                                                wayPointType = "ALL", --<param name="wayPointType" type="Common.WayPointType" defvalue="ALL" mandatory="false">
                                                appID = 1-- <param name="appID" type="Integer" mandatory="true"> 
                                              },
                                    -- TODO: APPLINK-22999 Update should be done for release/5
                                    mandatory_params = {
                                                          appID = 1
                                                        },
                                    string_mandatory_params = ' "appID" : '
                                  },
                                  --SubscribeWayPoints
                                  {
                                    name = "SubscribeWayPoints",
                                    splitted = false,
                                    params = {} -- no parameters
                                  },
                                  --UnsubscribeWayPoints
                                  {
                                    name = "UnsubscribeWayPoints",
                                    splitted = false,
                                    params = {} -- no parameters
                                  },
                                  --StartStream
                                  {
                                    
                                    name = "StartStream",
                                    splitted = false,
                                    params = {""} -- no parameters
                                  },
                                  --StopStream
                                  {
                                    
                                    name = "StopStream",
                                    splitted = false,
                                    params = {""} -- no parameters
                                  },
                                  --StartAudioStream
                                  {
                                    
                                    name = "StartAudioStream",
                                    splitted = false,
                                    params = {""} -- no parameters
                                  },
                                  --StopAudioStream
                                  {
                                    name = "StopAudioStream",
                                    splitted = false,
                                    params = {""} -- no parameters
                                  },
                                  --StopSpeaking
                                  {

                                    name = "Not applicable"
                                  },
                                  
                                }
                    }
                }

return interfaces
