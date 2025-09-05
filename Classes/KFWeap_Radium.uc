class KFWeap_Radium extends KFWeap_ScopedBase;

var transient KFParticleSystemComponent ParticlePSC;
var const ParticleSystem ParticleFXTemplate;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

var float LastFireInterval;

/*
const MAX_LOCKED_TARGETS = 8;
// Constains all currently locked-on targets
var protected array<Pawn> LockedTargets;
// The last time a target was acquired
var protected float LastTargetLockTime;
// The last time a target validation check was performed
var protected float LastTargetValidationCheckTime;
// How much time after a lock on occurs before another is allowed
var const float TimeBetweenLockOns;
// How much time should pass between target validation checks
var const float TargetValidationCheckInterval;
// Minimum distance a target can be from the crosshair to be considered for lock on
var const float MinTargetDistFromCrosshairSQ;
// Dot product FOV that targets need to stay within to maintain a target lock
var const float MaxLockMaintainFOVDotThreshold;

// Sound Effects to play when Locking
var AkBaseSoundObject LockAcquiredSoundFirstPerson;
var AkBaseSoundObject LockLostSoundFirstPerson;

// Icon textures for lock on drawing
var const Texture2D LockedOnIcon;
var LinearColor LockedIconColor;

const SecondaryFireAnim = 'Shoot_Iron';
const SecondaryFireIronAnim = 'Shoot_Iron';

var transient KFMuzzleFlash SecondaryMuzzleFlash;
var() KFMuzzleFlash SecondaryMuzzleFlashTemplate;

var (Positioning) vector SecondaryFireOffset;

// How many Alt ammo to recharge per second
var float AltFullRechargeSeconds;
var transient float AltRechargePerSecond;
var transient float AltIncrement;
var repnotify byte AltAmmo;
*/

