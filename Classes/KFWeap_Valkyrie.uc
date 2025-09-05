class KFWeap_Valkyrie extends KFWeap_SMGBase;

var transient KFParticleSystemComponent ParticlePSC;
var const ParticleSystem ParticleFXTemplate;

var transient bool bLockOnActive;

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
// var const float MinTargetDistFromCrosshairSQ;
// Dot product FOV that targets need to stay within to maintain a target lock
var const float MaxLockMaintainFOVDotThreshold;

var const float MaxTargetAngle;
var transient float CosTargetAngle;

// Sound Effects to play when Locking
var AkBaseSoundObject LockAcquiredSoundFirstPerson;
var AkBaseSoundObject LockLostSoundFirstPerson;

// Icon textures for lock on drawing
var const Texture2D LockedOnIcon;
var LinearColor LockedIconColor;

const SecondaryFireAnim = 'Shoot';
const SecondaryFireIronAnim = 'Shoot_Iron';

// var transient KFMuzzleFlash SecondaryMuzzleFlash;
// var() KFMuzzleFlash SecondaryMuzzleFlashTemplate;

// var (Positioning) vector SecondaryFireOffset;

// var vector BarrelOffsetX;
// var vector BarrelOffsetZ;

var class<KFGFxWorld_MedicOptics> OpticsUIClass;
var KFGFxWorld_MedicOptics OpticsUI;

// The last updated value for our ammo - Used to know when to update our optics ammo
var byte StoredPrimaryAmmo;
var byte StoredSecondaryAmmo;

var protected const array<vector2D> PelletSpread;

// How many Alt ammo to recharge per second
var float AltFullRechargeSeconds;
var transient float AltRechargePerSecond;
var transient float AltIncrement;
var repnotify byte AltAmmo;

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

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	CosTargetAngle = Cos(MaxTargetAngle * DegToRad);
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
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	// can only fire if more equal the lenght
	// if(LockedTargets.Length >= 6)
	if(LockedTargets.Length > 0)
	{
		StartFire(ALTFIRE_FIREMODE);
	}	
	// else
	// {
		// StartFire(DEFAULT_FIREMODE);
	// }

	// if(LockedTargets.Length < 6)
	// {
    // 	LockedTargets.Length = 0;
	// }
}

