Scriptname skynet_Library extends Quest  

skynet_MainController Property skynet Auto Hidden

; -----------------------------------------------------------------------------
; --- Properties ---
; -----------------------------------------------------------------------------
Faction Property factionMerchants Auto
Faction Property factionInnkeepers Auto
Faction Property factionStewards Auto
Faction Property factionPlayerFollowers Auto
Faction Property factionRentRoom Auto

Quest Property questDialogueGeneric Auto
Quest Property questBountyBandits Auto

GlobalVariable Property globalRentRoomPrice Auto

Keyword Property keywordDialogueTarget Auto
Keyword Property keywordFollowTarget Auto

Package Property packageDialoguePlayer Auto
Package Property packageDialogueNPC Auto
Package Property packageFollowPlayer Auto

Idle Property IdleApplaud2 Auto
Idle Property IdleApplaud3 Auto
Idle Property IdleApplaud4 Auto
Idle Property IdleApplaud5 Auto
Idle Property IdleApplaudSarcastic Auto
Idle Property IdleBook_Reading Auto
Idle Property IdleDrink Auto
Idle Property IdleDrinkPotion Auto
Idle Property IdleEatSoup Auto
Idle Property IdleExamine Auto
Idle Property IdleForceDefaultState Auto
Idle Property IdleLaugh Auto
Idle Property IdleNervous Auto
Idle Property IdleNoteRead Auto
Idle Property IdlePointClose Auto
Idle Property IdlePray Auto
Idle Property IdleSalute Auto
Idle Property IdleSnapToAttention Auto
Idle Property IdleStudy Auto
Idle Property IdleWave Auto
Idle Property IdleWipeBrow Auto

MiscObject Property miscGold Auto
Message Property msgClearHistory Auto

; -----------------------------------------------------------------------------
; --- Lookup Arrays ---
; -----------------------------------------------------------------------------
Package[] packageArray
String[] packageNames
Idle[] animationIdleArray
String[] animationNames
Bool arraysInitialized = False

; -----------------------------------------------------------------------------
; --- Version & Maintenance ---
; -----------------------------------------------------------------------------

Function Maintenance(skynet_MainController _skynet)
    skynet = _skynet
    InitializeLookupArrays()
    RegisterActions()
    skynet.Info("Library initialized")
EndFunction

Function InitializeLookupArrays()
    if arraysInitialized
        return
    endif
    
    ; Initialize package lookup arrays
    packageNames = new String[3]
    packageArray = new Package[3]
    
    packageNames[0] = "TalkToPlayer"
    packageArray[0] = packageDialoguePlayer
    
    packageNames[1] = "TalkToNPC"
    packageArray[1] = packageDialogueNPC
    
    packageNames[2] = "FollowPlayer"
    packageArray[2] = packageFollowPlayer
    
    ; Initialize animation lookup arrays
    animationNames = new String[15]
    animationIdleArray = new Idle[15]
    
    animationNames[0] = "applaud"
    animationIdleArray[0] = IdleApplaud2  ; Will be randomly selected from applaud group
    
    animationNames[1] = "applaud_sarcastic"
    animationIdleArray[1] = IdleApplaudSarcastic
    
    animationNames[2] = "read_book"
    animationIdleArray[2] = IdleBook_Reading
    
    animationNames[3] = "drink"
    animationIdleArray[3] = IdleDrink
    
    animationNames[4] = "drink_potion"
    animationIdleArray[4] = IdleDrinkPotion
    
    animationNames[5] = "eat"
    animationIdleArray[5] = IdleEatSoup
    
    animationNames[6] = "laugh"
    animationIdleArray[6] = IdleLaugh
    
    animationNames[7] = "nervous"
    animationIdleArray[7] = IdleNervous
    
    animationNames[8] = "read_note"
    animationIdleArray[8] = IdleNoteRead
    
    animationNames[9] = "pray"
    animationIdleArray[9] = IdlePray
    
    animationNames[10] = "salute"
    animationIdleArray[10] = IdleSalute
    
    animationNames[11] = "study"
    animationIdleArray[11] = IdleStudy
    
    animationNames[12] = "wave"
    animationIdleArray[12] = IdleWave
    
    animationNames[13] = "wipe_brow"
    animationIdleArray[13] = IdleWipeBrow
    
    animationNames[14] = "examine"
    animationIdleArray[14] = IdleExamine
    
    arraysInitialized = True