/*
replication
{
	if (bNetDirty && Role == ROLE_Authority)
		AltAmmo;
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

// simulated event Tick( FLOAT DeltaTime )
// {
//     if( AmmoCount[ALTFIRE_FIREMODE] < MagazineCapacity[ALTFIRE_FIREMODE] )
// 	{
//         RechargeAlt(DeltaTime);
// 	}

// 	Super.Tick(DeltaTime);
// }

// Alt doesn't count as ammo for purposes of inventory management (e.g. switching) 
simulated function bool HasAnyAmmo()
{
	return HasSpareAmmo() || HasAmmo(DEFAULT_FIREMODE);
}

simulated function bool ShouldAutoReload(byte FireModeNum)
{
	if (FireModeNum == ALTFIRE_FIREMODE)
		return false;
	
	return super.ShouldAutoReload(FireModeNum);
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

// Instead of a toggle, immediately fire alternate fire
simulated function AltFireMode()
{
	// LocalPlayer Only
	if ( !Instigator.IsLocallyControlled()  )
	{
		return;
	}

	if(LockedTargets.Length > 0)
	{
		StartFire(ALTFIRE_FIREMODE);
	}	
	else
	{
		StartFire(DEFAULT_FIREMODE);
	}

    // LockedTargets.Length = 0;
}

// We need to update our locked targets every frame and make sure they're within view and not dead
simulated event Tick( float DeltaTime )
{
	local Pawn RecentlyLocked, StaticLockedTargets[8];
	local bool bUpdateServerTargets;
	local int i;

	super.Tick( DeltaTime );

    if( AmmoCount[ALTFIRE_FIREMODE] < MagazineCapacity[ALTFIRE_FIREMODE] )
	{
        RechargeAlt(DeltaTime);
	}
	
    if( Instigator != none && Instigator.IsLocallyControlled() ) //bUseAltFireMode
    {
		if( `TimeSince(LastTargetLockTime) > TimeBetweenLockOns
			&& LockedTargets.Length < AmmoCount[GetAmmoType(1)]
			&& LockedTargets.Length < MAX_LOCKED_TARGETS)
		{
	        bUpdateServerTargets = FindTargets( RecentlyLocked );
	    }

		if( LockedTargets.Length > 0 )
		{
			bUpdateServerTargets = bUpdateServerTargets || ValidateTargets( RecentlyLocked );
		}

		// If we are a client, synchronize our targets with the server
		if( bUpdateServerTargets && Role < ROLE_Authority )
		{
			for( i = 0; i < MAX_LOCKED_TARGETS; ++i )
			{
				if( i < LockedTargets.Length )
				{
					StaticLockedTargets[i] = LockedTargets[i];
				}
				else
				{
					StaticLockedTargets[i] = none;
				}
			}

			ServerSyncLockedTargets( StaticLockedTargets );
		}
    }
}

// Given an potential target TA determine if we can lock on to it. By default only allow locking on to pawns.
simulated function bool CanLockOnTo(Actor TA)
{
	Local KFPawn PawnTarget;

	PawnTarget = KFPawn(TA);

	// Make sure the pawn is legit, isn't dead, and isn't already at full health
	if ((TA == None) || !TA.bProjTarget || TA.bDeleteMe || (PawnTarget == None) ||
		(TA == Instigator) || (PawnTarget.Health <= 0) || 
		!HasAmmo(ALTFIRE_FIREMODE))
	{
		return false;
	}

	// Make sure and only lock onto players on the same team
	return !WorldInfo.GRI.OnSameTeam(Instigator, TA);
}

// Finds a new lock on target, adds it to the target array and returns TRUE if the array was updated
simulated function bool FindTargets( out Pawn RecentlyLocked )
{
	local Pawn P, BestTargetLock;
	local byte TeamNum;
	local vector AimStart, AimDir, TargetLoc, Projection, DirToPawn, LinePoint;
	local Actor HitActor;
	local float PointDistSQ, Score, BestScore, TargetSizeSQ;

	TeamNum = Instigator.GetTeamNum();
	AimStart = GetSafeStartTraceLocation();
	AimDir = vector( GetAdjustedAim(AimStart) );
	BestScore = 0.f;

    //Don't add targets if we're already burst firing
    if (IsInState('WeaponBurstFiring'))
    {
        return false;
    }

	foreach WorldInfo.AllPawns( class'Pawn', P )
	{
		if (!CanLockOnTo(P))
		{
			continue;
		}
		// Want alive pawns and ones we already don't have locked
		if( P != none && P.IsAliveAndWell() && P.GetTeamNum() != TeamNum && LockedTargets.Find(P) == INDEX_NONE )
		{
			TargetLoc = GetLockedTargetLoc( P );
			Projection = TargetLoc - AimStart;
			DirToPawn = Normal( Projection );

			// Filter out pawns too far from center
			if( AimDir dot DirToPawn < 0.5f )
			{
				continue;
			}

			// Check to make sure target isn't too far from center
            PointDistToLine( TargetLoc, AimDir, AimStart, LinePoint );
            PointDistSQ = VSizeSQ( LinePoint - P.Location );

			TargetSizeSQ = P.GetCollisionRadius() * 2.f;
			TargetSizeSQ *= TargetSizeSQ;

            if( PointDistSQ > (TargetSizeSQ + MinTargetDistFromCrosshairSQ) )
            {
            	continue;
            }

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
		LastTargetLockTime = WorldInfo.TimeSeconds;
		LockedTargets.AddItem( BestTargetLock );
		RecentlyLocked = BestTargetLock;

		// Plays sound/FX when locking on to a new target
		PlayTargetLockOnEffects();

		return true;
	}

	RecentlyLocked = none;

	return false;
}

// Checks to ensure all of our current locked targets are valid
simulated function bool ValidateTargets( optional Pawn RecentlyLocked )
{
	local int i;
	local bool bShouldRemoveTarget, bAlteredTargets;
	local vector AimStart, AimDir, TargetLoc;
	local Actor HitActor;

	if( `TimeSince(LastTargetValidationCheckTime) < TargetValidationCheckInterval )
	{
		return false;
	}

	LastTargetValidationCheckTime = WorldInfo.TimeSeconds;

	AimStart = GetSafeStartTraceLocation();
	AimDir = vector( GetAdjustedAim(AimStart) );

	bAlteredTargets = false;
	for( i = 0; i < LockedTargets.Length; ++i )
	{
		// For speed don't bother checking a target we just locked
		if( RecentlyLocked != none && RecentlyLocked == LockedTargets[i] )
		{
			continue;
		}

		bShouldRemoveTarget = false;

		if( LockedTargets[i] == none
			|| !LockedTargets[i].IsAliveAndWell() )
		{
			bShouldRemoveTarget = true;
		}
		else
		{
			TargetLoc = GetLockedTargetLoc( LockedTargets[i] );
			if( AimDir dot Normal(LockedTargets[i].Location - AimStart) >= MaxLockMaintainFOVDotThreshold )
			{
				HitActor = class'KFAIController'.static.ActorBlockTest( self, TargetLoc, AimStart,, true, true );
				if( HitActor != none && HitActor != LockedTargets[i] )
				{
					bShouldRemoveTarget = true;
				}
			}
			else
			{
				bShouldRemoveTarget = true;
			}
		}

		// A target was invalidated, remove it from the list
		if( bShouldRemoveTarget )
		{
			LockedTargets.Remove( i, 1 );
			--i;
			bAlteredTargets = true;
			continue;
		}
	}

	// Plays sound/FX when losing a target lock, but only if we didn't play a lock on this frame
	if( bAlteredTargets && RecentlyLocked == none )
	{
		PlayTargetLostEffects();
	}

	return bAlteredTargets;
}

// Synchronizes our locked targets with the server
reliable server function ServerSyncLockedTargets( Pawn TargetPawns[MAX_LOCKED_TARGETS] )
{
	local int i;

    LockedTargets.Length = 0;
	for( i = 0; i < MAX_LOCKED_TARGETS; ++i )
	{
        if (TargetPawns[i] != none)
        {
            LockedTargets.AddItem(TargetPawns[i]);
        }		
	}
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

// Play FX or sounds when locking on to a new target
simulated function PlayTargetLockOnEffects()
{
	if( Instigator != none && Instigator.IsHumanControlled() )
	{
		PlaySoundBase( LockAcquiredSoundFirstPerson, true );
	}
}

// Play FX or sounds when losing a target lock
simulated function PlayTargetLostEffects()
{
	if( Instigator != none && Instigator.IsHumanControlled() )
	{
		PlaySoundBase( LockLostSoundFirstPerson, true );
	}
}

// Spawn projectile is called once for each rocket fired. In burst mode it will cycle through targets until it runs out
simulated function KFProjectile SpawnProjectile( class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir )
{
	local KFProj_Rocket_Battlecruiser RocketProj;

    if( CurrentFireMode == GRENADE_FIREMODE )
    {
        return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
    }

    // We need to set our target if we are firing from a locked on position
    if( CurrentFireMode == ALTFIRE_FIREMODE )
    {
		// We'll aim our rocket at a target here otherwise we will spawn a dumbfire rocket at the end of the function
		if( LockedTargets.Length > 0 )
		{
			// Spawn our projectile and set its target
			RocketProj = KFProj_Rocket_Battlecruiser( super.SpawnProjectile(KFProjClass, RealStartLoc, AimDir) );
			if( RocketProj != none  )
			{
                //Seek to new target, then remove from list. Always use first target in the list for new fire.
				RocketProj.SetLockedTarget( KFPawn(LockedTargets[0]) );
                LockedTargets.Remove(0, 1);

                return RocketProj;
			}
		}

		return None;
    }

   	return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
}

// Handle drawing our custom lock on HUD
simulated function DrawHUD( HUD H, Canvas C )
{
    local int i;

    if( LockedTargets.Length == 0 )
    {
       return;
    }

    // Draw target locked icons
	C.EnableStencilTest( true );
    for( i = 0; i < LockedTargets.Length; ++i )
    {
        if( LockedTargets[i] != none )
        {
            DrawTargetingIcon( C, i );
        }
    }
	C.EnableStencilTest( false );
}

// Draws a targeting icon for each one of our locked targets
simulated function DrawTargetingIcon( Canvas Canvas, int Index )
{
    local vector WorldPos, ScreenPos;
    local float IconSize, IconScale;

    // Project world pos to canvas
    WorldPos = GetLockedTargetLoc( LockedTargets[Index] );
    ScreenPos = Canvas.Project( WorldPos );//WorldToCanvas(Canvas, WorldPos);

    // calculate scale based on resolution and distance
    IconScale = fMin( float(Canvas.SizeX) / 1024.f, 1.f );
	// Scale down up to 40 meters away, with a clamp at 20% size
    IconScale *= fClamp( 1.f - VSize(WorldPos - Instigator.Location) / 4000.f, 0.2f, 1.f );
 
    // Apply size scale
    IconSize = 200.f * IconScale;
    ScreenPos.X -= IconSize / 2.f;
    ScreenPos.Y -= IconSize / 2.f;

    // Off-screen check
    if( ScreenPos.X < 0 || ScreenPos.X > Canvas.SizeX || ScreenPos.Y < 0 || ScreenPos.Y > Canvas.SizeY )
    {
        return;
    }

    Canvas.SetPos( ScreenPos.X, ScreenPos.Y );

	// Draw the icon
    Canvas.DrawTile( LockedOnIcon, IconSize, IconSize, 0, 0, LockedOnIcon.SizeX, LockedOnIcon.SizeY, LockedIconColor );
}
*/

