--[[CRQ: APPLINK-29495: Policies - Policy Table Update (EXTERNAL_PROPRIETARY flow)

--[[Clarifications
  1. APPLINK-29758: Can you clarify the state of PTU(UPDATE_NEEDED) in previous ign_cycle according to APPLINK-18946
  2. APPLINK-29759: Non-conformity between requirements APPLINK-18966 and APPLINK-24148
  3. APPLINK-29760: Can you clarify are there specific notifications from SDL to check SDP query
  ]]

--[[General Precondition: all configuration files, policy, storage should be initial]]

--[[Testing coverage]]
  -- ToDo: until coverage check for other transports!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  
  --APPLINK-18952: [PolicyTableUpdate] Request PTU - an app registered is not listed in PT (device consented)
  --APPLINK-19072: [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request
  --APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  --APPLINK-18040: [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
  --[[Tests:
	  TC_01_PTU_AppID_NotListed_PT
      -- Preconditions
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
      -- Test
	    1. Register App with ID = App1.
	    ExpRes: PTU is requested.
	    1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    3. SDL Defines the urls and an app to transfer PTU
	    4. SDL->app: OnSystemRequest()

	  TC_02_PTU_AppID_Listed_PT
      -- Preconditions
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
        2. Register App with ID = App1.
	    3. PTU is requested.
	    4. Unregister App with ID = App1. (app ID should be still listed in PT)
      -- Test
	    1. Register again App with ID = App1.
	    ExpRes: PTU should not be triggered.
	    2. Register again App with ID = App2.
	    ExpRes: PTU is requested.
	    1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    3. SDL Defines the urls and an app to transfer PTU
	    4. SDL->app: OnSystemRequest()

	  TC_03_PTU_AppIDs_NotListed_PT_DifferentDevices
      -- Preconditions
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
	    2. Register App with ID = App1.
	    3. PTU is requested.
	    ExpRes:
	    3.1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    3.2. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    3.3. SDL Defines the urls and an app to transfer PTU
	    3.4. SDL->app: OnSystemRequest()
      -- Test
        1. Connect Device ID2; Register App with ID = App2.
	    ExpRes: PTU is requested.
	    1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    3. SDL Defines the urls and an app to transfer PTU
	    4. SDL->app: OnSystemRequest()

	  TC_04_PTU_SameAppIDs_DifferentDevices
      -- Preconditions
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
	    2. Register App with ID = App1.
	    3. PTU is requested.
	    3.1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    3.2. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    3.3. SDL Defines the urls and an app to transfer PTU
	    3.4. SDL->app: OnSystemRequest()
      -- Test
	    1. Connect Device ID2; Register App with ID = App1, the same for DeviceID 1.
	    ExpRes: PTU is requested.
	    1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    3. SDL Defines the urls and an app to transfer PTU
	    4. SDL->app: OnSystemRequest()
    ]]
  
  --APPLINK-18946: [PolicyTableUpdate] Policy Table Update in case of failed retry strategy during previour IGN_ON (SDL.PolicyUpdate)
  --[[Tests:
    -- Waiting for clarification of APPLINK-29758: Can you clarify the state of PTU(UPDATE_NEEDED) in previous ign_cycle according to APPLINK-18946
	]]
	
  --APPLINK-18966: [PolicyTableUpdate] PoliciesManager must initiate PTU in case getting 'device consent' from the user
  --[[Tests:
    -- Waiting for clarification of APPLINK-29759: Non-conformity between requirements APPLINK-18966 and APPLINK-24148
    ]]

  --APPLINK-18967: [PolicyTableUpdate] PTU using consented device in case a user didn't consent the one which application required PTU
  --[[Tests:
    -- Waiting for clarification of APPLINK-29759: Non-conformity between requirements APPLINK-18966 and APPLINK-24148
    ]]
	
  --APPLINK-23586: [Policies]: SDL.OnPolicyUpdate initiation of PTU
  --APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  --APPLINK-18040: [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
  --[[Tests:
      TC_05_User_initiates_PTU: [HP]
	  -- Preconditions:
	    1. App is running on this device, and registerd on SDL
	  -- Test
        1. HMI -> SDL: SDL.OnPolicyUpdate
	    ExpRes: SDL->HMI: BasicCommunication.PolicyUpdate
	    1. PTS is created by SDL -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    2. HMI -> SDL: SDL.PolicyUpdate(SUCCESS)
	  -- ToDo: During testing coverage check is there negative cases to be covered.
    ]]
	
  --APPLINK-18991: [PolicyTableUpdate] PoliciesManager must initiate PTU on a User request
  --APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  --APPLINK-18040: [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
  --[[Tests:
      TC_06_User_request_PTU: [HP]
	  -- Preconditions:
	    1. App has registered and is in allowed HMILevel
      -- Test
	    1. HMI->SDL: SDL.UpdateSDL
	    ExpRes: SDL->HMI: SDL->HMI:SDL.UpdateSDL
	    1. PTS is created by SDL -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    2. HMI -> SDL: SDL.PolicyUpdate(SUCCESS)
	  -- ToDo: During testing coverage check is there negative cases to be covered.
    ]]
  
  --APPLINK-17932: [PolicyTableUpdate] Request to update PT - after "N" ignition cycles
  --APPLINK-19072: [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request
  --APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  --APPLINK-18040: [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
  --[[Tests:
      TC_07_No_PTU_After_N_ignition_cycles: [N]
	  -- Preconditions:
        1. Check in sdl_preloaded_pt.json, value of exchange_after_x_ignition_cycles = #Ign_Cycle
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Check in PT "module_config": value of 'ignition_cycles_since_last_exchange' = <N>. Should be less than #Ign_Cycle
	      -- For First IGN_Cycle: <N> = 0
	    4. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	  -- Test:
	    1. IGN_OFF
	    2. HMI->SDL:BasicCommunication.OnIgnitionCycleOver
	    3. IGN_ON
	    ExpRes:
	    1. Increment "module_meta" -> "ignition_cycles_since_last_exchange" value = <N> + 1
	    2. SDL should not initiate PTU: SDL.OnStatusUpdate(UPDATE_NEEDED) should not be sent
	    3. PTS is not created by SDL: SDL.PolicyUpdate() //PTU sequence started is not sent
	
	  TC_08_PTU_After_N_ignition_cycles: [HP]
	  -- Preconditions:
        1. Update in sdl_preloaded_pt.json, value of exchange_after_x_ignition_cycles = 2
	    2. First Ign_Cycle
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Check in PT "module_config": value of 'ignition_cycles_since_last_exchange' = 0. Should be less than exchange_after_x_ignition_cycles(2)
	    4. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    6. IGN_OFF
	    7. HMI->SDL:BasicCommunication.OnIgnitionCycleOver
	    8. IGN_ON => (ignition_cycles_since_last_exchange = 1) < exchange_after_x_ignition_cycles(2)
	    9. SDL should not initiate PTU; PTS is not created by SDL
	    10. IGN_OFF
	  -- Test:
        1. IGN_ON => (ignition_cycles_since_last_exchange = 2) == exchange_after_x_ignition_cycles(2)
        2. HMI->SDL:BasicCommunication.OnIgnitionCycleOver
	    ExpRes:
	    1. SDL should initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	  -- Postconditions:
        1. IGN_OFF
	    2. HMI->SDL:BasicCommunication.OnIgnitionCycleOver
	    3. IGN_ON => (ignition_cycles_since_last_exchange = 3) > exchange_after_x_ignition_cycles(2)
	    4. SDL should not initiate PTU; PTS is not created by SDL
	
	  TC_09_PTU_After_N_ignition_cycles: LongTerm test
	  -- Preconditions:
	    1. Check in sdl_preloaded_pt.json, value of exchange_after_x_ignition_cycles = #Ign_Cycle
	    2. First Ign_Cycle
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Check in PT "module_config": value of 'ignition_cycles_since_last_exchange' = 0. Should be less than exchange_after_x_ignition_cycles(2)
	    4. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    Do until (ignition_cycles_since_last_exchange = <N>) == #Ign_Cycle
	      6.1 IGN_OFF
	      6.2 HMI->SDL:BasicCommunication.OnIgnitionCycleOver
	      6.3 IGN_ON => (ignition_cycles_since_last_exchange = <N>) < exchange_after_x_ignition_cycles(#Ign_Cycle)
	      6.4 SDL should not initiate PTU; PTS is not created by SDL
	      6.5 IGN_OFF
	    End Do
	    As result of action 6 => ignition_cycles_since_last_exchange = #Ign_Cycle - 1
	
	  -- Test:
	    1. IGN_ON => ignition_cycles_since_last_exchange = #Ign_Cycle
	    2. HMI->SDL:BasicCommunication.OnIgnitionCycleOver
	    ExpRes:
	    1. SDL should initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	  -- Postconditions:
	    1. IGN_OFF
	    2. HMI->SDL:BasicCommunication.OnIgnitionCycleOver
	    3. IGN_ON => (ignition_cycles_since_last_exchange = #Ign_Cycle + 1) > exchange_after_x_ignition_cycles(#Ign_Cycle)
	    4. SDL should not initiate PTU; PTS is not created by SDL
    ]]
    
  --APPLINK-17965: [PolicyTableUpdate] Request to update PT - after "N" kilometers
  --APPLINK-19072: [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request
  --APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  --APPLINK-18040: [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
  --[[Tests:
      TC_10_No_PTU_After_N_kilometers:
	  -- Preconditions:
	    1. Check in sdl_preloaded_pt.json, value of exchange_after_x_kilometers = #ExchangeKilometers
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    4. Check the value of odometer received at this PTU = #Odometer1
	    => #ValueToCheck = #Odometer1 + #ExchangeKilometers
	  -- Test:
	    1. HMI->SDL:OnVehcileData ("odometer": #ValueToCheck - #Odometer1)
	    ExpRes:
	    1. SDL should not initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is not sent.
	    2. PTS should not be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is not sent/
	
      TC_11_No_PTU_After_N_kilometers:
	  -- Preconditions:
	    1. Check in sdl_preloaded_pt.json, value of exchange_after_x_kilometers = #ExchangeKilometers
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    4. Check the value of odometer received at this PTU = #Odometer1
	    => #ValueToCheck = #Odometer1 + #ExchangeKilometers
	  -- Test:
	    1. HMI->SDL:OnVehcileData ("odometer": #ValueToCheck - 1)
	    ExpRes:
	    1. SDL should not initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is not sent.
	    2. PTS should not be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is not sent/

	  TC_12_PTU_After_N_kilometers:
	  -- Preconditions:
	    1. Check in sdl_preloaded_pt.json, value of exchange_after_x_kilometers = #ExchangeKilometers
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    4. Check the value of odometer received at this PTU = #Odometer1
	    => #ValueToCheck = #Odometer1 + #ExchangeKilometers
	  -- Test:
	    1. HMI->SDL:OnVehcileData ("odometer": #ValueToCheck)
	    ExpRes:
	    1. SDL should initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is sent.
	    2. PTS should be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is sent//PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	  
      TC_13_PTU_After_N_kilometers:
	  -- Preconditions:
	    1. Check in sdl_preloaded_pt.json, value of exchange_after_x_kilometers = #ExchangeKilometers
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    4. Check the value of odometer received at this PTU = #Odometer1
	    => #ValueToCheck = #Odometer1 + #ExchangeKilometers
	  -- Test:
	    1. HMI->SDL:OnVehcileData ("odometer": #ValueToCheck + 1)
	    ExpRes:
	    1. SDL should initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is sent.
	    2. PTS should be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is sent//PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	
	  TC_14_PTU_After_N_kilometers:
	  -- Preconditions:
	    1. Check in sdl_preloaded_pt.json, value of exchange_after_x_kilometers = #ExchangeKilometers
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    4. Check the value of odometer received at this PTU = #Odometer1
	    => #ValueToCheck = #Odometer1 + #ExchangeKilometers
	    5. HMI->SDL:OnVehcileData ("odometer": #ValueToCheck + 1)
	    ExpRes:
	    1. SDL should initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is sent.
	    2. PTS should be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is sent//PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    3. Check the value of odometer received at this PTU = #Odometer2
	    => #ValueToCheck = #Odometer2 + #ExchangeKilometers
	    4. Finish PTU sequence.
	  -- Test:
        1. HMI->SDL:OnVehcileData ("odometer": #ValueToCheck + 1)
	    ExpRes:
	    1. SDL should initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is sent. 
	    2. PTS should be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is sent//PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
    ]]

  --APPLINK-17968: [PolicyTableUpdate] Request PTU - after "N" days
  --APPLINK-19072: [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request
  --APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  --APPLINK-18040: [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
  --[[Tests:
      TC_15_No_PTU_After_N_days:
	  -- Preconditions:
	    1. Check in sdl_preloaded_pt.json, value of exchange_after_x_kilometers = #ExchangeDays
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    4. Check the value of date received at this PTU = #Date1
	    => #ValueToCheck = #Date1 + #ExchangeDays
	  -- Test:
	    1. HMI->SDL: SDL gets the current date ("date": #ValueToCheck - #Date1)
	    ExpRes:
	    1. SDL should not initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is not sent.
	    2. PTS should not be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is not sent/
	
      TC_16_No_PTU_After_N_days:
	  -- Preconditions:
	    1. Check in sdl_preloaded_pt.json, value of exchange_after_x_kilometers = #ExchangeDays
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    4. Check the value of date received at this PTU = #Date1
	    => #ValueToCheck = #Date1 + #ExchangeDays
	  -- Test:
	    1. HMI->SDL: SDL gets the current date ("date": #ValueToCheck - 1)
	    ExpRes:
	    1. SDL should not initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is not sent.
	    2. PTS should not be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is not sent/

	  TC_17_PTU_After_N_days:
	  -- Preconditions:
	    1. Check in sdl_preloaded_pt.json, value of exchange_after_x_kilometers = #ExchangeDays
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    4. Check the value of date received at this PTU = #Date1
	    => #ValueToCheck = #Date1 + #ExchangeDays
	  -- Test:
	    1. HMI->SDL: SDL gets the current date ("date": #ValueToCheck)
	    ExpRes:
	    1. SDL should initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is sent.
	    2. PTS should be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is sent//PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	  
      TC_18_PTU_After_N_days:
	  -- Preconditions:
	    1. Check in sdl_preloaded_pt.json, value of exchange_after_x_kilometers = #ExchangeDays
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    4. Check the value of date received at this PTU = #Date1
	    => #ValueToCheck = #Date1 + #ExchangeDays
	  -- Test:
 	    1. HMI->SDL: SDL gets the current date ("date": #ValueToCheck + 1)
	    ExpRes:
	    1. SDL should initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is sent.
	    2. PTS should be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is sent//PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  	
	  TC_19_PTU_After_N_days:
	  -- Preconditions:
 	    1. Check in sdl_preloaded_pt.json, value of exchange_after_x_kilometers = #ExchangeDays
	    2. Device an app with app_ID is running is consented. Application is running on SDL
	    3. Successful PTU scenarios is finished => SDL -> HMI: OnStatusUpdate(UP_TO_DATE)
	    4. Check the value of date received at this PTU = #Date1
	    => #ValueToCheck = #Date1 + #ExchangeDays
	    5. HMI->SDL: SDL gets the current date ("date": #ValueToCheck + 1)
	    ExpRes:
	    1. SDL should initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is sent.
	    2. PTS should be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is sent//PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    3. Check the value of date received at this PTU = #date2
	    => #ValueToCheck = #date2 + #ExchangeDays
	    4. Finish PTU sequence.
	  -- Test:
	    1. HMI->SDL: SDL gets the current date ("date": #ValueToCheck + 1)
	    ExpRes:
	    1. SDL should initiate PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED) is sent.
	    2. PTS should be created by SDL: SDL-> HMI: SDL.PolicyUpdate() is sent//PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  ]]
  
  --APPLINK-19010: [PolicyTableUpdate] BlueTooth: PoliciesManager must initiate the triggered PTU ONLY AFTER the SDP query is complete
  --APPLINK-19072: [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request
  --APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  --APPLINK-18040: [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
  --[[Tests:
      TC_20_BT_PTU_OneApp
	  -- Preconditions:
	    1. Device an app with app_ID1 not listed in PTU is running on mobile. 
	    2. Device is connected via BT
      -- Test
	    -- Clarification APPLINK-29760
	    1. SDL waits until SDP query is complete: 
	    ExpRes: 
	    1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule

	  TC_21_BT_PTU_ThreeApps
	  -- Preconditions:
	    1. Device an app with app_ID1, app_ID2 and app_ID3 not listed in PTU is running on mobile. 
	    2. Device is connected via BT
      -- Test
	    -- Clarification APPLINK-29760
	    1. SDL waits until SDP query is complete: 
	    ExpRes: 
	    1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule

	  TC_22_BT_PTU_ThreeApps_AdditionalAppRegistered
	  -- Preconditions:
	    1. Device an app with app_ID1, app_ID2 and app_ID3 not listed in PTU is running on mobile. 
	    2. Device is connected via BT
	    -- Clarification APPLINK-29760
	    3. SDL waits until SDP query is complete: 
	      ExpRes: 
	      3.1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	      3.2. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    4. Perform successfull PTU
	    5. IGN_OFF
	  -- Test
	    1. IGN_ON
	    2. The three apps are registered. => NO PTU
	    3. Register new app over BT
	    ExpRes:
	    3.1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    3.2. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule

	  Waiting clarification: APPLINK-29760: Can you clarify are there specific notifications from SDL to check SDP query
	  According to it may additional tests to be added.
  ]]
 
  --APPLINK-19011: [PolicyTableUpdate] USB/USB: At least one application is registered
  --APPLINK-19072: [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request
  --APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  --APPLINK-18040: [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
  --[[Tests:
      TC_23_USB_PTU_OneApp
	  -- Preconditions:
	    1. Device an app with app_ID1 not listed in PTU is running on mobile. 
      -- Test
	    1. Device is connected over USB
	    2. app->SDL: RegisterAppInterface()
	    ExpRes: 
	    1. SDL-> app: RegisterAppInterface()
	    2. SDL->HMI: OnAppRegistered()
	    3. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    4. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule

	  TC_24_USB_PTU_ThreApps
	  -- Preconditions:
	    1. Device an app with app_ID1,app_ID2, app_ID3 not listed in PTU is running on mobile. 
      -- Test
	    1. Device is connected over USB
	    2. app->SDL: RegisterAppInterface(app_ID1)
	    3. app->SDL: RegisterAppInterface(app_ID2)
	    4. app->SDL: RegisterAppInterface(app_ID3)
	    5. SDL-> app: RegisterAppInterface(app_ID1)
	    6. SDL-> app: RegisterAppInterface(app_ID1)
	    7. SDL-> app: RegisterAppInterface(app_ID1)
	    8. Wait for first SDL-> HMI: OnAppRegistered(app_ID1) or OnAppRegistered(app_ID2) or OnAppRegistered(app_ID3). 
	       This can happen during steps 5,6,7
	    ExpRes: 
	    1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
     
      TC_25_USB_PTU_OneApp_AdditionalAppRegisters
	  -- Preconditions:
	    1. Device an app with app_ID1 not listed in PTU is running on mobile. 
      -- Test
	    1. Device is connected over USB
	    2. app->SDL: RegisterAppInterface()
	    3. SDL-> app: RegisterAppInterface()
	    4. SDL->HMI: OnAppRegistered()
	    5. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    6. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    7. Perform successfull PTU
        ExpRes: 
        1. Register new app not listed in PT
        ExpRes:
        1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
 
      TC_26_USB_PTU_OneApp
	  -- Preconditions:
	    1. Device an app with app_ID1 not listed in PTU is running on mobile. 
      -- Test
	    1. Device is connected over USB
	    2. app->SDL: RegisterAppInterface()
	    ExpRes: 
	    1. SDL-> app: RegisterAppInterface()
	    2. SDL->HMI: OnAppRegistered()
	    3. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    4. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule

	  TC_27_USB_PTU_ThreApps
	  -- Preconditions:
	    1. Device an app with app_ID1,app_ID2, app_ID3 not listed in PTU is running on mobile. 
      -- Test
	    1. Device is connected over USB
	    2. app->SDL: RegisterAppInterface(app_ID1)
	    3. app->SDL: RegisterAppInterface(app_ID2)
	    4. app->SDL: RegisterAppInterface(app_ID3)
	    5. SDL-> app: RegisterAppInterface(app_ID1)
	    6. SDL-> app: RegisterAppInterface(app_ID1)
	    7. SDL-> app: RegisterAppInterface(app_ID1)
	    8. Wait for first SDL-> HMI: OnAppRegistered(app_ID1) or OnAppRegistered(app_ID2) or OnAppRegistered(app_ID3). 
	       This can happen during steps 5,6,7
	    ExpRes: 
	    1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
    
      TC_28_USB_PTU_OneApp_AdditionalAppRegisters
	  -- Preconditions:
	    1. Device an app with app_ID1 not listed in PTU is running on mobile. 
      -- Test
	    1. Device is connected over USB
	    2. app->SDL: RegisterAppInterface()
	    3. SDL-> app: RegisterAppInterface()
	    4. SDL->HMI: OnAppRegistered()
	    5. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    6. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    7. Perform successfull PTU
        ExpRes: 
        1. Register new app not listed in PT
        ExpRes:
        1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  ]]

  --APPLINK-18040: [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
  --APPLINK-18053: [PolicyTableUpdate] PTS creation rule
  --APPLINK-18114: [PolicyTableUpdate] Timeout to wait a response on PTU
  --APPLINK-19070: [PolicyTableUpdate] Policy Table Update retry timeout definition
  --APPLINK-19102: [PolicyTableUpdate] [F-S] Policy Manager sends PTS to HMI by providing the file location, timeout and the array of timeouts for retry sequence
  --All these requirements will be checked in each TC that includes SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
  --[[Tests:
      TC_29_PTU_WaitResponse_TimeoutRetry_File
	  -- Preconditions:
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
      -- Test
	    2. Register App with ID = App1.
	    ExpRes: PTU is requested.
	    1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    => check in PTS "module_config" section, key <timeout_after_x_seconds>; 'retry' from "seconds_between_retries"
	    => SDL Defines the urls and an app to transfer PTU
	    3. SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
  ]]

  --APPLINK-19050: [PolicyTableUpdate] Policy Manager responds on GetURLs from HMI
  --APPLINK-14831: In case HMI sends GetURLs and at least one app is registered SDL must return only default url and url related to registered app
  --[[Tests:
      TC_30_PTU_GetURLs
	  -- Preconditions:
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
	    2. Register App with ID = App1. In PTS for endpoints: default URL, URL for registered_App1
	    ExpRes: PTU is requested.
	    1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    => check in PTS "module_config" section, key <timeout_after_x_seconds>; 'retry' from "seconds_between_retries"
	    => SDL Defines the urls and an app to transfer PTU
	    3. SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
	    4. HMI->SDL:SUCCESS:PolicyUpdate()
	  -- Test
	    1. HMI->SDL: SDL.GetURLs(service=0x07) 
	    ExpRes:
	    1. Check "endopint" section, default should be assigned to App1 policies(registered_App1)
	    2. SDL.GetURLs(urls[] = registered_App1, appID = App1) 

	  TC_31_PTU_GetURLs_3_Apps
	  -- Preconditions:
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
	    2. Register App with ID = App1. In PTS for endpoints: default URL, URL for registered_App1
	    3. Register App with ID = App2. In PTS for endpoints: default URL, URL for registered_App2
	    4. Register App with ID = App3. In PTS for endpoints: default URL, URL for registered_App3
	    ExpRes: PTU is requested.
	    1. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    => check in PTS "module_config" section, key <timeout_after_x_seconds>; 'retry' from "seconds_between_retries"
	    => SDL Defines the urls and an app to transfer PTU
	    3. SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
	    4. HMI->SDL:SUCCESS:PolicyUpdate()
	  -- Test
	    1. HMI->SDL: SDL.GetURLs(service=0x07) 
	    ExpRes:
	    --Clarification: Which app section to be returned?
	    1. Check "endopint" section, default should be assigned to App1 policies(registered_App1)
	    2. SDL.GetURLs(urls[] = registered_App1, appID = App1) 

  ]]
  --APPLINK-19050: [PolicyTableUpdate] Policy Manager responds on GetURLs from HMI
  --APPLINK-14832: In case HMI sends GetURLs and no apps registered SDL must return only default url 
  --[[Tests:
    TC_32_PTU_NoAppRegistered_FailedPTU_PrevIGN_Cycle
	  -- Preconditions:
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
	    2. Register App with ID = App1.
	    ExpRes: PTU is requested.
	    3. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    4. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    5. SDL Defines the urls and an app to transfer PTU
	    6. SDL->app: OnSystemRequest()
	    7. IGN_OFF
	    8. IGN_ON. Do not register application.
	    9. PTU is triggered because of APPLINK-18946
	    ExpRes:
	    1. SDL-> HMI: OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created.
	    3. SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
	    -- Test
	    1. Check "endpoint" section in PTS
	    2. HMI -> SDL: SDL.GetURLs(serviceType = 0x7)
	    ExpRes:
		SDL->HMI: GetURLS(urls = default_section), appID is not sent as parameter.

	TC_33_PTU_NoAppRegistered_FailedPTU_PrevIGN_Cycle_UnregisterApp
	  -- Preconditions:
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
	    2. Register App with ID = App1.
	    ExpRes: PTU is requested.
	    3. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    4. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    5. SDL Defines the urls and an app to transfer PTU
	    6. SDL->app: OnSystemRequest()
	    7. IGN_OFF
	    8. IGN_ON. App1 is registered.
	    9. PTU is triggered because of APPLINK-18946
	    ExpRes:
	    1. SDL-> HMI: OnStatusUpdate(UPDATE_NEEDED)
	    2. PTS is created.
	    3. SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
	    -- Test
	    1. Unregister APP1
	    2. Check "endpoint" section in PTS
	    3. HMI -> SDL: SDL.GetURLs(serviceType = 0x7)
	    ExpRes:
		SDL->HMI: GetURLS(urls = default_section), appID is not sent as parameter.

      TC_34_PTU_NoAppRegistered_Trigger_NIgnCycles
	  -- Preconditions:
	    Conditions for PTU because of APPLINK-17932 should be created
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
	    2. Register App with ID = App1.
	    ExpRes: PTU is requested.
	    3. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    4. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    5. SDL Defines the urls and an app to transfer PTU
	    6. SDL->app: OnSystemRequest()
	    7. Perform successful PTU
	    -- Test
	    1. PTU according to APPLINK-17932
	    2. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    3. Check "endpoint" section in PTS - default, app1
	    2. Unregister APP1
	    3. HMI -> SDL: SDL.GetURLs(serviceType = 0x7)
	    ExpRes:
		SDL->HMI: GetURLS(urls = default_section), appID is not sent as parameter.

	  TC_35_PTU_NoAppRegistered_Trigger_NKilometers
	  -- Preconditions:
	    Conditions for PTU because of APPLINK-17965 should be created
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
	    2. Register App with ID = App1.
	    ExpRes: PTU is requested.
	    3. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    4. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    5. SDL Defines the urls and an app to transfer PTU
	    6. SDL->app: OnSystemRequest()
	    7. Perform successful PTU
	    -- Test
	    1. PTU according to APPLINK-17965
	    2. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    3. Check "endpoint" section in PTS - default, app1
	    2. Unregister APP1
	    3. HMI -> SDL: SDL.GetURLs(serviceType = 0x7)
	    ExpRes:
		SDL->HMI: GetURLS(urls = default_section), appID is not sent as parameter.

	  TC_36_PTU_NoAppRegistered_Trigger_NDays
	  -- Preconditions:
	    Conditions for PTU because of APPLINK-17968 should be created
        1. Connect Device ID1. According to APPLINK-24148: isPermissionsConsentNeeded:false, Device is always consented.
	    2. Register App with ID = App1.
	    ExpRes: PTU is requested.
	    3. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    4. PTS is created by SDL.....//PTU started -> APPLINK-18053: [PolicyTableUpdate] PTS creation rule
	    5. SDL Defines the urls and an app to transfer PTU
	    6. SDL->app: OnSystemRequest()
	    7. Perform successful PTU
	    -- Test
	    1. PTU according to APPLINK-17968
	    2. SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
	    3. Check "endpoint" section in PTS - default, app1
	    2. Unregister APP1
	    3. HMI -> SDL: SDL.GetURLs(serviceType = 0x7)
	    ExpRes:
		SDL->HMI: GetURLS(urls = default_section), appID is not sent as parameter.
  ]]

  --APPLINK-19050: [PolicyTableUpdate] Policy Manager responds on GetURLs from HMI
  --APPLINK-14831: In case HMI sends GetURLs and at least one app is registered SDL must return only default url and url related to registered app
  --APPLINK-14832: In case HMI sends GetURLs and no apps registered SDL must return only default url 

  -- ToDo: Check timeout for starting PTU!
  -- Reqs "No "certificate" at "module_config" section" will be covered at the end because still not implemented!
 
  -- Additional TCs can be created for combination of different connections. Suspended until all CRQs are covered 
  
  
  
  
  
  
  
  
  
  