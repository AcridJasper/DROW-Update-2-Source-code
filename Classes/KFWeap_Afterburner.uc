class KFWeap_Afterburner extends KFWeap_SMGBase;

// can only be on 0
`define BARREL_MIC_INDEX 0

var const float BarrelHeatPerProjectile;
var const float MaxBarrelHeat;
var const float BarrelCooldownRate;
var transient float CurrentBarrelHeat;
var transient float LastBarrelHeat;

/*
//Props related to charging the weapon
var float MaxChargeTime;
var float ValueIncreaseTime;
var float DmgIncreasePerCharge;
var float IncapIncreasePerCharge;
var int AmmoIncreasePerCharge;

var transient float ChargeTime;
var transient float ConsumeAmmoTime;
var transient float MaxChargeLevel;

var transient ParticleSystemComponent ChargedPSC;
var ParticleSystem ChargingEffect;
var ParticleSystem ChargedEffect;

var transient bool bIsFullyCharged;
var const WeaponFireSndInfo FullyChargedSound;

var float FullChargedTimerInterval;

var bool bBlocked;

const SecondaryFireAnim     = 'Shoot';
const SecondaryFireIronAnim = 'Shoot_Iron';
*/


/*
//Props related to charging the weapon
var float MaxChargeTime;
var float ValueIncreaseTime;
var float DmgIncreasePerCharge;
var float IncapIncreasePerCharge;
var int AmmoIncreasePerCharge;

var transient float ChargeTime;
var transient float ConsumeAmmoTime;
var transient float MaxChargeLevel;

var ParticleSystem ChargingEffect;
var ParticleSystem ChargedEffect;

var transient ParticleSystemComponent ChargingPSC;
var transient bool bIsFullyCharged;

var const WeaponFireSndInfo FullyChargedSound;

var float FullChargedTimerInterval;

const SecondaryFireAnim     = 'Shoot';
const SecondaryFireIronAnim = 'Shoot_Iron';
*/


/*
// How many Alt ammo to recharge per second
var float AltFullRechargeSeconds;
var transient float AltRechargePerSecond;
var transient float AltIncrement;
var repnotify byte AltAmmo;

replication
{
	if (bNetDirty && Role == ROLE_Authority)
		AltAmmo;

	if(Role == Role_Authority && bNetDirty)
		ChargeTime;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == nameof(AltAmmo))
	{
		AmmoCount[ALTFIRE_FIREMODE] = AltAmmo;
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	StartAltRecharge();
}

function StartAltRecharge()
{
	// local KFPerk InstigatorPerk;
	local float UsedAltRechargeTime;

	// begin ammo recharge on server
	if( Role == ROLE_Authority )
	{
		UsedAltRechargeTime = AltFullRechargeSeconds;
	    AltRechargePerSecond = MagazineCapacity[ALTFIRE_FIREMODE] / UsedAltRechargeTime;
		AltIncrement = 0;
	}
}

function RechargeAlt(float DeltaTime)
{
	if ( Role == ROLE_Authority )
	{
		AltIncrement += AltRechargePerSecond * DeltaTime;

		if( AltIncrement >= 1.0 && AmmoCount[ALTFIRE_FIREMODE] < MagazineCapacity[ALTFIRE_FIREMODE] )
		{
			AmmoCount[ALTFIRE_FIREMODE]++;
			AltIncrement -= 1.0;
			AltAmmo = AmmoCount[ALTFIRE_FIREMODE];
		}
	}
}

// Overridden to call StartHealRecharge on server
function GivenTo( Pawn thisPawn, optional bool bDoNotActivate )
{
	super.GivenTo( thisPawn, bDoNotActivate );

	if( Role == ROLE_Authority && !thisPawn.IsLocallyControlled() )
	{
		StartAltRecharge();
	}
}
*/

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	// Force start with "Glow_Intensity" of 0.0f
	LastBarrelHeat = MaxBarrelHeat;
	ChangeBarrelMaterial();
}

simulated function ConsumeAmmo( byte FireModeNum )
{
    local byte AmmoType;
    local KFPerk InstigatorPerk;

`if(`notdefined(ShippingPC))
    if( bInfiniteAmmo )
    {
        return;
    }
`endif

	CurrentBarrelHeat = fmin(CurrentBarrelHeat + BarrelHeatPerProjectile, MaxBarrelHeat);
	ChangeBarrelMaterial();

	AmmoType = GetAmmoType(FireModeNum);

	InstigatorPerk = GetPerk();
	if( InstigatorPerk != none && InstigatorPerk.GetIsUberAmmoActive( self ) )
	{
		return;
	}

	// If AmmoCount is being replicated, don't allow the client to modify it here
	if( Role == ROLE_Authority || bAllowClientAmmoTracking )
	{
	    // Don't consume ammo if magazine size is 0 (infinite ammo with no reload)
		if (MagazineCapacity[AmmoType] > 0 && AmmoCount[AmmoType] > 0)
		{
			// Ammo cost needs to be firemodenum because it is independent of ammo type.
			AmmoCount[AmmoType] = Max(AmmoCount[AmmoType] - AmmoCost[FireModeNum], 0);
		}
	}
}