/*
simulated state WeaponSingleFiring
{
	simulated function BeginState( Name PrevStateName )
	{
		LockedTargets.Length = 0;

		super.BeginState( PrevStateName );
	}
}
*/

/*
simulated state WeaponBurstFiring
{
	// simulated event BeginState(Name PreviousStateName)
	// {
	// 	super.BeginState(PreviousStateName);
	// }

	simulated function int GetBurstAmount()
	{
		// Clamp our bursts to either the number of targets or how much ammo we have remaining
		return Clamp( LockedTargets.Length, 1, AmmoCount[GetAmmoType(1)] ); //CurrentFireMode
	}

    simulated function bool ShouldRefire()
    {
        return LockedTargets.Length > 0;
    }

    simulated function FireAmmunition()
    {
        super.FireAmmunition();
        if (Role < ROLE_Authority)
        {
            LockedTargets.Remove(0, 1);
        }
    }

	simulated event vector GetMuzzleLoc()
	{
		local vector MuzzleLocation;

		// swap fireoffset temporarily
		FireOffset = SecondaryFireOffset;
		MuzzleLocation = Global.GetMuzzleLoc();
		FireOffset = default.FireOffset;

		return MuzzleLocation;
	}

	simulated function name GetWeaponFireAnim(byte FireModeNum)
	{
		return bUsingSights ? SecondaryFireIronAnim : SecondaryFireAnim;
	}

	simulated event EndState( Name NextStateName )
	{
		LockedTargets.Length = 0;

		super.EndState( NextStateName );
	}
}

// Fires a projectile
simulated function CustomFire()
{
	ProjectileFireCustom();
}

simulated function Projectile ProjectileFireCustom()
{
	local vector StartTrace, RealStartLoc, AimDir;
	local rotator AimRot;
	local class<KFProjectile> MyProjectileClass;

	// tell remote clients that we fired, to trigger effects
	if ( ShouldIncrementFlashCountOnFire() )
	{
		IncrementFlashCount();
	}

    MyProjectileClass = GetKFProjectileClass();

	if( Role == ROLE_Authority || (MyProjectileClass.default.bUseClientSideHitDetection
        && MyProjectileClass.default.bNoReplicationToInstigator && Instigator != none
        && Instigator.IsLocallyControlled()) )
	{
		// This is where we would start an instant trace. (what CalcWeaponFire uses)
		MySkelMesh.GetSocketWorldLocationAndRotation( 'MuzzleFlashAlt', StartTrace, AimRot);
		GetMuzzleLocAndRot(StartTrace, AimRot);

		// AimDir = Vector(Owner.Rotation);
		// AimDir = Vector(AimRot);
		AimDir = Vect(0,0,1);

		// this is the location where the projectile is spawned.
		RealStartLoc = StartTrace;

		return SpawnAllProjectiles(MyProjectileClass, RealStartLoc, AimDir);
	}

	return None;
}

simulated function GetMuzzleLocAndRot(out vector MuzzleLoc, out rotator MuzzleRot)
{
	if (KFSkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation('MuzzleFlashAlt', MuzzleLoc, MuzzleRot) == false)
	{
		`Log("Alt muzzleFlash not found!");
	}

	// To World Coordinates. (Rotation should be 0 so no taken into account)
	// MuzzleLoc = Location + QuatRotateVector(QuatFromRotator(Rotation), MuzzleLoc);
}

// Don't allow secondary fire to make a primary fire shell particle come out of the gun.
simulated function CauseMuzzleFlash(byte FireModeNum)
{
	if(FireModeNum == ALTFIRE_FIREMODE)
	{
		if (SecondaryMuzzleFlash == None)
		{
			AttachMuzzleFlash();
		}

		if (SecondaryMuzzleFlash != none)
		{
			SecondaryMuzzleFlash.CauseMuzzleFlash(FireModeNum);
		}

		if (SecondaryMuzzleFlash.bAutoActivateShellEject)
		{
			SecondaryMuzzleFlash.CauseShellEject();
			SetShellEjectsToForeground();
		}
	}
	else
	{
		Super.CauseMuzzleFlash(FireModeNum);
	}
}

simulated function AttachMuzzleFlash()
{
	super.AttachMuzzleFlash();

	if ( MySkelMesh != none )
	{
		if (SecondaryMuzzleFlashTemplate != None)
		{
			SecondaryMuzzleFlash = new(self) Class'KFMuzzleFlash'(SecondaryMuzzleFlashTemplate);
			SecondaryMuzzleFlash.AttachMuzzleFlash(MySkelMesh, 'MuzzleFlashAlt');
		}
	}
}
*/

