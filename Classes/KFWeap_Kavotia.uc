class KFWeap_Kavotia extends KFWeapon; //KFWeap_RifleBase

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

var AkEvent AmbientSoundPlayEvent;
var AkEvent	AmbientSoundStopEvent;

// Particle system
var transient KFParticleSystemComponent ParticlePSC;
var const ParticleSystem ParticleFXTemplate;

// Point light
var PointLightComponent IdleLight;
var Name LightAttachBone;

// How many Alt ammo to recharge per second
var float AmmoFullRechargeSeconds;
var transient float AmmoRechargePerSecond;
var transient float AmmoIncrement;
var repnotify byte FakeAmmo;

replication
{
	if (bNetDirty && Role == ROLE_Authority)
		FakeAmmo;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == nameof(FakeAmmo))
	{
		AmmoCount[DEFAULT_FIREMODE] = FakeAmmo;
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	StartAmmoRecharge();
}

function StartAmmoRecharge()
{
	// local KFPerk InstigatorPerk;
	local float UsedAmmoRechargeTime;

	// begin ammo recharge on server
	if( Role == ROLE_Authority )
	{
		UsedAmmoRechargeTime = AmmoFullRechargeSeconds;
	    AmmoRechargePerSecond = MagazineCapacity[DEFAULT_FIREMODE] / UsedAmmoRechargeTime;
		AmmoIncrement = 0;
	}
}

function RechargeAmmo(float DeltaTime)
{
	if ( Role == ROLE_Authority )
	{
		AmmoIncrement += AmmoRechargePerSecond * DeltaTime;

		if( AmmoIncrement >= 1.0 && AmmoCount[DEFAULT_FIREMODE] < MagazineCapacity[DEFAULT_FIREMODE] )
		{
			AmmoCount[DEFAULT_FIREMODE]++;
			AmmoIncrement -= 1.0;
			FakeAmmo = AmmoCount[DEFAULT_FIREMODE];
		}
	}
}

// Overridden to call StartHealRecharge on server
function GivenTo( Pawn thisPawn, optional bool bDoNotActivate )
{
	super.GivenTo( thisPawn, bDoNotActivate );

	if( Role == ROLE_Authority && !thisPawn.IsLocallyControlled() )
	{
		StartAmmoRecharge();
	}
}

simulated event Tick( FLOAT DeltaTime )
{
    if( AmmoCount[DEFAULT_FIREMODE] < MagazineCapacity[DEFAULT_FIREMODE] )
	{
        RechargeAmmo(DeltaTime);
	}

	Super.Tick(DeltaTime);
}

// Alt doesn't count as ammo for purposes of inventory management (e.g. switching) 
simulated function bool HasAnyAmmo()
{
	return HasSpareAmmo() || HasAmmo(ALTFIRE_FIREMODE);
}

simulated function string GetSpecialAmmoForHUD()
{
	return int(FakeAmmo)$"%";
}

simulated function bool CanBuyAmmo()
{
	return false;
}

// Allows weapon to set its own trader stats (can set number of stats, names and values of stats)
static simulated event SetTraderWeaponStats( out array<STraderItemWeaponStats> WeaponStats )
{
	super.SetTraderWeaponStats( WeaponStats );

	WeaponStats.Length = WeaponStats.Length + 1;
	WeaponStats[WeaponStats.Length-1].StatType = TWS_RechargeTime;
	WeaponStats[WeaponStats.Length-1].StatValue = default.AmmoFullRechargeSeconds;
}

simulated state WeaponEquipping
{
	// when picked up, start the persistent sound
	simulated event BeginState(Name PreviousStateName)
	{
		local KFPawn InstigatorPawn;

		super.BeginState(PreviousStateName);

		ActivatePSC(ParticlePSC, ParticleFXTemplate, 'MuzzleFlash');

		if (MySkelMesh != none)
		{
			MySkelMesh.AttachComponentToSocket(IdleLight, LightAttachBone);
			IdleLight.SetEnabled(true);
		}

		if (Instigator != none)
		{
			InstigatorPawn = KFPawn(Instigator);
			if (InstigatorPawn != none)
			{
				InstigatorPawn.PlayWeaponSoundEvent(AmbientSoundPlayEvent);
			}
		}
	}
}