simulated function ChangeBarrelMaterial()
{
    if( CurrentBarrelHeat != LastBarrelHeat )
    {
    	if( WeaponMICs.Length >= `BARREL_MIC_INDEX )
    	{
			WeaponMICs[`BARREL_MIC_INDEX].SetScalarParameterValue('Barrel_Intensity', CurrentBarrelHeat);
			LastBarrelHeat = CurrentBarrelHeat; 
		}
    }
}

simulated function Tick(float Delta)
{
	// if( AmmoCount[ALTFIRE_FIREMODE] < MagazineCapacity[ALTFIRE_FIREMODE] )
	// {
    //     RechargeAlt(Delta);
	// }

	Super.Tick(Delta);

	CurrentBarrelHeat = fmax(CurrentBarrelHeat - BarrelCooldownRate * Delta, 0.0f);
	ChangeBarrelMaterial();
}

/*
// Overriden to fire a projectile from CUSTOM_FIREMODE at random intervals
simulated function Projectile ProjectileFire()
{
    local KFPawn TargetPawn;
    
    if ( CurrentFireMode == DEFAULT_FIREMODE || CurrentFireMode == CUSTOM_FIREMODE )
    {
        if ( FindTarget(TargetPawn) )
        {
            if ( FRand() < MicroRocketChance )
            {
                CurrentFireMode = CUSTOM_FIREMODE;
                // FireModeNum = CUSTOM_FIREMODE;
                // BeginFire(CUSTOM_FIREMODE);
                // StartFire(CUSTOM_FIREMODE);
                
                KFPawn(Instigator).SetWeaponAmbientSound(MicroRocketSound.DefaultCue, MicroRocketSound.FirstPersonCue);
            }
        }
    }

    return super.ProjectileFire();
}
*/

/*
// Instead of switch fire mode use as immediate alt fire
simulated function AltFireMode()
{
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	StartFire(ALTFIRE_FIREMODE);
}

simulated function StartFire(byte FireModeNum)
{
	if (IsTimerActive('RefireCheckTimer'))
	{
		return;
	}

	super.StartFire(FireModeNum);
}

simulated function OnStartFire()
{
	local KFPawn PawnInst;
	PawnInst = KFPawn(Instigator);

	if (PawnInst != none)
	{
		PawnInst.OnStartFire();
	}
}
*/

/*
simulated function FireAmmunition()
{
	// Let the accuracy tracking system know that we fired
	HandleWeaponShotTaken(CurrentFireMode);

	// Handle the different fire types
	switch (WeaponFireTypes[CurrentFireMode])
	{
	case EWFT_InstantHit:
		// Launch a projectile if we are in zed time, and this weapon has a projectile to launch for this mode
		if (`IsInZedTime(self) && WeaponProjectiles[CurrentFireMode] != none )
		{
			ProjectileFire();
		}
		else
		{
			InstantFireClient();
		}
		break;

	case EWFT_Projectile:
		ProjectileFire();
		break;

	case EWFT_Custom:
		CustomFire();
		break;
	}

	// If we're firing without charging, still consume one ammo
	if (GetChargeLevel() < 1)
	{
		ConsumeAmmo(CurrentFireMode);
	}

	NotifyWeaponFired(CurrentFireMode);

	// Play fire effects now (don't wait for WeaponFired to replicate)
	PlayFireEffects(CurrentFireMode, vect(0, 0, 0));
}
*/