//Overriden to use instant hit vfx. Basically, calculate the hit location so vfx can play
simulated function Projectile ProjectileFire()
{
	local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
	local ImpactInfo	TestImpact;
	local vector DirA, DirB;
	local Quat Q;
	local class<KFProjectile> MyProjectileClass;

    MyProjectileClass = GetKFProjectileClass();

	// This is where we would start an instant trace. (what CalcWeaponFire uses)
	StartTrace = GetSafeStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));

	// this is the location where the projectile is spawned.
	RealStartLoc = GetPhysicalFireStartLoc(AimDir);

	// if projectile is spawned at different location of crosshair,
	// then simulate an instant trace where crosshair is aiming at, Get hit info.
	EndTrace = StartTrace + AimDir * GetTraceRange();
	TestImpact = CalcWeaponFire( StartTrace, EndTrace );

	// Set flash location to trigger client side effects.  Bypass Weapon.SetFlashLocation since
	// that function is not marked as simulated and we want instant client feedback.
	// ProjectileFire/IncrementFlashCount has the right idea:
	//	1) Call IncrementFlashCount on Server & Local
	//	2) Replicate FlashCount if ( !bNetOwner )
	//	3) Call WeaponFired() once on local player
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
			// Store the original aim direction without correction
            DirB = AimDir;

			// Then we realign projectile aim direction to match where the crosshair did hit.
			AimDir = Normal(TestImpact.HitLocation - RealStartLoc);

            // Store the desired corrected aim direction
    		DirA = AimDir;

    		// Clamp the maximum aim adjustment for the AimDir so you don't get wierd
    		// cases where the projectiles velocity is going WAY off of where you
    		// are aiming. This can happen if you are really close to what you are
    		// shooting - Ramm
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

