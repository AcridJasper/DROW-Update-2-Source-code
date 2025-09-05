class KFWeap_Nihilanth extends KFWeapon;

// Shoot animation to play when shooting secondary fire
var(Animations) const editconst	name	FireHeavyAnim;
// Shoot animation to play when shooting secondary fire last shot
var(Animations) const editconst	name	FireLastHeavyAnim;
// Shoot animation to play when shooting secondary fire last shot when aiming
var(Animations) const editconst	name	FireLastHeavySightedAnim;

var const float MaxTargetAngle;
var transient float CosTargetAngle;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	CosTargetAngle = Cos(MaxTargetAngle * DegToRad);
}

// Given an potential target TA determine if we can lock on to it.  By default only allow locking on to pawns.
simulated function bool CanLockOnTo(Actor TA)
{
	Local KFPawn PawnTarget;

	PawnTarget = KFPawn(TA);

	// Make sure the pawn is legit, isn't dead, and isn't already at full health
	if ((TA == None) || !TA.bProjTarget || TA.bDeleteMe || (PawnTarget == None) ||
		(TA == Instigator) || (PawnTarget.Health <= 0) || 
		!HasAmmo(DEFAULT_FIREMODE))
	{
		return false;
	}

	// Make sure and only lock onto players on the same team
	return !WorldInfo.GRI.OnSameTeam(Instigator, TA);
}

// Finds a new lock on target
simulated function bool FindTarget( out KFPawn RecentlyLocked )
{
	local KFPawn P, BestTargetLock;
	local byte TeamNum;
	local vector AimStart, AimDir, TargetLoc, Projection, DirToPawn, LinePoint;
	local Actor HitActor;
	local float PointDistSQ, Score, BestScore, TargetSizeSQ;

	TeamNum   = Instigator.GetTeamNum();
	AimStart  = GetSafeStartTraceLocation();
	AimDir    = vector( GetAdjustedAim(AimStart) );
	BestScore = 0.f;

	foreach WorldInfo.AllPawns( class'KFPawn', P )
	{
		if (!CanLockOnTo(P))
		{
			continue;
		}
		// Want alive pawns and ones we already don't have locked
		if( P != none && P.IsAliveAndWell() && P.GetTeamNum() != TeamNum )
		{
			TargetLoc  = GetLockedTargetLoc( P );
			Projection = TargetLoc - AimStart;
			DirToPawn  = Normal( Projection );

			// Filter out pawns too far from center
			
			if( AimDir dot DirToPawn < CosTargetAngle )
			{
				continue;
			}

			// Check to make sure target isn't too far from center
            		PointDistToLine( TargetLoc, AimDir, AimStart, LinePoint );
            		PointDistSQ = VSizeSQ( LinePoint - P.Location );

			TargetSizeSQ = P.GetCollisionRadius() * 2.f;
			TargetSizeSQ *= TargetSizeSQ;

            // Make sure it's not obstructed
            HitActor = class'KFAIController'.static.ActorBlockTest(self, TargetLoc, AimStart,, true, true);
            if( HitActor != none && HitActor != P )
            {
            	continue;
            }

            // Distance from target has much more impact on target selection score
            Score = VSizeSQ( Projection ) + PointDistSQ;
            if( BestScore == 0.f || Score < BestScore )
            {
            	BestTargetLock = P;
            	BestScore = Score;
            }
	}
	}

	if( BestTargetLock != none )
	{
		RecentlyLocked = BestTargetLock;

		return true;
	}

	RecentlyLocked = none;

	return false;
}

// Adjusts our destination target impact location
static simulated function vector GetLockedTargetLoc( Pawn P )
{
	// Go for the chest, but just in case we don't have something with a chest bone we'll use collision and eyeheight settings
	if( P.Mesh.SkeletalMesh != none && P.Mesh.bAnimTreeInitialised )
	{
		if( P.Mesh.MatchRefBone('Spine2') != INDEX_NONE )
		{
			return P.Mesh.GetBoneLocation( 'Spine2' );
		}
		else if( P.Mesh.MatchRefBone('Spine1') != INDEX_NONE )
		{
			return P.Mesh.GetBoneLocation( 'Spine1' );
		}
		
		return P.Mesh.GetPosition() + ((P.CylinderComponent.CollisionHeight + (P.BaseEyeHeight  * 0.5f)) * vect(0,0,1)) ;
	}

	// General chest area, fallback
	return P.Location + ( vect(0,0,1) * P.BaseEyeHeight * 0.75f );	
}