/*
simulated state CannonCharge extends WeaponFiring
{
    //For minimal code purposes, I'll directly call global.FireAmmunition after charging is released
    simulated function FireAmmunition() {}

    //Store start fire time so we don't have to timer this
    simulated event BeginState(Name PreviousStateName)
    {
		local KFPerk InstigatorPerk;

        super.BeginState(PreviousStateName);

		InstigatorPerk = GetPerk();
		if( InstigatorPerk != none )
		{
			SetZedTimeResist( InstigatorPerk.GetZedTimeModifier(self) );
		}

		ChargeTime = 0;
		ConsumeAmmoTime = 0;
		MaxChargeLevel = int(MaxChargeTime / ValueIncreaseTime);

		if (ChargingPSC == none)
		{
			ChargingPSC = new(self) class'ParticleSystemComponent';

			if(MySkelMesh != none)
			{
				MySkelMesh.AttachComponentToSocket(ChargingPSC, 'MuzzleFlash');
			}
			else
			{
				AttachComponent(ChargingPSC);
			}
		}
		else
		{
			ChargingPSC.ActivateSystem();
		}

		bIsFullyCharged = false;

		global.OnStartFire();

		if(ChargingPSC != none)
		{
			ChargingPSC.SetTemplate(ChargingEffect);
		}
    }

	simulated function bool ShouldRefire()
	{
		// ignore how much ammo is left (super/global counts ammo)
		return StillFiring(CurrentFireMode);
	}

    simulated event Tick(float DeltaTime)
    {
        local float ChargeRTPC;

		global.Tick(DeltaTime);

		// Don't charge unless we're holding down the button
		if (PendingFire(CurrentFireMode))
		{
			ConsumeAmmoTime += DeltaTime;
		}

		if (bIsFullyCharged)
		{
			if (ConsumeAmmoTime >= FullChargedTimerInterval)
			{
				//ConsumeAmmo(ALTFIRE_FIREMODE);
				ConsumeAmmoTime -= FullChargedTimerInterval;
			}

			return;
		}

		// Don't charge unless we're holding down the button
		if (PendingFire(CurrentFireMode))
		{
			ChargeTime += DeltaTime;
		}

		ChargeRTPC = FMin(ChargeTime / MaxChargeTime, 1.f);
        KFPawn(Instigator).SetWeaponComponentRTPCValue("Weapon_Charge", ChargeRTPC); //For looping component
        Instigator.SetRTPCValue('Weapon_Charge', ChargeRTPC); //For one-shot sounds

		if (ConsumeAmmoTime >= ValueIncreaseTime)
		{
			ConsumeAmmo(ALTFIRE_FIREMODE);
			ConsumeAmmoTime -= ValueIncreaseTime;
		}

		if (ChargeTime >= MaxChargeTime || !HasAmmo(ALTFIRE_FIREMODE))
		{
			bIsFullyCharged = true;
			ChargingPSC.SetTemplate(ChargedEffect);
			KFPawn(Instigator).SetWeaponAmbientSound(FullyChargedSound.DefaultCue, FullyChargedSound.FirstPersonCue);
		}
    }

    //Now that we're done charging, directly call FireAmmunition. This will handle the actual projectile fire and scaling.
    simulated event EndState(Name NextStateName)
    {
		ClearZedTimeResist();
        ClearPendingFire(CurrentFireMode);
		ClearTimer(nameof(RefireCheckTimer));

		KFPawn(Instigator).bHasStartedFire = false;
		KFPawn(Instigator).bNetDirty = true;

		if (ChargingPSC != none)
		{
			ChargingPSC.DeactivateSystem();
		}

		KFPawn(Instigator).SetWeaponAmbientSound(none);
    }

	simulated function HandleFinishedFiring()
	{
		global.FireAmmunition();

		// Gotta restart the timer every shot :(
		if( IsTimerActive(nameOf(RefireCheckTimer)) )
		{
			ClearTimer( nameOf(RefireCheckTimer) );
			TimeWeaponFiring( CurrentFireMode );
		}

		if (bPlayingLoopingFireAnim)
		{
			StopLoopingFireEffects(CurrentFireMode);
		}

		if (MuzzleFlash != none)
		{
			SetTimer(MuzzleFlash.MuzzleFlash.Duration, false, 'Timer_StopFireEffects');
		}
		else
		{
			SetTimer(0.3f, false, 'Timer_StopFireEffects');
		}

		NotifyWeaponFinishedFiring(CurrentFireMode);

		super.HandleFinishedFiring();
	}
}

simulated function name GetWeaponFireAnim(byte FireModeNum)
{
	if (FireModeNum == ALTFIRE_FIREMODE)
	{
		return bUsingSights ? SecondaryFireIronAnim : SecondaryFireAnim;
	}
	
	return super.GetWeaponFireAnim(FireModeNum);
}

// Placing the actual Weapon Firing end state here since we need it to happen at the end of the actual firing loop.
simulated function Timer_StopFireEffects()
{
	// Simulate weapon firing effects on the local client
	if (WorldInfo.NetMode == NM_Client)
	{
		Instigator.WeaponStoppedFiring(self, false);
	}

	ClearFlashCount();
	ClearFlashLocation();
}

simulated function KFProjectile SpawnProjectile(class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir)
{
    local KFProj_Bullet_Afterburner_ALT CannonShot;
    local int Charges;

    CannonShot = KFProj_Bullet_Afterburner_ALT(super.SpawnProjectile(KFProjClass, RealStartLoc, AimDir));

    //Calc and set scaling values
    if (CannonShot != none)
    {
        Charges = GetChargeLevel();
        CannonShot.DamageScale = 1.f + DmgIncreasePerCharge * Charges;
        CannonShot.IncapScale = 1.f + IncapIncreasePerCharge * Charges;

        return CannonShot;
    }

    return none;
}

simulated function int GetChargeLevel()
{
	return Min(ChargeTime / ValueIncreaseTime, MaxChargeLevel);
}

// Should generally match up with KFWeapAttach_HuskCannon::GetChargeFXLevel
simulated function int GetChargeFXLevel()
{
	local int ChargeLevel;

	ChargeLevel = GetChargeLevel();
	if (ChargeLevel < 1)
	{
		return 1;
	}
	else if (ChargeLevel < MaxChargeLevel)
	{
		return 2;
	}
	else
	{
		return 3;
	}
}

// increase the instant hit damage based on the charge level
simulated function int GetModifiedDamage(byte FireModeNum, optional vector RayDir)
{
	local int ModifiedDamage;

	ModifiedDamage = super.GetModifiedDamage(FireModeNum, RayDir);
	if (FireModeNum == ALTFIRE_FIREMODE)
	{
		ModifiedDamage = ModifiedDamage * (1.f + DmgIncreasePerCharge * GetChargeLevel());
	}

	return ModifiedDamage;
}
*/


