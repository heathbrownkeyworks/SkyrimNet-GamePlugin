scriptname SkyrimNetInternal

; Cached form references for performance
Faction cachedCompanionFaction
Sound cachedSlapSound
GlobalVariable cachedPrayAnimationGlobal

Bool formsInitialized = False

; Functions from within this file are executed directly by the main DLL.
; Do not change or touch them, or you risk stability issues.

Bool Function ClearTimelineMessage() global
    skynet_MainController skynet = GetMainController()
    if !skynet
        return False
    endif

    Int _i = skynet.libs.msgClearHistory.Show()
    if _i == 0
        return False
    Else
        return True
    EndIf
EndFunction

; -----------------------------------------------------------------------------
; --- Utility Functions ---
; -----------------------------------------------------------------------------

skynet_MainController Function GetMainController() global
    skynet_MainController skynet = ((Game.GetFormFromFile(0x0802, "SkyrimNet.esp") as Quest) As skynet_MainController)
    if !skynet
        Debug.MessageBox("Fatal Error: Failed to retrieve SkyrimNet controller.")
    endif
    return skynet
EndFunction

Function InitializeCachedForms() global
    if formsInitialized
        return
    endif
    
    cachedCompanionFaction = Game.GetFormFromFile(0x084D1B, "Skyrim.esm") as Faction
    cachedSlapSound = Game.GetFormFromFile(0x0E98, "SkyrimNet.esp") as Sound
    cachedPrayAnimationGlobal = Game.GetFormFromFile(0x0E99, "SkyrimNet.esp") as GlobalVariable
    
    formsInitialized = True
EndFunction

Bool Function IsValidCompanion(Actor akActor) global
    if !formsInitialized
        InitializeCachedForms()
    endif
    
    return cachedCompanionFaction && akActor && akActor.IsInFaction(cachedCompanionFaction)
EndFunction

Function SafeEvaluatePackage(Actor akActor) global
    If akActor && !akActor.IsDeleted()
        akActor.EvaluatePackage()
    EndIf
EndFunction

; -----------------------------------------------------------------------------
; --- Actor & Package Management ---
; -----------------------------------------------------------------------------

Function SetActorDialogueTarget(Actor akActor, Actor akTarget = None) global
    skynet_MainController skynet = GetMainController()
    if !skynet
        return
    endif
    skynet.SetActorDialogueTarget(akActor, akTarget)
EndFunction

Function AddPackageToActor(Actor akActor, string packageName, int priority, int flags) global
    if !akActor
        Debug.Trace("[SkyrimNetInternal] AddPackageToActor: akActor is null")
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] AddPackageToActor called for " + akActor.GetDisplayName() + " with package " + packageName + " and priority " + priority + " and flags " + flags)
    skynet_MainController skynet = GetMainController()
    if !skynet
        return
    endif
    skynet.libs.ApplyPackageOverrideToActor(akActor, packageName, priority, flags)
EndFunction

Function RemovePackageFromActor(Actor akActor, string packageName) global
    if !akActor
        Debug.Trace("[SkyrimNetInternal] RemovePackageFromActor: akActor is null")
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] RemovePackageFromActor called for " + akActor.GetDisplayName() + " with package " + packageName)
    skynet_MainController skynet = GetMainController()
    if !skynet
        return
    endif
    skynet.libs.RemovePackageOverrideFromActor(akActor, packageName)
EndFunction

; -----------------------------------------------------------------------------
; --- Player Input Handlers ---
; -----------------------------------------------------------------------------

string Function GetPlayerInput() global
    Debug.Trace("[SkyrimNetInternal] GetPlayerInput called")
    UIExtensions.OpenMenu("UITextEntryMenu")
    string messageText = UIExtensions.GetMenuResultString("UITextEntryMenu")
    Debug.Trace("[SkyrimNetInternal] GetPlayerInput returned: " + messageText)
    return messageText
EndFunction

; -----------------------------------------------------------------------------
; --- Example Papyrus Decorators ---
; -----------------------------------------------------------------------------

string Function ExampleDecorator(Actor akActor) global
    Debug.Trace("[SkyrimNet] (ExampleScript) ExampleDecorator called")
    return "Hello, world!"