simulated function ActivatePSC(out KFParticleSystemComponent OutPSC, ParticleSystem ParticleEffect, name SocketName)
{
	if (MySkelMesh != none)
	{
		MySkelMesh.AttachComponentToSocket(OutPSC, SocketName);
		OutPSC.SetFOV(MySkelMesh.FOV);
	}
	else
	{
		AttachComponent(OutPSC);
	}

	OutPSC.ActivateSystem();

	if (OutPSC != none)
	{
		OutPSC.SetTemplate(ParticleEffect);
		// OutPSC.SetAbsolute(false, false, false);
		OutPSC.SetDepthPriorityGroup(SDPG_Foreground);
	}
}

simulated event SetFOV( float NewFOV )
{
	super.SetFOV(NewFOV);

	if (ParticlePSC != none)
	{
		ParticlePSC.SetFOV(NewFOV);
	}
}

simulated state Inactive
{
	// when dropped, destroyed, etc, play the stop on the persistent sound
	simulated event BeginState(Name PreviousStateName)
	{
		local KFPawn InstigatorPawn;

		super.BeginState(PreviousStateName);

		if (ParticlePSC != none)
		{
			ParticlePSC.DeactivateSystem();
		}

		IdleLight.SetEnabled(false);

		if (Instigator != none)
		{
			InstigatorPawn = KFPawn(Instigator);
			if (InstigatorPawn != none)
			{
				InstigatorPawn.PlayWeaponSoundEvent(AmbientSoundStopEvent);
			}
		}
	}
}

simulated state WeaponPuttingDown
{
	simulated event BeginState(Name PreviousStateName)
	{
		local KFPawn InstigatorPawn;

		super.BeginState(PreviousStateName);

		if (Instigator != none)
		{
			InstigatorPawn = KFPawn(Instigator);
			if (InstigatorPawn != none)
			{
				InstigatorPawn.PlayWeaponSoundEvent(AmbientSoundStopEvent);
			}
		}
	}
}

simulated state WeaponAbortEquip
{
	simulated event BeginState(Name PreviousStateName)
	{
		local KFPawn InstigatorPawn;
		
		super.BeginState(PreviousStateName);

		if (Instigator != none)
		{
			InstigatorPawn = KFPawn(Instigator);
			if (InstigatorPawn != none)
			{
				InstigatorPawn.PlayWeaponSoundEvent(AmbientSoundStopEvent);
			}
		}
	}
}

simulated function PlayFiringSound( byte FireModeNum )
{
    local byte UsedFireModeNum;

	MakeNoise(1.0,'PlayerFiring'); // AI

	if (MedicComp != none && FireModeNum == ALTFIRE_FIREMODE)
	{
		MedicComp.PlayFiringSound();
	}
	else
	if ( !bPlayingLoopingFireSnd )
	{
		UsedFireModeNum = FireModeNum;

		// Use the single fire sound if we're in zed time and want to play single fire sounds
		if( FireModeNum < bLoopingFireSnd.Length && bLoopingFireSnd[FireModeNum] && ShouldForceSingleFireSound() )
        {
            UsedFireModeNum = SingleFireSoundIndex;
        }

        if ( UsedFireModeNum < WeaponFireSound.Length )
		{
			WeaponPlayFireSound(WeaponFireSound[UsedFireModeNum].DefaultCue, WeaponFireSound[UsedFireModeNum].FirstPersonCue);
		}
	}
}

/** Returns trader filter index based on weapon type */
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Rifle;
}