/*


// Instead of switch fire mode use as immediate alt fire
simulated function AltFireMode()
{
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	StartFire(ALTFIRE_FIREMODE);
}

simulated function name GetWeaponFireAnim(byte FireModeNum)
{
	if (FireModeNum == ALTFIRE_FIREMODE)
	{
		return bUsingSights ? SecondaryFireIronAnim : SecondaryFireAnim;
	}
	
	return super.GetWeaponFireAnim(FireModeNum);
}

simulated function StartFire(byte FiremodeNum)
{
	if (IsTimerActive('RefireCheckTimer'))
	{
		return;
	}
 
	if (bBlocked && AmmoCount[0] == 0 && !IsTimerActive(nameof(RefireCheckTimer)) && !IsTimerActive(nameof(UnlockClientFire)))
	{
		bBlocked = false;
	}

	if(Role != Role_Authority && FireModeNum == DEFAULT_FIREMODE && HasAmmo(DEFAULT_FIREMODE))
	{
		bBlocked = true;
		if(IsTimerActive(nameof(UnlockClientFire)))
		{
			ClearTimer(nameof(UnlockClientFire));
		}
	}

	super.StartFire(FiremodeNum);

	if ( PendingFire(RELOAD_FIREMODE) && Role != Role_Authority)
	{
		bBlocked = false;
	}
}

simulated function RefireCheckTimer()
{
	Super.RefireCheckTimer();
	if(bBlocked && Role != Role_Authority)
	{
		SetTimer(0.25f , false, nameof(UnlockClientFire));
	}
}

reliable client function UnlockClientFire()
{
	bBlocked = false;
}

simulated function OnStartFire()
{
	local KFPawn PawnInst;
	PawnInst = KFPawn(Instigator);

	if (PawnInst != none)
	{
		PawnInst.OnStartFire();
	}
}
*/