simulated state WeaponEquipping
{
	simulated function BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		ActivatePSC(ParticlePSC, ParticleFXTemplate, 'ParticleFX');
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

auto simulated state Inactive
{
	simulated function BeginState(name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);

		if (ParticlePSC != none)
		{
			ParticlePSC.DeactivateSystem();
		}
	}
}

simulated function float GetFireInterval(byte FireModeNum)
{
	if (FireModeNum == DEFAULT_FIREMODE && AmmoCount[FireModeNum] == 0)
	{
		return LastFireInterval;
	}

	return super.GetFireInterval(FireModeNum);
}

//Reduce the damage received and apply it to the shield
function AdjustDamage(out int InDamage, class<DamageType> DamageType, Actor DamageCauser)
{
	super.AdjustDamage(InDamage, DamageType, DamageCauser);

	if (Instigator != none && DamageCauser.Instigator == Instigator)
	{
		InDamage *= SelfDamageReductionValue;
	}
}

defaultproperties
{
	// Inventory / Grouping
	InventorySize=10 //12
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Radium_MAT.UI_WeaponSelect_Radium'
   	//AssociatedPerkClasses(0)=class'KFPerk_Survivalist'
	AssociatedPerkClasses(0)=none

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DTest' // Loot beam fx (no offset)

    // FOV
    MeshFOV=60 //70
	MeshIronSightFOV=27
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=15.0,Y=11.5,Z=-4)
	IronSightPosition=(X=0.0,Y=0,Z=0)

	// Content
	PackageKey="Radium"
	FirstPersonMeshName="WEP_Radium_MESH.Wep_1stP_Radium_Rig"
	FirstPersonAnimSetNames(0)="WEP_Radium_ARCH.Wep_1stP_Radium_Anim"
	PickupMeshName="WEP_Radium_MESH.Wep_Radium_Pickup"
	AttachmentArchetypeName="WEP_Radium_ARCH.WEP_Radium_3P"
	MuzzleFlashTemplateName="WEP_Radium_ARCH.Wep_Radium_MuzzleFlash"
	// SecondaryMuzzleFlashTemplate=KFMuzzleFlash'WEP_M99_ARCH.Wep_M99_MuzzleFlash'

 	// 2D scene capture
	Begin Object Name=SceneCapture2DComponent0
	   TextureTarget=TextureRenderTarget2D'Wep_Mat_Lib.WEP_ScopeLense_Target'
	   FieldOfView=12.5 // "2.0X" = 25.0(our real world FOV determinant)/2.0
	End Object

    ScopedSensitivityMod=12.0 //8.0
	ScopeLenseMICTemplate=MaterialInstanceConstant'WEP_1P_M99_MAT.WEP_1P_M99_Scope_MAT'

	// Ammo
	MagazineCapacity[0]=1
	SpareAmmoCapacity[0]=20 //30
	InitialSpareMags[0]=6
	AmmoPickupScale[0]=2.0
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// AI warning system
	bWarnAIWhenAiming=true
	AimWarningDelay=(X=0.4f, Y=0.8f)
	AimWarningCooldown=0.0f

	// Recoil
	maxRecoilPitch=700 //1200
	minRecoilPitch=650 //775
	maxRecoilYaw=500 //800
	minRecoilYaw=-500 //-500
	RecoilRate=0.085
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=150
	RecoilISMinYawLimit=65385
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	RecoilViewRotationScale=0.8
	FallingRecoilModifier=1.0
	HippedRecoilModifier=0.5

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletSingle'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile //EWFT_InstantHit
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bolt_Radium'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Radium'
	InstantHitDamage(DEFAULT_FIREMODE)=70
	FireInterval(DEFAULT_FIREMODE)=0.8 // 75 RPM //0.2
	PenetrationPower(DEFAULT_FIREMODE)=5.0
	Spread(DEFAULT_FIREMODE)=0.006
	FireOffset=(X=30,Y=3.0,Z=-2.5)
	ForceReloadTimeOnEmpty=0.4 //0.5
	LastFireInterval=0.3

	SelfDamageReductionValue=0.16f; //0.18

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