EndFunction

string Function ExampleDecorator2(Actor akActor) global
    if !akActor
        return "Hello, world! (no actor provided)"
    endif
    Debug.Trace("[SkyrimNet] (ExampleScript) ExampleDecorator2 called with " + akActor + " : " + akActor.GetDisplayName())
    return "Hello, world! You called me with " + akActor.GetDisplayName()
EndFunction

; -----------------------------------------------------------------------------
; --- Trade Actions ---
; -----------------------------------------------------------------------------

bool Function OpenTrade_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    if !akActor || akActor.IsInCombat()
        return false
    endif

    skynet_MainController skynet = GetMainController()
    if !skynet
        return false
    endif

    return skynet.libs.OpenTrade_IsEligible(akActor, contextJson, paramsJson)
EndFunction

Function OpenTrade_Execute(Actor akActor, string contextJson, string paramsJson) global
    if !akActor
        Debug.Trace("[SkyrimNetInternal] OpenTrade_Execute: akActor is null")
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] OpenTrade_Execute called for " + akActor.GetDisplayName())
    akActor.ShowBarterMenu()
EndFunction

; -----------------------------------------------------------------------------
; --- Animation Actions ---
; -----------------------------------------------------------------------------

bool Function Animation_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    if !akActor || akActor.IsInCombat() || akActor.GetSitState() > 0
        return false
    endif

    if !akActor.GetRace().IsPlayable()
        return false
    endif

    return true
EndFunction

Function AnimationGeneric(Actor akOriginator, string contextJson, string paramsJson) global
    if !akOriginator
        Debug.Trace("[SkyrimNetInternal] AnimationGeneric: akOriginator is null")
        return
    endif

    String _anim = SkyrimNetApi.GetJsonString(paramsJson, "anim", "none")
    If _anim == "none"
        Debug.Trace("[SkyrimNetInternal] AnimationGeneric: _anim is none")
        return
    endif

    skynet_MainController skynet = GetMainController()
    if !skynet
        return
    endif

    Debug.Trace("[SkyrimNetInternal] AnimationGeneric: Playing: " + _anim)
    skynet.libs.PlayGenericAnimation(akOriginator, _anim)
EndFunction

Function AnimationSlapActor(Actor akOriginator, string contextJson, string paramsJson) global
    if !formsInitialized
        InitializeCachedForms()
    endif
    
    actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", Game.GetPlayer())
    
    if (!akOriginator || !akTarget)
        Debug.Trace("[SkyrimNetInternal] AnimationSlapActor: akOriginator or akTarget is null")
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] AnimationSlapActor: Slapping " + akTarget.GetDisplayName() + " with " + akOriginator.GetDisplayName())
    
    akTarget.SetDontMove()
    akOriginator.MoveTo(akTarget, 40.0 * Math.Sin(akTarget.GetAngleZ()), 40.0 * Math.Cos(akTarget.GetAngleZ()))
    akOriginator.SetAngle(0.0, 0.0, akTarget.GetAngleZ()+180.0)
    debug.sendanimationevent(akOriginator, "SMplayerslaps")
    
    if cachedSlapSound
        cachedSlapSound.play(akTarget)
    endif
    
    utility.wait(0.8)
    akOriginator.pushactoraway(akTarget,1)
    akTarget.SetDontMove(false)
EndFunction

Function AnimationPrayer(Actor akOriginator, string contextJson, string paramsJson) global
    if !formsInitialized
        InitializeCachedForms()
    endif
    
    if !akOriginator
        Debug.Trace("[SkyrimNetInternal] AnimationPrayer: akOriginator is null")
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] AnimationPrayer: Praying with " + akOriginator.GetDisplayName())
    
    if cachedPrayAnimationGlobal
        cachedPrayAnimationGlobal.SetValue(10)
        Utility.wait(5)
        cachedPrayAnimationGlobal.SetValue(0)
    endif
EndFunction

; -----------------------------------------------------------------------------
; --- Consolidated Companion Actions ---
; -----------------------------------------------------------------------------

bool Function Companion_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    return IsValidCompanion(akActor)
EndFunction