// Spawn projectile is called once for each rocket fired. In burst mode it will cycle through targets until it runs out */
simulated function KFProjectile SpawnProjectile( class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir )
{
	local KFProj_Orb_ElectricBolt BoltProj;
	local KFProj_Orb_Nihilanth PortalProj;
	local KFPawn TargetPawn;

    	if ( CurrentFireMode == DEFAULT_FIREMODE )
	{
		FindTarget(TargetPawn);

		BoltProj = KFProj_Orb_ElectricBolt( super.SpawnProjectile( class<KFProjectile>(WeaponProjectiles[CurrentFireMode]) , RealStartLoc, AimDir) );

		if( BoltProj != none )
		{
			// We'll aim our rocket at a target here otherwise we will spawn a dumbfire rocket at the end of the function
			if ( TargetPawn != none)
			{
				//Seek to new target, then remove it
				BoltProj.SetLockedTarget( TargetPawn );
			}
		}

		return BoltProj;
	}

    	if ( CurrentFireMode == ALTFIRE_FIREMODE )
	{
		FindTarget(TargetPawn);

		PortalProj = KFProj_Orb_Nihilanth( super.SpawnProjectile( class<KFProjectile>(WeaponProjectiles[CurrentFireMode]) , RealStartLoc, AimDir) );

		if( PortalProj != none )
		{
			// We'll aim our rocket at a target here otherwise we will spawn a dumbfire rocket at the end of the function
			if ( TargetPawn != none)
			{
				//Seek to new target, then remove it
				PortalProj.SetLockedTarget( TargetPawn );
			}
		}

		return PortalProj;
	}

   	return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
}

// Handle one-hand fire anims
simulated function name GetWeaponFireAnim(byte FireModeNum)
{
	local bool bPlayFireLast;

    	bPlayFireLast = ShouldPlayFireLast(FireModeNum);

	if ( bUsingSights )
	{
		if( bPlayFireLast )
        {
        	if ( FireModeNum == ALTFIRE_FIREMODE )
        	{
                return FireLastHeavySightedAnim;
        	}
        	else
        	{
                return FireLastSightedAnim;
            }
        }
        else
        {
            return FireSightedAnims[FireModeNum];
        }

	}
	else
	{
		if( bPlayFireLast )
        {
        	if ( FireModeNum == ALTFIRE_FIREMODE )
        	{
                return FireLastHeavyAnim;
        	}
        	else
        	{
                return FireLastAnim;
            }
        }
        else
        {
        	if ( FireModeNum == ALTFIRE_FIREMODE )
        	{
                return FireHeavyAnim;
        	}
        	else
        	{
                return FireAnim;
            }
        }
	}
}

// Instead of a toggle, just immediately fire alternate fire.
simulated function AltFireMode()
{
	// LocalPlayer Only
	if ( !Instigator.IsLocallyControlled()  )
	{
		return;
	}

	StartFire(ALTFIRE_FIREMODE);
}

// Disable auto-reload for alt-fire
simulated function bool ShouldAutoReload(byte FireModeNum)
{
	local bool bRequestReload;

    bRequestReload = Super.ShouldAutoReload(FireModeNum);

    // Must be completely empty for auto-reload or auto-switch
    if ( FireModeNum == ALTFIRE_FIREMODE && AmmoCount[0] > 0 )
    {
   		bPendingAutoSwitchOnDryFire = false;
   		return false;
    }

    return bRequestReload;
}

// Allow reloads for primary weapon to be interupted by firing secondary weapon
simulated function bool CanOverrideMagReload(byte FireModeNum)
{
	if(FireModeNum == ALTFIRE_FIREMODE)
	{
		return true;
	}

	return Super.CanOverrideMagReload(FireModeNum);
}