// Re-enables target lock-on
simulated state WeaponEquipping
{
	simulated function BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		bLockOnActive = true;

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

// We need to update our locked targets every frame and make sure they're within view and not dead
simulated event Tick( float DeltaTime )
{
	local Pawn RecentlyLocked, StaticLockedTargets[8];
	local bool bUpdateServerTargets;
	local int i;

	super.Tick( DeltaTime );

	if (Instigator != none && Instigator.weapon == self)
	{
		UpdateOpticsUI();
	}

    if( AmmoCount[ALTFIRE_FIREMODE] < MagazineCapacity[ALTFIRE_FIREMODE] )
	{
        RechargeAlt(DeltaTime);
	}

	if( bLockOnActive )
	{
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
}

// Disables target lock-on
simulated state WeaponPuttingDown
{
	simulated function BeginState(name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);

		bLockOnActive = false;
    	LockedTargets.Length = 0;

		// if( LockedTargets.Length > 0 )
		// {
			// PlayTargetLostEffects();
		// }
	}

	// simulated function EndState(Name NextStateName)
	// {
	// 	Super.EndState(NextStateName);

	// 	bLockOnActive = false;
    // 	LockedTargets.Length = 0;

	// PlayTargetLostEffects();
	// }
}

// Given an potential target TA determine if we can lock on to it. By default only allow locking on to pawns.
simulated function bool CanLockOnTo(Actor TA)
{
	Local KFPawn PawnTarget;

	PawnTarget = KFPawn(TA);

	// Make sure the pawn is legit, isn't dead, and isn't already at full health
	if ((TA == None) || !TA.bProjTarget || TA.bDeleteMe || (PawnTarget == None) ||
		(TA == Instigator) || (PawnTarget.Health <= 0) /*||
		!HasAmmo(DEFAULT_FIREMODE)*/)
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
			// if( AimDir dot DirToPawn < 0.5f )
			// {
			// 	continue;
			// }

			if( AimDir dot DirToPawn < CosTargetAngle )
			{
				continue;
			}
			
			// Check to make sure target isn't too far from center
            PointDistToLine( TargetLoc, AimDir, AimStart, LinePoint );
            PointDistSQ = VSizeSQ( LinePoint - P.Location );

			TargetSizeSQ = P.GetCollisionRadius() * 2.f;
			TargetSizeSQ *= TargetSizeSQ;

            // if( PointDistSQ > (TargetSizeSQ + MinTargetDistFromCrosshairSQ) )
            // {
            // 	continue;
            // }

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
	local KFProj_Rocket_Valkyrie RocketProj;
	// local KFProj_Bullet_Valkyrie BulletProj;

    if( CurrentFireMode == GRENADE_FIREMODE )
    {
        return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
    }

    // We need to set our target if we are firing from a locked on position
    if( CurrentFireMode == ALTFIRE_FIREMODE && LockedTargets.Length > 0 )
    {
		// We'll aim our rocket at a target here otherwise we will spawn a dumbfire rocket at the end of the function
		if( LockedTargets.Length > 0 )
		{
			// Spawn our projectile and set its target
			RocketProj = KFProj_Rocket_Valkyrie( super.SpawnProjectile(KFProjClass, RealStartLoc, AimDir) );
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

    // if( CurrentFireMode == DEFAULT_FIREMODE )
    // {
	// 	BulletProj = KFProj_Bullet_Valkyrie( super.SpawnProjectile(KFProjClass, RealStartLoc + BarrelOffsetZ / 2.f, AimDir) );
	// 	BulletProj = KFProj_Bullet_Valkyrie( super.SpawnProjectile(KFProjClass, RealStartLoc + BarrelOffsetX / 2.f, AimDir) );
	// 	BulletProj = KFProj_Bullet_Valkyrie( super.SpawnProjectile(KFProjClass, RealStartLoc - BarrelOffsetX / 2.f, AimDir) );

	// 	if( BulletProj != none )
	// 	{
    //         return BulletProj;
	// 	}
    // }

   	return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
	// return None;
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

	// simulated event vector GetMuzzleLoc()
	// {
	// 	local vector MuzzleLocation;

	// 	// swap fireoffset temporarily
	// 	FireOffset = SecondaryFireOffset;
	// 	MuzzleLocation = Global.GetMuzzleLoc();
	// 	FireOffset = default.FireOffset;

	// 	return MuzzleLocation;
	// }

	simulated event vector GetMuzzleLoc()
	{
		local vector MuzzleLocation;

		MuzzleLocation = Global.GetMuzzleLoc();

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
	local vector MuzzleLocation, HitLocation, HitNormal;

	if (Role == ROLE_Authority)
	{
		MuzzleLocation = GetMuzzleLoc();
		Trace( HitLocation, HitNormal, MuzzleLocation + vect(0,0,1) * 400, MuzzleLocation,,,,TRACEFLAG_BULLET);
	}

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (HitLocation == vect(0,0,0))
		{
			MySkelMesh.GetSocketWorldLocationAndRotation('MuzzleFlash', MuzzleLocation);
			ProjectileFireCustom();
		}
		else
		{
			ProjectileFire();
		}
	}

	// Alt-fire only (server authoritative)
	// if ( CurrentFireMode != ALTFIRE_FIREMODE )
	// {
	// 	Super.CustomFire();
	// 	return;
	// }
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
		MySkelMesh.GetSocketWorldLocationAndRotation( 'MuzzleFlash', StartTrace, AimRot);
		GetMuzzleLocAndRot(StartTrace, AimRot);

		// AimDir = Vector(Owner.Rotation);
		// AimDir = Vector(AimRot);
		AimDir = Vect(0,0,1); //aims upwards here

		// this is the location where the projectile is spawned.
		RealStartLoc = StartTrace;

		return SpawnAllProjectiles(MyProjectileClass, RealStartLoc, AimDir);
	}

	return None;
}

simulated function GetMuzzleLocAndRot(out vector MuzzleLoc, out rotator MuzzleRot)
{
	if (KFSkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation('MuzzleFlash', MuzzleLoc, MuzzleRot) == false)
	{
		`Log("Alt muzzleFlash not found!");
	}

	// To World Coordinates. (Rotation should be 0 so no taken into account)
	// MuzzleLoc = Location + QuatRotateVector(QuatFromRotator(Rotation), MuzzleLoc);
}

/*
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

// Disable normal bullet spread
simulated function rotator AddSpread(rotator BaseAim)
{
	return BaseAim; // do nothing
}

// Same as AddSpread(), but used with MultiShotSpread
static function rotator AddMultiShotSpread( rotator BaseAim, float CurrentSpread, byte PelletNum )
{
	local vector X, Y, Z;
	local float RandY, RandZ;

	if (CurrentSpread == 0) // 0.3214
	{
		return BaseAim;
	}
	else
	{
        // No randomized spread, it's controlled in PelletSpread down bellow
		GetAxes(BaseAim, X, Y, Z);
		RandY = default.PelletSpread[PelletNum].Y; //* RandRange( 0.5f, 1.5f
		RandZ = default.PelletSpread[PelletNum].X;
		return rotator(X + RandY * CurrentSpread * Y + RandZ * CurrentSpread * Z);
	}
}

/*
// Allows weapon to calculate its own damage for display in trader
// Overridden to multiply damage by number of pellets
static simulated function float CalculateTraderWeaponStatDamage()
{
    local float BaseDamage, DoTDamage;
    local class<KFDamageType> DamageType;

    local GameExplosion ExplosionInstance;

    ExplosionInstance = class<KFProjectile>(default.WeaponProjectiles[DEFAULT_FIREMODE]).default.ExplosionTemplate;

    BaseDamage = default.InstantHitDamage[DEFAULT_FIREMODE] + ExplosionInstance.Damage;

    DamageType = class<KFDamageType>(ExplosionInstance.MyDamageType);
    if( DamageType != none && DamageType.default.DoT_Type != DOT_None )
    {
        DoTDamage = (DamageType.default.DoT_Duration / DamageType.default.DoT_Interval) * (BaseDamage * DamageType.default.DoT_DamageScale);
    }

    return BaseDamage * default.NumPellets[DEFAULT_FIREMODE] + DoTDamage;
}
*/

// Tight choke skill - remove if you want slugs ("combines" 9 bullets into one)
simulated function KFProjectile SpawnAllProjectiles(class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir)
{
	local KFPerk InstigatorPerk;

	if (CurrentFireMode == DEFAULT_FIREMODE)
	{
		InstigatorPerk = GetPerk();
		if (InstigatorPerk != none)
		{
			Spread[CurrentFireMode] = default.Spread[CurrentFireMode] * InstigatorPerk.GetTightChokeModifier();
		}
	}

	return super.SpawnAllProjectiles(KFProjClass, RealStartLoc, AimDir);
}

// Get our optics movie from the inventory once our InvManager is created
reliable client function ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate)
{
	local KFInventoryManager KFIM;

	super.ClientWeaponSet(bOptionalSet, bDoNotActivate);

	if (OpticsUI == none)
	{
		KFIM = KFInventoryManager(InvManager);
		if (KFIM != none)
		{
			//Create the screen's UI piece
			OpticsUI = KFGFxWorld_MedicOptics(KFIM.GetOpticsUIMovie(OpticsUIClass));
		}
	}
}

// Update our displayed ammo count if it's changed
simulated function UpdateOpticsUI(optional bool bForceUpdate)
{
	if (OpticsUI != none && OpticsUI.OpticsContainer != none)
	{
		if (AmmoCount[DEFAULT_FIREMODE] != StoredPrimaryAmmo || bForceUpdate)
		{
			StoredPrimaryAmmo = AmmoCount[DEFAULT_FIREMODE];
			OpticsUI.SetPrimaryAmmo(StoredPrimaryAmmo);
		}

		if (AmmoCount[ALTFIRE_FIREMODE] != StoredSecondaryAmmo || bForceUpdate)
		{
			StoredSecondaryAmmo = AmmoCount[ALTFIRE_FIREMODE];
			OpticsUI.SetHealerCharge(StoredSecondaryAmmo);
		}

		if(OpticsUI.MinPercentPerShot != AmmoCost[ALTFIRE_FIREMODE])
		{
			OpticsUI.SetShotPercentCost( AmmoCost[ALTFIRE_FIREMODE] );
		}
	}
}

function ItemRemovedFromInvManager()
{
	local KFInventoryManager KFIM;
	local KFWeap_MedicBase KFW;

	Super.ItemRemovedFromInvManager();

	if (OpticsUI != none)
	{
		KFIM = KFInventoryManager(InvManager);
		if (KFIM != none)
		{
			// @todo future implementation will have optics in base weapon class
			foreach KFIM.InventoryActors(class'KFWeap_MedicBase', KFW)
			{
				// This is not a MedicBase, no need to check against itself
				if(KFW.OpticsUI.Class == OpticsUI.class)
				{
					// A different weapon is still using this optics class
					return;
				}
			}

			//Create the screen's UI piece
			KFIM.RemoveOpticsUIMovie(OpticsUI.class);

			OpticsUI.Close();
			OpticsUI = none;
		}
	}
}

// Unpause our optics movie and reinitialize our ammo when we equip the weapon
simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional Name SocketName)
{
	super.AttachWeaponTo(MeshCpnt, SocketName);

	if (OpticsUI != none)
	{
		OpticsUI.SetPause(false);
		OpticsUI.ClearLockOn();
		UpdateOpticsUI(true);
		OpticsUI.SetShotPercentCost( AmmoCost[ALTFIRE_FIREMODE]);
	}
}

// Pause the optics movie once we unequip the weapon so it's not playing in the background
simulated function DetachWeapon()
{
	local Pawn OwnerPawn;
	super.DetachWeapon();

	OwnerPawn = Pawn(Owner);
	if( OwnerPawn != none && OwnerPawn.Weapon == self )
	{
		if (OpticsUI != none)
		{
			OpticsUI.SetPause();
		}
	}
}

// Allows weapon to set its own trader stats (can set number of stats, names and values of stats)
static simulated event SetTraderWeaponStats( out array<STraderItemWeaponStats> WeaponStats )
{
	super.SetTraderWeaponStats( WeaponStats );

	WeaponStats.Length = WeaponStats.Length + 1;
	WeaponStats[WeaponStats.Length-1].StatType = TWS_RechargeTime;
	WeaponStats[WeaponStats.Length-1].StatValue = default.AltFullRechargeSeconds;
}

defaultproperties
{
	// Inventory
	InventorySize=5
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Valkyrie_MAT.UI_WeaponSelect_Valkyrie'
	AssociatedPerkClasses(0)=class'KFPerk_Survivalist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DTest' // Loot beam fx (no offset)

	// FOV
	MeshFOV=75
	MeshIronSightFOV=55
	PlayerIronSightFOV=75

	// Zooming/Position
	// IronSightPosition=(X=0.f,Y=0.f,Z=0.f)
	IronSightPosition=(X=0.0,Y=5.0,Z=6.0)
	PlayerViewOffset=(X=19,Y=10,Z=-0.5)

	//Content
	PackageKey="Valkyrie"
	FirstPersonMeshName="WEP_Valkyrie_MESH.Wep_1stP_Valkyrie_Rig"
	FirstPersonAnimSetNames(0)="wep_1p_p90_anim.Wep_1stP_P90_Anim"
	PickupMeshName="WEP_Valkyrie_MESH.Wep_Valkyrie_Pickup"
	AttachmentArchetypeName="WEP_Valkyrie_ARCH.WEP_Valkyrie_3P"
	MuzzleFlashTemplateName="WEP_Valkyrie_ARCH.Wep_Valkyrie_MuzzleFlash"
	// SecondaryMuzzleFlashTemplate=KFMuzzleFlash'WEP_M99_ARCH.Wep_M99_MuzzleFlash'

    OpticsUIClass=class'KFGFxWorld_MedicOptics'

	// Create all these particle system components off the bat so that the tick group can be set
	// fixes issue where the particle systems get offset during animations
	Begin Object Class=KFParticleSystemComponent Name=BasePSC0
		TickGroup=TG_PostUpdateWork
	End Object
	ParticlePSC=BasePSC0
	ParticleFXTemplate=ParticleSystem'DTest_EMIT.FX_Valkyrie_ParticleFX'

	// Ammo
	MagazineCapacity[0]=50
	SpareAmmoCapacity[0]=350
	InitialSpareMags[0]=2
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=80
	minRecoilPitch=65
	maxRecoilYaw=60
	minRecoilYaw=-60
	RecoilRate=0.063
	RecoilMaxYawLimit=400
	RecoilMinYawLimit=65135
	RecoilMaxPitchLimit=800
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=150
	RecoilISMinYawLimit=65385
	RecoilISMaxPitchLimit=350
	RecoilISMinPitchLimit=65435
	IronSightMeshFOVCompensationScale=1.5

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Valkyrie'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Valkyrie'
	FireInterval(DEFAULT_FIREMODE)=+.07 // 900 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=10 //30
	// Spread(DEFAULT_FIREMODE)=0.01
	FireOffset=(X=30,Y=4.5,Z=-5)

	// BarrelOffsetX=(X=10.0,Y=0,Z=0) // minus for other proj
	// BarrelOffsetZ=(X=0.0,Y=0,Z=10.0)

	Spread(DEFAULT_FIREMODE)=0.1f
	NumPellets(DEFAULT_FIREMODE)=4
	PelletSpread(0)=(X=0.2f,Y=0.0f)
	PelletSpread(1)=(X=-0.2f,Y=0.0f)
	PelletSpread(2)=(X=0.0f,Y=0.2f)
	PelletSpread(3)=(X=0.0f,Y=-0.2f)

	// ALTFIRE_FIREMODE
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'UI_FireModes_TEX.UI_FireModeSelect_Rocket'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponBurstFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Custom //EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Rocket_Valkyrie'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_Valkyrie'
	InstantHitDamage(ALTFIRE_FIREMODE)=145
	FireInterval(ALTFIRE_FIREMODE)=+0.1 // 600 RPM
	PenetrationPower(ALTFIRE_FIREMODE)=0
	Spread(ALTFIRE_FIREMODE)=4.0
	// SecondaryFireOffset=(X=0.f,Y=0,Z=1.f)

	AltAmmo=8
	MagazineCapacity[1]=8
	AmmoCost(ALTFIRE_FIREMODE)=1
	AltFullRechargeSeconds=15
	bCanRefillSecondaryAmmo=false;
    SecondaryAmmoTexture=Texture2D'UI_FireModes_TEX.UI_FireModeSelect_Rocket'
	// bAllowClientAmmoTracking=true

	// Target Locking
	// MinTargetDistFromCrosshairSQ=2500.0f // 0.5 meters
	MaxTargetAngle=30
	TimeBetweenLockOns=0.06f
	TargetValidationCheckInterval=0.1f
	MaxLockMaintainFOVDotThreshold=0.36f

	// LockOn Visuals
    LockedOnIcon=Texture2D'DTest_MAT.Wep_1stP_Cube_Thicc_Small_45_Target_T'
    LockedIconColor=(R=1.f, G=0.f, B=0.f, A=0.5f)

    // Lock On/Lost Sounds
	LockAcquiredSoundFirstPerson=AkEvent'WW_WEP_SA_Railgun.Play_Railgun_Scope_Locked'
	LockLostSoundFirstPerson=AkEvent'WW_WEP_SA_Railgun.Play_Railgun_Scope_Lost'

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_P90'
	InstantHitDamage(BASH_FIREMODE)=25

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_P90.Play_P90_Fire_3P_Loop', FirstPersonCue=AkEvent'WW_WEP_P90.Play_P90_Fire_1P_Loop')
	WeaponFireLoopEndSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_P90.Play_P90_Fire_3P_EndLoop', FirstPersonCue=AkEvent'WW_WEP_P90.Play_P90_Fire_1P_EndLoop')
	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_FNFAL.Play_WEP_FNFAL_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_FNFAL.Play_WEP_FNFAL_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=true
	bLoopingFireSnd(DEFAULT_FIREMODE)=true
	SingleFireSoundIndex=2
	WeaponFireSnd(2)=(DefaultCue=AkEvent'WW_WEP_P90.Play_P90_Fire_3P_Single', FirstPersonCue=AkEvent'WW_WEP_P90.Play_P90_Fire_1P_Single')

	// Attachments
	bHasIronSights=true
	bHasFlashlight=true
}