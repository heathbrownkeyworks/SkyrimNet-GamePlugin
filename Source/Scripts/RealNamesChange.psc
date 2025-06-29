scriptName RealNamesChange extends Quest

GlobalVariable Property RNBandit Auto
GlobalVariable Property RNForsworn Auto
GlobalVariable Property RNGuard Auto
GlobalVariable Property RNStendarr Auto
GlobalVariable Property RNThalmor Auto
GlobalVariable Property RNVampire Auto
GlobalVariable Property RNDragon Auto
GlobalVariable Property RNDragonPriest Auto
GlobalVariable Property RNDaedra Auto
GlobalVariable Property RNCreature Auto
GlobalVariable Property RNOther Auto

GlobalVariable Property RNDoLastNames Auto
GlobalVariable Property RNQuestName Auto

Faction Property FacBandit Auto
Faction Property FacForsworn Auto
Faction Property FacHagraven Auto
Faction Property FacGuard Auto
Faction Property FacStendarr Auto
Faction Property FacThalmor Auto
Faction Property FacVampire Auto
Faction Property FacVampireThrall Auto
Faction Property FacDragon Auto
Faction Property FacDragonPriest Auto
Faction Property FacDaedra Auto
Faction Property FacCreature Auto

FormList Property UniquesRename Auto
FormList Property NonUniqueNoRename Auto

; Cached faction arrays for performance
Faction[] factionArray
GlobalVariable[] settingArray
Int numFactions

Event OnInit()
    InitializeFactionArrays()
EndEvent

Function InitializeFactionArrays()
    numFactions = 10
    factionArray = new Faction[10]
    settingArray = new GlobalVariable[10]
    
    ; Initialize faction/setting pairs
    factionArray[0] = FacBandit
    settingArray[0] = RNBandit
    
    factionArray[1] = FacForsworn
    settingArray[1] = RNForsworn
    
    factionArray[2] = FacGuard
    settingArray[2] = RNGuard
    
    factionArray[3] = FacStendarr
    settingArray[3] = RNStendarr
    
    factionArray[4] = FacThalmor
    settingArray[4] = RNThalmor
    
    factionArray[5] = FacVampire
    settingArray[5] = RNVampire
    
    factionArray[6] = FacDragon
    settingArray[6] = RNDragon
    
    factionArray[7] = FacDragonPriest
    settingArray[7] = RNDragonPriest
    
    factionArray[8] = FacDaedra
    settingArray[8] = RNDaedra
    
    factionArray[9] = FacCreature
    settingArray[9] = RNCreature
EndFunction

Function ChangeName(Actor akTarget, String newFirstName, String newLastName)
    if !akTarget
        Return
    EndIf

    ActorBase TargetRef = akTarget.GetLeveledActorBase()
    ActorBase TargetBase = akTarget.GetActorBase()

    Debug.Trace("RealNamesExtended: UniquesRename.Find(TargetRef) = " + UniquesRename.Find(TargetBase))
    Debug.Trace("RealNamesExtended: NonUniqueNoRename.Find(TargetRef) = " + NonUniqueNoRename.Find(TargetBase))

    Bool ShouldRename = DetermineIfShouldRename(TargetRef, TargetBase)
    
    If !ShouldRename
        Return
    EndIf

    Bool useQuestName = (RNQuestName.GetValue() as int == 1)
    ProcessActorRename(akTarget, newFirstName, newLastName, useQuestName)
EndFunction

Bool Function DetermineIfShouldRename(ActorBase TargetRef, ActorBase TargetBase)
    If TargetRef.IsUnique()
        Return UniquesRename.Find(TargetBase) >= 0
    Else
        Return NonUniqueNoRename.Find(TargetBase) < 0
    EndIf
EndFunction

Function ProcessActorRename(Actor akTarget, String newFirstName, String newLastName, Bool useQuestName)
    ; Initialize arrays if not done yet
    if !factionArray || factionArray.Length == 0
        InitializeFactionArrays()
    EndIf
    
    ; Check each faction in order
    Int i = 0
    While i < numFactions
        if ShouldProcessFaction(akTarget, i)
            ProcessFactionRename(akTarget, settingArray[i], newFirstName, newLastName, useQuestName)
            Return
        EndIf
        i += 1
    EndWhile
    
    ; Default to "Other" category
    ProcessFactionRename(akTarget, RNOther, newFirstName, newLastName, useQuestName)
EndFunction

Bool Function ShouldProcessFaction(Actor akTarget, Int factionIndex)
    ; Special cases for multi-faction checks
    if factionIndex == 1  ; Forsworn
        Return akTarget.IsInFaction(FacForsworn) || akTarget.IsInFaction(FacHagraven)
    ElseIf factionIndex == 5  ; Vampire
        Return akTarget.IsInFaction(FacVampire) || akTarget.IsInFaction(FacVampireThrall)
    Else
        Return akTarget.IsInFaction(factionArray[factionIndex])
    EndIf
EndFunction

Function ProcessFactionRename(Actor akTarget, GlobalVariable settingGV, String newFirstName, String newLastName, Bool useQuestName)
    Int setting = settingGV.GetValue() as int
    If setting == 0
        Return
    EndIf
    
    String finalName = BuildActorName(akTarget, newFirstName, newLastName, setting)
    akTarget.SetDisplayName(finalName, useQuestName)
EndFunction

String Function BuildActorName(Actor akTarget, String newFirstName, String newLastName, Int setting)
    String newName = newFirstName
    
    ; Add last name if enabled
    if (RNDoLastNames.GetValue() == 1 && newLastName != "")
        newName += " " + newLastName
    endif
    
    ; Check for cached name
    if (StorageUtil.HasStringValue(akTarget, "RNE_Name"))
        newName = StorageUtil.GetStringValue(akTarget, "RNE_Name")
    Else
        StorageUtil.SetStringValue(akTarget, "RNE_Name", newName)
    EndIf
    
    ; Add original name if setting is 2
    If setting == 2
        ActorBase TargetRef = akTarget.GetLeveledActorBase()
        String oldname = TargetRef.GetName()
        newName += ", " + oldname
    EndIf
    
    Return newName
EndFunction