defaultproperties
{
	// Inventory
	InventorySize=4
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Kavotia_MAT.UI_WeaponSelect_Kavotia'
	AssociatedPerkClasses(0)=class'KFPerk_Survivalist'
	AssociatedPerkClasses(1)=class'KFPerk_Commando'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DTest' // Loot beam fx (no offset)

	// FOV
	MeshFOV=75
	MeshIronSightFOV=60
	PlayerIronSightFOV=75

	// Zooming/Position
	IronSightPosition=(X=15.f,Y=7,Z=0)
	PlayerViewOffset=(X=18.f,Y=8,Z=-5.0)

	// Content
	PackageKey="Kavotia"
	FirstPersonMeshName="WEP_Kavotia_MESH.Wep_1stP_Kavotia_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_MAC10_ANIM.WEP_1P_MAC10_ANIM"
	PickupMeshName="WEP_Kavotia_MESH.Wep_Kavotia_Pickup"
	AttachmentArchetypeName="WEP_Kavotia_ARCH.WEP_Kavotia_3P"
	MuzzleFlashTemplateName="WEP_Kavotia_ARCH.Wep_Kavotia_MuzzleFlash"

	// Ammo
	AmmoFullRechargeSeconds=10
	FakeAmmo=100
	MagazineCapacity[0]=100
	SpareAmmoCapacity[0]=0
	InitialSpareMags[0]=0
	bCanBeReloaded=false //true
	bReloadFromMagazine=false //true

	// Recoil
	maxRecoilPitch=90
	minRecoilPitch=80
	maxRecoilYaw=75
	minRecoilYaw=-75
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
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Electricity'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_InstantHit
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Kavotia'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Kavotia'
	FireInterval(DEFAULT_FIREMODE)=0.2 // 300 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=100
	Spread(DEFAULT_FIREMODE)=0.01
	PenetrationPower(DEFAULT_FIREMODE)=3.0
	AmmoCost(DEFAULT_FIREMODE)=5
	FireOffset=(X=30,Y=4.5,Z=-5)

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Mac10'
	InstantHitDamage(BASH_FIREMODE)=26

	// Fire Effects
	// WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_3P_Loop', FirstPersonCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_1P_Loop')
	// WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_3P_Single', FirstPersonCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_1P_Single')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Kavotia_SND.greypistol_shoot_3p_Cue', FirstPersonCue=SoundCue'WEP_Kavotia_SND.greypistol_shoot1_Cue')
	WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_Kavotia_SND.greypistol_shoot_3p_Cue', FirstPersonCue=SoundCue'WEP_Kavotia_SND.greypistol_shoot1_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_MedicSMG.Play_SA_MedicSMG_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Dart_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=false
	bLoopingFireSnd(DEFAULT_FIREMODE)=false
	// WeaponFireLoopEndSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_3P_EndLoop', FirstPersonCue=AkEvent'WW_WEP_Mac_10.Play_Mac_10_Fire_1P_EndLoop')
	// SingleFireSoundIndex=ALTFIRE_FIREMODE

	// Particle system
	Begin Object Class=KFParticleSystemComponent Name=BasePSC0
		TickGroup=TG_PostUpdateWork
	End Object
	ParticlePSC=BasePSC0
	ParticleFXTemplate=ParticleSystem'DTest_EMIT.FX_Kavotia_ParticleFX'

	// Point light
    Begin Object Class=PointLightComponent Name=IdlePointLight
		LightColor=(R=204,G=0,B=204,A=255)
		Brightness=1.5f //0.125f
		FalloffExponent=4.f
		Radius=50.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=TRUE
		bCastPerObjectShadows=false
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object
	IdleLight=IdlePointLight
	LightAttachBone=MuzzleFlash

	//Ambient Sounds
    AmbientSoundPlayEvent=AkEvent'WEP_Kavotia_SND.Play_Kavotia_Loop_1P'
    AmbientSoundStopEvent=AkEvent'WEP_Kavotia_SND.Stop_Kavotia_Loop_1P'

	// Attachments
	bHasIronSights=true
	bHasFlashlight=true

	// Shooting Animations
	FireAnim=Shoot
	FireSightedAnims[0]=Shoot_Iron
	FireSightedAnims[1]=Shoot_Iron2
	FireSightedAnims[2]=Shoot_Iron3
}