/*
simulated event bool HasAmmo( byte FireModeNum, optional int Amount )
{
	local KFPerk InstigatorPerk;
	// we can always do a melee attack
	if( FireModeNum == BASH_FIREMODE )
	{
		return TRUE;
	}
	else if ( FireModeNum == RELOAD_FIREMODE )
	{
		return CanReload();
	}
	else if ( FireModeNum == GRENADE_FIREMODE )
	{
        if( KFInventoryManager(InvManager) != none )
        {
            return KFInventoryManager(InvManager).HasGrenadeAmmo(Amount);
        }
	}
	
	InstigatorPerk = GetPerk();
	if( InstigatorPerk != none && InstigatorPerk.GetIsUberAmmoActive( self ) )
	{
		return true;
	}

	// If passed in ammo isn't set, use default ammo cost.
	if( Amount == 0 )
	{
		Amount = AmmoCost[FireModeNum];
	}

	return AmmoCount[GetAmmoType(FireModeNum)] >= Amount;
}
*/

/*
simulated state MineReconstructorCharge extends WeaponFiring
{
    //For minimal code purposes, I'll directly call global.FireAmmunition after charging is released
    simulated function FireAmmunition()
    {
		return;
	}

    //Store start fire time so we don't have to timer this
    simulated event BeginState(Name PreviousStateName)
    {
		local KFPerk InstigatorPerk;

        super.BeginState(PreviousStateName);

		InstigatorPerk = GetPerk();
		if( InstigatorPerk != none )
		{
			SetZedTimeResist( InstigatorPerk.GetZedTimeModifier(self) );
		}

		ChargeTime = 0;
		ConsumeAmmoTime = 0;

		bIsFullyCharged = false;

		global.OnStartFire();

		ChargeTime = 0;

		if(ChargedPSC != none)
		{
			ChargedPSC.SetTemplate(ChargingEffect);
		}
    }

	simulated function bool ShouldRefire()
	{
		// ignore how much ammo is left (super/global counts ammo)
		return StillFiring(CurrentFireMode);
	}

    simulated event Tick(float DeltaTime)
    {
        local float ChargeRTPC;

		global.Tick(DeltaTime);

		if(bIsFullyCharged) return;

		// Don't charge unless we're holding down the button
		if (PendingFire(CurrentFireMode))
		{
			ConsumeAmmoTime += DeltaTime;
		}

		if (bIsFullyCharged)
		{
			if (ConsumeAmmoTime >= FullChargedTimerInterval)
			{
				ConsumeAmmo(ALTFIRE_FIREMODE);
				ConsumeAmmoTime -= FullChargedTimerInterval;
			}

			return;
		}

		// Don't charge unless we're holding down the button
		if (PendingFire(CurrentFireMode))
		{
			if(Role == Role_Authority && !bIsFullyCharged)
			{
				ChargeTime += DeltaTime;
				bNetDirty = true;
			}
		}

		ChargeRTPC = FMin(ChargeTime / MaxChargeTime, 1.f);
        KFPawn(Instigator).SetWeaponComponentRTPCValue("Weapon_Charge", ChargeRTPC); //For looping component
        Instigator.SetRTPCValue('Weapon_Charge', ChargeRTPC); //For one-shot sounds
		
		if (ConsumeAmmoTime >= ValueIncreaseTime && !bIsFullyCharged)
		{
			ConsumeAmmo(ALTFIRE_FIREMODE);
			ConsumeAmmoTime -= ValueIncreaseTime;
		}

		if (ChargeTime >= MaxChargeTime || !HasAmmo(ALTFIRE_FIREMODE))
		{
			bIsFullyCharged = true;

			if(( Instigator.Role != ROLE_Authority ) || WorldInfo.NetMode == NM_Standalone)
			{
				if (ChargedPSC == none)
				{
					ChargedPSC = new(self) class'ParticleSystemComponent';
	
					if(MySkelMesh != none)
					{
						MySkelMesh.AttachComponentToSocket(ChargedPSC, 'MuzzleFlash');
					}
					else
					{
						AttachComponent(ChargedPSC);
					}
				}
				else
				{
					ChargedPSC.ActivateSystem();
				}
	
				ChargedPSC.SetTemplate(ChargedEffect);
	
				KFPawn(Instigator).SetWeaponAmbientSound(FullyChargedSound.DefaultCue, FullyChargedSound.FirstPersonCue);
			}
		}
    }

    //Now that we're done charging, directly call FireAmmunition. This will handle the actual projectile fire and scaling.
    simulated event EndState(Name NextStateName)
    {
		if(Role == Role_Authority)
		{
			UnlockClientFire();
		}

		ClearZedTimeResist();
        ClearPendingFire(CurrentFireMode);
		ClearTimer(nameof(RefireCheckTimer));

		KFPawn(Instigator).bHasStartedFire = false;
		KFPawn(Instigator).bNetDirty = true;

		if (ChargedPSC != none)
		{
			ChargedPSC.DeactivateSystem();
		}

		KFPawn(Instigator).SetWeaponAmbientSound(none);
    }

	simulated function HandleFinishedFiring()
	{
		global.FireAmmunition();

		if (bPlayingLoopingFireAnim)
		{
			StopLoopingFireEffects(CurrentFireMode);
		}

		NotifyWeaponFinishedFiring(CurrentFireMode);

		super.HandleFinishedFiring();
	}

	simulated function PutDownWeapon()
	{
		global.FireAmmunition();

		if (bPlayingLoopingFireAnim)
		{
			StopLoopingFireEffects(CurrentFireMode);
		}
		
		NotifyWeaponFinishedFiring(CurrentFireMode);
		
		if(Role == Role_Authority)
		{
			UnlockClientFire();
		}

		super.PutDownWeapon();
	}
}

simulated state Active
{
	simulated function BeginState(name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);

		if(Role == Role_Authority)
		{
			UnlockClientFire();
		}
	}
}

simulated function KFProjectile SpawnProjectile(class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir)
{
    local KFProj_Bullet_Afterburner_ALT CannonShot;
    local int Charges;

    CannonShot = KFProj_Bullet_Afterburner_ALT(super.SpawnProjectile(KFProjClass, RealStartLoc, AimDir));

    //Calc and set scaling values
    if (CannonShot != none)
    {
        Charges = GetChargeLevel();
        CannonShot.DamageScale = 1.f + DmgIncreasePerCharge * Charges;
        CannonShot.IncapScale = 1.f + IncapIncreasePerCharge * Charges;

        return CannonShot;
    }

    return none;
}

simulated function int GetChargeLevel()
{
	return Min(ChargeTime / ValueIncreaseTime, MaxChargeLevel);
}


*/


