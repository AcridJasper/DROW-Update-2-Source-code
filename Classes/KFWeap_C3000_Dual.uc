class KFWeap_C3000_Dual extends KFWeap_DualBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

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

simulated state WeaponFiring
{
	simulated function BeginState(Name PrevStateName)
	{
		local KFPerk InstigatorPerk;

		InstigatorPerk = GetPerk();
		if( InstigatorPerk != none )
		{
			SetZedTimeResist( InstigatorPerk.GetZedTimeModifier(self) );
		}
		if ( bLoopingFireSnd.Length > 0 )
		{
			StartLoopingFireSound(CurrentFireMode);
		}

		super.BeginState(PrevStateName);
	}

	simulated function FireAmmunition()
    {
    	bFireFromRightWeapon = !bFireFromRightWeapon;
        Super.FireAmmunition();
	}

	simulated function EndState(Name NextStateName)
	{
		super.EndState(NextStateName);

		ClearZedTimeResist();

		// Simulate weapon firing effects on the local client
		if( WorldInfo.NetMode == NM_Client )
		{
			Instigator.WeaponStoppedFiring(self, false);
		}

		if ( bPlayingLoopingFireSnd )
		{
			StopLoopingFireSound(CurrentFireMode);
		}
	}
}

simulated event vector GetMuzzleLoc()
{
    local Rotator ViewRotation;
	if( bFireFromRightWeapon )
	{
		if( Instigator != none )
		{
				ViewRotation = Instigator.GetViewRotation();

				// Add in the free-aim rotation
				if ( KFPlayerController(Instigator.Controller) != None )
				{	
					ViewRotation += KFPlayerController(Instigator.Controller).WeaponBufferRotation;
				}

			if( bUsingSights )
			{
				return Instigator.GetWeaponStartTraceLocation() + (FireOffset >> ViewRotation);
			}
			else
			{
				return Instigator.GetPawnViewLocation() + (FireOffset >> ViewRotation);
			}

		}
		return Location;
	}
	else
	{
		return GetLeftMuzzleLoc();
	}
}

// Overriden to use instant hit vfx.Basically, calculate the hit location so vfx can play
simulated function Projectile ProjectileFire()
{
	local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
	local ImpactInfo	TestImpact;
	local vector DirA, DirB;
	local Quat Q;
	local class<KFProjectile> MyProjectileClass;

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

// Returns trader filter index based on weapon type
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Explosive;
}

defaultproperties
{
	// Content
	PackageKey="C3000"
	FirstPersonMeshName="WEP_C3000_MESH.Wep_1stP_Dual_C3000_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_Dual_M1911_ANIM.Wep_1stP_Dual_M1911_Anim"
	PickupMeshName="WEP_C3000_MESH.Wep_C3000_Pickup"
	AttachmentArchetypeName="WEP_C3000_ARCH.WEP_C3000_Dual_3P"
	MuzzleFlashTemplateName="WEP_C3000_ARCH.Wep_C3000_MuzzleFlash"

	FireOffset=(X=17,Y=4.0,Z=-2.25)
	LeftFireOffset=(X=17,Y=-4,Z=-2.25)

	// Zooming/Position
	IronSightPosition=(X=15,Y=0,Z=0)
	PlayerViewOffset=(X=16,Y=0,Z=-5)
	QuickWeaponDownRotation=(Pitch=-8192,Yaw=0,Roll=0)

	bCanThrow=true
	bDropOnDeath=true

	SingleClass=class'KFWeap_C3000'

	// FOV
	MeshFOV=75
	MeshIronSightFOV=60
    PlayerIronSightFOV=77

	// Ammo
	MagazineCapacity[0]=16
	SpareAmmoCapacity[0]=144 //128
	InitialSpareMags[0]=3
	AmmoPickupScale[0]=1.0
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=95
	minRecoilPitch=85
	maxRecoilYaw=70
	minRecoilYaw=-70
	RecoilRate=0.07
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=500
	RecoilISMinPitchLimit=65485
	IronSightMeshFOVCompensationScale=1.35

	FireTweenTime=0.03

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_C3000'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_C3000'
	FireInterval(DEFAULT_FIREMODE)=+.075 // 800 RPM //+0.1 // 600 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=50
	PenetrationPower(DEFAULT_FIREMODE)=0
	Spread(DEFAULT_FIREMODE)=0.015

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

/*	
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_C3000'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_C3000'
	FireInterval(ALTFIRE_FIREMODE)=+.075 // 800 RPM //+0.1 // 600 RPM
	InstantHitDamage(ALTFIRE_FIREMODE)=50.0
	PenetrationPower(ALTFIRE_FIREMODE)=1.0
	Spread(ALTFIRE_FIREMODE)=0.015
*/

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Colt1911'
	InstantHitDamage(BASH_FIREMODE)=24

	// Fire Effects
	// WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_1911.Play_WEP_SA_1911_Fire_Single_M', FirstPersonCue=AkEvent'WW_WEP_1911.Play_WEP_SA_1911_Fire_Single_S')
	// WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_1911.Play_WEP_SA_1911_Fire_Single_M', FirstPersonCue=AkEvent'WW_WEP_1911.Play_WEP_SA_1911_Fire_Single_S')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_C3000_SND.C3000_fire_Cue', FirstPersonCue=SoundCue'WEP_C3000_SND.C3000_fire_Cue')
	WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_C3000_SND.C3000_fire_Cue', FirstPersonCue=SoundCue'WEP_C3000_SND.C3000_fire_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_1911.Play_WEP_SA_1911_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_1911.Play_WEP_SA_1911_Handling_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=false
	// bLoopingFireSnd(DEFAULT_FIREMODE)=true

	// Attachments
	bHasIronSights=true
	bHasFlashlight=true

	// Inventory
	InventorySize=4
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_C3000_MAT.UI_WeaponSelect_C3000_Dual'
	bIsBackupWeapon=false
	AssociatedPerkClasses(0)=class'KFPerk_Survivalist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DTest' // Loot beam fx (no offset)

	BonesToLockOnEmpty=(RW_Bolt, RW_Bullets1)
    BonesToLockOnEmpty_L=(LW_Bolt, LW_Bullets1)

    bHasFireLastAnims=true
}