/*
	// ALTFIRE_FIREMODE
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'UI_FireModes_TEX.UI_FireModeSelect_Rocket'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponBurstFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Custom //EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Rocket_Battlecruiser'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_Seeker6Impact'
	InstantHitDamage(ALTFIRE_FIREMODE)=125
	FireInterval(ALTFIRE_FIREMODE)=+0.1 // 600 RPM
	PenetrationPower(ALTFIRE_FIREMODE)=0
	Spread(ALTFIRE_FIREMODE)=1.0
	SecondaryFireOffset=(X=0.f,Y=0,Z=1.f)

	AltAmmo=8
	MagazineCapacity[1]=8
	AmmoCost(ALTFIRE_FIREMODE)=1
	AltFullRechargeSeconds=15
	bCanRefillSecondaryAmmo=false;
    SecondaryAmmoTexture=Texture2D'UI_FireModes_TEX.UI_FireModeSelect_Rocket'
	// bAllowClientAmmoTracking=true

	// Target Locking
	MinTargetDistFromCrosshairSQ=2500.0f // 0.5 meters
	TimeBetweenLockOns=0.06f
	TargetValidationCheckInterval=0.1f
	MaxLockMaintainFOVDotThreshold=0.36f

	// LockOn Visuals
    LockedOnIcon=Texture2D'DTest_MAT.Wep_1stP_Cube_Thicc_45_Target_T'
    LockedIconColor=(R=1.f, G=0.f, B=0.f, A=0.5f)

    // Lock On/Lost Sounds
	LockAcquiredSoundFirstPerson=AkEvent'WW_WEP_SA_Railgun.Play_Railgun_Scope_Locked'
	LockLostSoundFirstPerson=AkEvent'WW_WEP_SA_Railgun.Play_Railgun_Scope_Lost'
*/
	
	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_M99'
	InstantHitDamage(BASH_FIREMODE)=30

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SealSqueal.Play_WEP_SealSqueal_Shoot_3P', FirstPersonCue=AkEvent'WW_WEP_SealSqueal.Play_WEP_SealSqueal_Shoot_1P')
	// WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_M99.Play_WEP_M99_DryFire'
	// WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_M99.Play_WEP_M99_DryFire'

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// Create all these particle system components off the bat so that the tick group can be set
	// fixes issue where the particle systems get offset during animations
	Begin Object Class=KFParticleSystemComponent Name=BasePSC0
		TickGroup=TG_PostUpdateWork
	End Object
	ParticlePSC=BasePSC0
	ParticleFXTemplate=ParticleSystem'DTest_EMIT.FX_Radium_ParticleFX'

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil'
}