// Overriden to use instant hit vfx.Basically, calculate the hit location so vfx can play
simulated function Projectile ProjectileFire()
{
	local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
	local ImpactInfo	TestImpact;
	local vector DirA, DirB;
	local Quat Q;
	local class<KFProjectile> MyProjectileClass;

    // local KFPawn TargetPawn;

    MyProjectileClass = GetKFProjectileClass();

	StartTrace = GetSafeStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));

	RealStartLoc = GetPhysicalFireStartLoc(AimDir);

	EndTrace = StartTrace + AimDir * GetTraceRange();
	TestImpact = CalcWeaponFire( StartTrace, EndTrace );

	if( Instigator != None )
	{
		Instigator.SetFlashLocation( Self, CurrentFireMode, TestImpact.HitLocation );
	}

	if( Role == ROLE_Authority || (MyProjectileClass.default.bUseClientSideHitDetection
        && MyProjectileClass.default.bNoReplicationToInstigator && Instigator != none
        && Instigator.IsLocallyControlled()) )
	{
		if( StartTrace != RealStartLoc )
		{	
            DirB = AimDir;

			AimDir = Normal(TestImpact.HitLocation - RealStartLoc);

    		DirA = AimDir;

    		if ( (DirA dot DirB) < MaxAimAdjust_Cos )
    		{
    			Q = QuatFromAxisAndAngle(Normal(DirB cross DirA), MaxAimAdjust_Angle);
    			AimDir = QuatRotateVector(Q,DirB);
    		}
		}

		return SpawnAllProjectiles(MyProjectileClass, RealStartLoc, AimDir);
	}

	return None;
}