EndFunction

Function RegisterActions()
    if !RegisterBasicActions()
        skynet.Fatal("Basic actions failed to register.")
        return
    endif

    if !RegisterAnimationActions()
        skynet.Fatal("Animation actions failed to register.")
        return
    endif

    if !RegisterCompanionActions()
        skynet.Fatal("Companion actions failed to register.")
        return
    endif

    if !RegisterTavernActions()
        skynet.Fatal("Tavern actions failed to register.")
        return
    endif

    ; DEBUG ONLY
    debug.notification("Actions registered.")
EndFunction

; -----------------------------------------------------------------------------
; --- Skynet Package Parsing ---
; -----------------------------------------------------------------------------

Package Function GetPackageFromString(String asPackage)
    if !arraysInitialized
        InitializeLookupArrays()
    endif
    
    Int index = packageNames.Find(asPackage)
    If index >= 0
        Return packageArray[index]
    EndIf
    
    skynet.Error("Package not found: " + asPackage)
    return None
EndFunction

Function ApplyPackageOverrideToActor(Actor akActor, String asString, Int priority = 1, Int flags = 0)
    if !akActor
        skynet.Error("Cannot apply package to null actor")
        return
    endif
    
    Package _pck = GetPackageFromString(asString)
    if !_pck
        skynet.Error("Could not retrieve package for: " + asString)
        return
    endif
    
    skynet.Info("Applying package override " + asString + " to " + akActor.GetDisplayName())
    ActorUtil.AddPackageOverride(akActor, _pck, priority, flags)
    SafeEvaluatePackage(akActor)
EndFunction

Function RemovePackageOverrideFromActor(Actor akActor, String asString)
    if !akActor
        skynet.Error("Cannot remove package from null actor")
        return
    endif
    
    Package _pck = GetPackageFromString(asString)
    if !_pck
        skynet.Error("Could not retrieve package for: " + asString)
        return
    endif
    
    skynet.Info("Removing package override " + asString + " from " + akActor.GetDisplayName())
    ActorUtil.RemovePackageOverride(akActor, _pck)
    SafeEvaluatePackage(akActor)
EndFunction

Function SafeEvaluatePackage(Actor akActor)
    If akActor && !akActor.IsDeleted()
        akActor.EvaluatePackage()
    EndIf
EndFunction

; -----------------------------------------------------------------------------
; --- Skynet Papyrus Actions ---
; -----------------------------------------------------------------------------

Bool Function RegisterBasicActions()
    SkyrimNetApi.RegisterAction("OpenTrade", "Use ONLY if {{ player.name }} asks to trade and you agree to trade. Otherwise, you MUST NOT use this action.", \
                                "SkyrimNetInternal", "OpenTrade_IsEligible", \
                                "SkyrimNetInternal", "OpenTrade_Execute", \
                                "", "PAPYRUS", \
                                1, "")

    SkyrimNetApi.RegisterAction("StartFollow", "Start following {{ player.name }} temporarily.", \
                                "SkyrimNetInternal", "StartFollow_IsEligible", \
                                "SkyrimNetInternal", "StartFollow_Execute", \
                                "", "PAPYRUS", \
                                1, "")

    SkyrimNetApi.RegisterAction("StopFollow", "Stop following {{ player.name }} around. Use this when you are done following them, or want to go home.", \
                                "SkyrimNetInternal", "StopFollow_IsEligible", \
                                "SkyrimNetInternal", "StopFollow_Execute", \
                                "", "PAPYRUS", \
                                1, "")

    SkyrimNetApi.RegisterAction("WaitHere", "Wait for {{ player.name }} at the current location.", \
                                "SkyrimNetInternal", "PauseFollow_IsEligible", \
                                "SkyrimNetInternal", "PauseFollow_Execute", \
                                "", "PAPYRUS", \
                                1, "")
    return true