defaultproperties
{
    	// Inventory
	InventorySize=8 //9
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Nihilanth_MAT.UI_WeaponSelect_Nihilanth'
	AssociatedPerkClasses(0)=class'KFPerk_Survivalist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DTest' // Loot beam fx (no offset)

    	// FOV
	MeshIronSightFOV=52
    	PlayerIronSightFOV=80

	// Zooming/Position
	IronSightPosition=(X=3,Y=-0.032,Z=-0.03)
	PlayerViewOffset=(X=5.0,Y=9,Z=-3)

	// Content
	PackageKey="Nihilanth"
	FirstPersonMeshName="WEP_Nihilanth_MESH.Wep_1stP_Nihilanth_Rig"
	FirstPersonAnimSetNames(0)="WEP_Nihilanth_ARCH.WEP_1p_Nihilanth_ANIM"
	PickupMeshName="WEP_Nihilanth_MESH.Wep_Nihilanth_Pickup"
	AttachmentArchetypeName="WEP_Nihilanth_ARCH.Wep_Nihilanth_3P"
	MuzzleFlashTemplateName="WEP_Nihilanth_ARCH.Wep_Nihilanth_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=100 //80
	SpareAmmoCapacity[0]=400
	InitialSpareMags[0]=1
	AmmoPickupScale[0]=1.0
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=90
	minRecoilPitch=80
	maxRecoilYaw=90
	minRecoilYaw=-90
	RecoilRate=0.085
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=75
	RecoilISMinYawLimit=65460
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	RecoilViewRotationScale=0.25
	IronSightMeshFOVCompensationScale=1.5
    	HippedRecoilModifier=1.5

	// DEFAULT_FIREMODE (shoots tiny yellow electric balls)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'DTest_MAT.UI_FireModeSelect_OrbD'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Orb_ElectricBolt'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Explosive_ElectricBolt'
	FireInterval(DEFAULT_FIREMODE)=+0.1 // 600 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=30 //25
    	PenetrationPower(DEFAULT_FIREMODE)=0
	Spread(DEFAULT_FIREMODE)=0.2 //0.025
	FireOffset=(X=30,Y=4.5,Z=-5)

	MaxTargetAngle=20 // 30 Angle at which bullet will lock-on
	
	// ALT_FIREMODE (shoots "massive" green portal)
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'DTest_MAT.UI_FireModeSelect_OrbD'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Orb_Nihilanth'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Explosive_ElectricBolt'
	FireInterval(ALTFIRE_FIREMODE)=1.33 //45 RPM
	InstantHitDamage(ALTFIRE_FIREMODE)=170 //550
    	PenetrationPower(ALTFIRE_FIREMODE)=40.0
	Spread(ALTFIRE_FIREMODE)=0 //0.025
	AmmoCost(ALTFIRE_FIREMODE)=50

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Flamethrower'
	InstantHitDamage(BASH_FIREMODE)=30

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_ArcGenerator.Play_HRG_ArcGenerator_Fire_3P_Loop', FirstPersonCue=AkEvent'WW_WEP_HRG_ArcGenerator.Play_HRG_ArcGenerator_Fire_1P_Loop')
	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_ArcGenerator.Play_HRG_ArcGenerator_AltFire_3P', FirstPersonCue=AkEvent'WW_WEP_HRG_ArcGenerator.Play_HRG_ArcGenerator_AltFire_1P')
    	WeaponFireLoopEndSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_ArcGenerator.Play_HRG_ArcGenerator_Fire_3P_LoopEnd', FirstPersonCue=AkEvent'WW_WEP_HRG_ArcGenerator.Play_HRG_ArcGenerator_Fire_1P_LoopEnd')

	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_Microwave_Gun.Play_SA_MicrowaveGun_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_Microwave_Gun.Play_SA_MicrowaveGun_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=true
	bLoopingFireSnd(DEFAULT_FIREMODE)=true
	SingleFireSoundIndex=FIREMODE_NONE

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
	
	// Animation
	bHasFireLastAnims=true
	FireSightedAnims[0]=Shoot
	FireSightedAnims[1]=Shoot_Heavy_Iron
	FireLastHeavySightedAnim=Shoot_Heavy_Iron_Last
    	FireHeavyAnim=Shoot_Heavy
    	FireLastHeavyAnim=Shoot_Heavy_Last

 	BonesToLockOnEmpty=(RW_Handle1, RW_BatteryCylinder1, RW_BatteryCylinder2, RW_LeftArmSpinner, RW_RightArmSpinner, RW_LockEngager2, RW_LockEngager1)

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.2f), (Stat=EWUS_Damage1, Scale=1.0f), (Stat=EWUS_Weight, Add=1)))
}