Function CompanionInventory(Actor akActor, string contextJson, string paramsJson) global
    if !IsValidCompanion(akActor)
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] CompanionInventory called for " + akActor.GetDisplayName())
    akActor.OpenInventory()
EndFunction

bool Function CompanionFollow_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    if !IsValidCompanion(akActor)
        return false
    endif

    return akActor.GetActorValue("WaitingForPlayer") != 0
EndFunction

Function CompanionFollow(Actor akActor, string contextJson, string paramsJson) global
    if !IsValidCompanion(akActor)
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] CompanionFollow called for " + akActor.GetDisplayName())
    akActor.SetActorValue("WaitingForPlayer", 0)
    SafeEvaluatePackage(akActor)
EndFunction

bool Function CompanionWait_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    if !IsValidCompanion(akActor)
        return false
    endif

    return akActor.GetActorValue("WaitingForPlayer") == 0
EndFunction

Function CompanionWait(Actor akActor, string contextJson, string paramsJson) global
    if !IsValidCompanion(akActor)
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] CompanionWait called for " + akActor.GetDisplayName())
    akActor.SetActorValue("WaitingForPlayer", 1)
    SafeEvaluatePackage(akActor)
EndFunction

bool Function CompanionGiveTask_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    if !IsValidCompanion(akActor) || akActor.IsDoingFavor()
        return false
    endif

    return true
EndFunction

Function CompanionGiveTask(Actor akActor, string contextJson, string paramsJson) global
    if !IsValidCompanion(akActor)
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] CompanionGiveTask called for " + akActor.GetDisplayName())
    akActor.SetDoingFavor(true)
EndFunction

; -----------------------------------------------------------------------------
; --- Basic Follow Actions ---
; -----------------------------------------------------------------------------

bool Function StartFollow_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    if !akActor
        return false
    endif
    
    skynet_MainController skynet = GetMainController()
    if !skynet
        return false
    endif

    return skynet.libs.StartFollow_IsEligible(akActor)
EndFunction

Function StartFollow_Execute(Actor akActor, string contextJson, string paramsJson) global
    if !akActor
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] StartFollow_Execute called for " + akActor.GetDisplayName())

    skynet_MainController skynet = GetMainController()
    if !skynet
        return
    endif

    skynet.libs.StartFollow_Execute(akActor)
EndFunction

bool Function StopFollow_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    if !akActor
        return false
    endif
    
    skynet_MainController skynet = GetMainController()
    if !skynet
        return false
    endif

    return skynet.libs.StopFollow_IsEligible(akActor)
EndFunction

Function StopFollow_Execute(Actor akActor, string contextJson, string paramsJson) global
    if !akActor
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] StopFollow_Execute called for " + akActor.GetDisplayName())

    skynet_MainController skynet = GetMainController()
    if !skynet
        return
    endif

    skynet.libs.StopFollow_Execute(akActor)
EndFunction

bool Function PauseFollow_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    if !akActor
        return false
    endif
    
    skynet_MainController skynet = GetMainController()
    if !skynet
        return false
    endif

    return skynet.libs.PauseFollow_IsEligible(akActor)
EndFunction

Function PauseFollow_Execute(Actor akActor, string contextJson, string paramsJson) global
    if !akActor
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] PauseFollow_Execute called for " + akActor.GetDisplayName())

    skynet_MainController skynet = GetMainController()
    if !skynet
        return
    endif

    skynet.libs.PauseFollow_Execute(akActor)
EndFunction

; -----------------------------------------------------------------------------
; --- Tavern Actions ---
; -----------------------------------------------------------------------------

bool Function RentRoom_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    if !akActor
        return false
    endif
    
    skynet_MainController skynet = GetMainController()
    if !skynet
        return false
    endif

    return skynet.libs.RentRoom_IsEligible(akActor)
EndFunction

Function RentRoom_Execute(Actor akActor, string contextJson, string paramsJson) global
    if !akActor
        return
    endif
    
    Debug.Trace("[SkyrimNetInternal] RentRoom_Execute called for " + akActor.GetDisplayName())

    skynet_MainController skynet = GetMainController()
    if !skynet
        return
    endif

    skynet.libs.RentRoom_Execute(akActor, paramsJson)
EndFunction