EndFunction

Bool Function OpenTrade_IsEligible(Actor akActor, string contextJson, string paramsJson)
    if !akActor || !factionMerchants
        return false
    endif
    
    if akActor.GetFactionRank(factionMerchants) == -2
        return false
    endif
    return true
EndFunction

Bool Function RegisterTavernActions()
    SkyrimNetApi.RegisterAction("RentRoom", "Rent a room out to {{ player.name }} for an amount of gold, but only if they agreed to the price beforehand", \
                                "SkyrimNetInternal", "RentRoom_IsEligible", \
                                "SkyrimNetInternal", "RentRoom_Execute", \
                                "", "PAPYRUS", \
                                1, "{\"price\": \"Int\"}")

    return True
EndFunction

Bool Function RentRoom_IsEligible(Actor akActor)
    if !akActor || !factionRentRoom
        return false
    endif
    
    if !akActor.IsInFaction(factionRentRoom) || akActor.GetActorValue("Variable09") > 0
        return false
    EndIf

    if !(akActor as RentRoomScript)
        return false
    endif

    return true
EndFunction

Function RentRoom_Execute(Actor akActor, string paramsJson)
    if !akActor || !questDialogueGeneric || !globalRentRoomPrice || !miscGold
        skynet.Error("RentRoom_Execute: Required properties not initialized")
        return
    endif
    
    DialogueGenericScript _dqs = (questDialogueGeneric as DialogueGenericScript)
    RentRoomScript rentScript = (akActor as RentRoomScript)

    if (!rentScript || !_dqs)
        return
    endif

    Int price = SkyrimNetApi.GetJsonInt(paramsJson, "price", Math.Floor(globalRentRoomPrice.GetValue()))
    if skynet.playerRef.GetItemCount(miscGold) < price
        return
    EndIf

    skynet.playerRef.RemoveItem(miscGold, price)
    rentScript.RentRoom(_dqs)
EndFunction

Bool Function RegisterAnimationActions()
    SkyrimNetApi.RegisterAction("SlapTarget", "Slap the target.", \
                                "SkyrimNetInternal", "Animation_IsEligible", \
                                "SkyrimNetInternal", "AnimationSlapActor", \
                                "", "PAPYRUS", \
                                1, "{\"target\": \"Actor\"}")

    SkyrimNetApi.RegisterAction("Gesture", "Perform a gesture to emphasize your words.", \
                                "SkyrimNetInternal", "Animation_IsEligible", \
                                "SkyrimNetInternal", "AnimationGeneric", \
                                "", "PAPYRUS", \
                                1, "{ \"anim\": \"applaud|applaud_sarcastic|drink|drink_potion|eat|laugh|nervous|read_note|pray|salute|study|wave|wipe_brow|examine\" }")

    return True
EndFunction

Function PlayGenericAnimation(Actor akActor, String anim)
    if !akActor
        skynet.Error("PlayGenericAnimation: akActor is null")
        return
    endif
    
    if !arraysInitialized
        InitializeLookupArrays()
    endif
    
    Debug.Trace("Playing animation: " + anim + " for " + akActor.GetDisplayName())
    
    Idle targetIdle = GetIdleForAnimation(anim)
    
    if !targetIdle
        skynet.Error("Could not parse animation string for generic animation: " + anim)
        Return
    endif

    akActor.PlayIdle(IdleForceDefaultState)
    utility.wait(2)
    akActor.PlayIdle(targetIdle)
EndFunction