static simulated event EFilterTypeUI GetAltTraderFilter()
{
	return FT_Flame;
}

/*
// Allows weapon to set its own trader stats (can set number of stats, names and values of stats)
static simulated event SetTraderWeaponStats( out array<STraderItemWeaponStats> WeaponStats )
{
	super.SetTraderWeaponStats( WeaponStats );

	WeaponStats.Length = WeaponStats.Length + 1;
	WeaponStats[WeaponStats.Length-1].StatType = TWS_RechargeTime;
	WeaponStats[WeaponStats.Length-1].StatValue = default.AltFullRechargeSeconds;
}
*/

defaultproperties
{
	// Inventory
	InventorySize=4
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Afterburner_MAT.UI_WeaponSelect_Afterburner'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DTest' // Loot beam fx (no offset)

	// FOV
	MeshFOV=75
	MeshIronSightFOV=60
	PlayerIronSightFOV=75

	// Zooming/Position
	IronSightPosition=(X=15.f,Y=0,Z=0)
	PlayerViewOffset=(X=18.f,Y=8,Z=-5.0)

	// Content
	PackageKey="Afterburner"
	FirstPersonMeshName="WEP_Afterburner_MESH.Wep_1stP_Afterburner_Rig"
	FirstPersonAnimSetNames(0)="WEP_Afterburner_ARCH.WEP_1P_Afterburner_ANIM"
	PickupMeshName="WEP_Afterburner_MESH.Wep_3rdP_Afterburner_Pickup"
	AttachmentArchetypeName="WEP_Afterburner_ARCH.Wep_Afterburner_3P"
	MuzzleFlashTemplateName="WEP_Afterburner_ARCH.Wep_Afterburner_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=40
	SpareAmmoCapacity[0]=400 //360
	InitialSpareMags[0]=4
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=60
	minRecoilPitch=40
	maxRecoilYaw=50
	minRecoilYaw=-50
	RecoilRate=0.06
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=550 //900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=75
	RecoilISMinYawLimit=65460
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	IronSightMeshFOVCompensationScale=1.6
	WalkingRecoilModifier=1.1
	JoggingRecoilModifier=1.2

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Afterburner'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Afterburner'
	FireInterval(DEFAULT_FIREMODE)=+0.05 // 1200 RPM
	Spread(DEFAULT_FIREMODE)=0.01
	InstantHitDamage(DEFAULT_FIREMODE)=32
	AmmoCost(DEFAULT_FIREMODE)=1
	FireOffset=(X=30,Y=4.5,Z=-5)

    MaxBarrelHeat=1.5f
	BarrelHeatPerProjectile=0.2f
	BarrelCooldownRate=1.2f
	
	CurrentBarrelHeat=0.0f
	LastBarrelHeat=0.0f

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

/*
	// ALT_FIREMODE
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'UI_SecondaryAmmo_TEX.GasTank'
	FiringStatesArray(ALTFIRE_FIREMODE)=MineReconstructorCharge //CannonCharge
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_Afterburner_ALT'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Fire_Mac10'
	InstantHitDamage(ALTFIRE_FIREMODE)=60
	FireInterval(ALTFIRE_FIREMODE)=0.15 // 400 RPM //+0.223 //269 RPMs
	PenetrationPower(ALTFIRE_FIREMODE)=0
	Spread(ALTFIRE_FIREMODE)=0.005
	AmmoCost(ALTFIRE_FIREMODE)=10

	// FullChargedTimerInterval=2.0f
    // MaxChargeTime=1.0
    // ValueIncreaseTime=0.2
    // DmgIncreasePerCharge=0.8
    // IncapIncreasePerCharge=0.22
    // AmmoIncreasePerCharge=1

	FullChargedTimerInterval=2.0f
    MaxChargeTime=0.6
    AmmoIncreasePerCharge=1
	ValueIncreaseTime=0.1
    DmgIncreasePerCharge=0.8
    IncapIncreasePerCharge=0.22
	bBlocked = false;
	bAllowClientAmmoTracking = false;

	AltAmmo=100
	MagazineCapacity[1]=100
	AltFullRechargeSeconds=15
	bCanRefillSecondaryAmmo=false;
    SecondaryAmmoTexture=Texture2D'UI_SecondaryAmmo_TEX.GasTank'

	// Charging effects
	ChargingEffect=ParticleSystem'DTest_EMIT.FX_Afterburner_Charging'
	ChargedEffect=ParticleSystem'DTest_EMIT.FX_Afterburner_Charged'
*/

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Mac10'
	InstantHitDamage(BASH_FIREMODE)=25

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_3P_Loop', FirstPersonCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_1P_Loop')
	WeaponFireLoopEndSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_3P_EndLoop', FirstPersonCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_1P_EndLoop')
	WeaponFireSnd(2)=(DefaultCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_3P_Single', FirstPersonCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_1P_Single')
	SingleFireSoundIndex=2
	
	// WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_BallisticBouncer.Play_WEP_HRG_BallisticBouncer_3P_Start', FirstPersonCue=AkEvent'WW_WEP_HRG_BallisticBouncer.Play_WEP_HRG_BallisticBouncer_1P_Start')
	// FullyChargedSound=(DefaultCue = AkEvent'WW_WEP_Lazer_Cutter.Play_WEP_LaserCutter_Beam_Charged_LP_Level_0_3P', FirstPersonCue=AkEvent'WW_WEP_Lazer_Cutter.Play_WEP_LaserCutter_Beam_Charged_LP_Level_0_3P')
	// WeaponFireLoopEndSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_1P')

	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_MedicSMG.Play_SA_MedicSMG_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_MedicSMG.Play_SA_MedicSMG_Handling_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=true
	bLoopingFireSnd(DEFAULT_FIREMODE)=true
	// bLoopingFireAnim(ALTFIRE_FIREMODE)=true
	// bLoopingFireSnd(ALTFIRE_FIREMODE)=true

	// Attachments
	bHasIronSights=true
	bHasFlashlight=true

	// Shooting Animations
	FireSightedAnims[0]=Shoot_Iron
	FireSightedAnims[1]=Shoot_Iron2
	FireSightedAnims[2]=Shoot_Iron3

	AssociatedPerkClasses(0)=class'KFPerk_Firebug'
	AssociatedPerkClasses(1)=class'KFPerk_SWAT'
	AssociatedPerkClasses(2)=class'KFPerk_Demolitionist'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Damage1, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.3f), (Stat=EWUS_Damage1, Scale=1.3f), (Stat=EWUS_Weight, Add=2)))
}