Idle Function GetIdleForAnimation(String anim)
    ; Special case for applaud - random selection
    If anim == "applaud"
        int rnd = Utility.RandomInt(0,3)
        if rnd == 0
            return IdleApplaud2
        elseif rnd == 1
            return IdleApplaud3
        elseif rnd == 2
            return IdleApplaud4
        elseif rnd == 3
            return IdleApplaud5
        EndIf
    EndIf
    
    ; Use lookup array for other animations
    Int index = animationNames.Find(anim)
    If index >= 0
        return animationIdleArray[index]
    EndIf
    
    return None
EndFunction

Bool Function RegisterCompanionActions()
    SkyrimNetApi.RegisterAction("CompanionFollow", "Start following {{ player.name }}.", \
                                "SkyrimNetInternal", "CompanionFollow_IsEligible", \
                                "SkyrimNetInternal", "CompanionFollow", \
                                "", "PAPYRUS", \
                                1, "")

    SkyrimNetApi.RegisterAction("CompanionWait", "Wait at this location", \
                                "SkyrimNetInternal", "CompanionWait_IsEligible", \
                                "SkyrimNetInternal", "CompanionWait", \
                                "", "PAPYRUS", \
                                1, "")

    SkyrimNetApi.RegisterAction("CompanionInventory", "Give {{ player.name }} access to your inventory", \
                                "SkyrimNetInternal", "Companion_IsEligible", \
                                "SkyrimNetInternal", "CompanionInventory", \
                                "", "PAPYRUS", \
                                1, "")

    SkyrimNetApi.RegisterAction("CompanionGiveTask", "Let {{ player.name }} designate a task for you", \
                                "SkyrimNetInternal", "CompanionGiveTask_IsEligible", \
                                "SkyrimNetInternal", "CompanionGiveTask", \
                                "", "PAPYRUS", \
                                1, "")

    return true
EndFunction

Bool Function StartFollow_IsEligible(Actor akActor)
    if !akActor
        return false
    endif
    
    if SkyrimNetApi.HasPackage(akActor, "FollowPlayer") && akActor.GetAV("WaitingForPlayer") == 0
        return false
    endif

    return true
EndFunction

Bool Function StopFollow_IsEligible(Actor akActor)
    if !akActor || !factionPlayerFollowers
        return false
    endif
    
    if akActor.IsInFaction(factionPlayerFollowers)
        return false
    endif

    if !SkyrimNetApi.HasPackage(akActor, "FollowPlayer")
        return false
    endif

    return true
EndFunction

Bool Function PauseFollow_IsEligible(Actor akActor)
    if !akActor || !factionPlayerFollowers
        return false
    endif
    
    if akActor.IsInFaction(factionPlayerFollowers)
        return false
    endif

    if !SkyrimNetApi.HasPackage(akActor, "FollowPlayer")
        return false
    endif

    if akActor.GetAV("WaitingForPlayer") > 0
        return false
    endif

    return true
EndFunction

Function StartFollow_Execute(Actor akActor)
    if !akActor
        return
    endif
    
    debug.notification(akActor.GetDisplayName() + " is now following you.")

    akActor.SetAV("WaitingForPlayer", 0)
    SkyrimNetApi.RegisterPackage(akActor, "FollowPlayer", 10, 0, true)
    SafeEvaluatePackage(akActor)
EndFunction

Function StopFollow_Execute(Actor akActor)
    if !akActor
        return
    endif
    
    debug.notification(akActor.GetDisplayName() + " is no longer following you.")

    SkyrimNetApi.UnregisterPackage(akActor, "FollowPlayer")
    SafeEvaluatePackage(akActor)
EndFunction

Function PauseFollow_Execute(Actor akActor)
    if !akActor
        return
    endif
    
    debug.notification(akActor.GetDisplayName() + " is waiting for you here.")

    akActor.SetAV("WaitingForPlayer", 1)
    SafeEvaluatePackage(akActor)
EndFunction