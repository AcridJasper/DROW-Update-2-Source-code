class KFWeap_Inferno extends KFWeap_MeleeBase;

// Number of projectiles to spawn
// var() int NumOfGrenades;

var transient KFParticleSystemComponent FirePSC;
var const ParticleSystem FireFXTemplate;

/* Light that is applied to the blade and the bone to attach to*/
var PointLightComponent IdleLight;
var Name LightAttachBone;

/** The current amount of charge/heat this weapon has */
var repnotify float UltimateCharge;
/** The highest amount of charge/heat this weapon can have*/
var float MaxUltimateCharge;

/** How much charge to gain when hitting with each Firemode */
var array<float> UltimateChargePerHit;
/** How much charge to gain with a successful block */
var float UltimateChargePerBlock;
/** How much charge to gain with a successful parry */
var float UltimateChargePerParry;

/** Name of the special anim used for the ultimate attack */
var name UltimateAttackAnim;

// Heavy attack sword throwing anim
// var name SwordThrowAttackAnim;

/** Particle system that plays when the weapon is fully charged */
// var transient KFParticleSystemComponent ChargedPSC;
// var const ParticleSystem ChargedEffect;

// Explodes on hit
var GameExplosion LightExplosionTemplate, HeavyExplosionTemplate;
var transient ParticleSystemComponent ExplosionPSC;
var ParticleSystem ExplosionEffect;

var float ExplosionOriginalDamage;

var bool bWasTimeDilated;

// var AkEvent AmbientSoundPlayEvent;
// var AkEvent AmbientSoundStopEvent;

var const float MaxTargetAngle;
var transient float CosTargetAngle;

replication
{
	if (bNetDirty)
		UltimateCharge;
}

simulated event ReplicatedEvent(name VarName)
{
	switch (VarName)
	{
	case nameof(UltimateCharge):
		// AdjustChargeFX();
		break;
	default:
		super.ReplicatedEvent(VarName);
	};
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	CosTargetAngle = Cos(MaxTargetAngle * DegToRad);

	ExplosionOriginalDamage = LightExplosionTemplate.Damage;
	ExplosionOriginalDamage = HeavyExplosionTemplate.Damage;
}

simulated function string GetSpecialAmmoForHUD()
{
	return int(UltimateCharge)$"%";
}

// When this weapon hits with an attack
simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
{
	local KFPawn_Monster Victim;

	if (HitActor.bWorldGeometry)
	{
		return;
	}

	Victim = KFPawn_Monster(HitActor);
	if ( Victim == None || (Victim.bPlayedDeath && `TimeSince(Victim.TimeOfDeath) > 0.f) )
	{
		return;
	}

	if(Victim != none)
	{
		// hit something with a melee attack so gain charge
		AdjustUltimateCharge(UltimateChargePerHit[CurrentFireMode]);
	}
}

// When this weapon hits, explode with given template
simulated state MeleeChainAttacking
{
	simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
	{
		local KFPawn_Monster Victim;
		local KFExplosionActorReplicated ExploActor;

		// On local player or server, we cache off our time dilation setting here
		if (WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_DedicatedServer || Instigator.Controller != None)
		{
			bWasTimeDilated = WorldInfo.TimeDilation < 1.f;
		}

		if (HitActor.bWorldGeometry)
		{
			return;
		}
	
		Victim = KFPawn_Monster(HitActor);
		if ( Victim == None || (Victim.bPlayedDeath && `TimeSince(Victim.TimeOfDeath) > 0.f) )
		{
			return;
		}

		if(Victim != none)
		{
			// hit something with a melee attack so gain charge
			AdjustUltimateCharge(UltimateChargePerHit[CurrentFireMode]);
		}

		if ( Role == ROLE_Authority && Instigator != None && Instigator.IsLocallyControlled() )
		{
			// Nudge explosion location
			// HitLocation = HitLocation + (vect(0,0,1) * 128.f);
	
			// Explode using the given template
			ExploActor = Spawn(class'KFExplosionActorReplicated', self,, HitLocation, rotator(vect(0,0,1)),, true);
			if (ExploActor != None)
			{
				ExploActor.InstigatorController = Instigator.Controller;
				ExploActor.Instigator = Instigator;
				ExploActor.bIgnoreInstigator = true;
				LightExplosionTemplate.Damage = ExplosionOriginalDamage * GetUpgradeDamageMod(DEFAULT_FIREMODE);
				LightExplosionTemplate.Damage = ExplosionOriginalDamage * GetUpgradeDamageMod(HEAVY_ATK_FIREMODE);
				LightExplosionTemplate.Damage = ExplosionOriginalDamage * GetUpgradeDamageMod(BASH_FIREMODE);
	
				ExploActor.Explode(LightExplosionTemplate);
			}

			// tell remote clients that we fired, to trigger effects in third person
			// IncrementFlashCount();
		}
	
		if (WorldInfo.NetMode != NM_DedicatedServer)
		{
			if (ExplosionEffect != None)
			{
				ExplosionPSC = WorldInfo.MyEmitterPool.SpawnEmitter(ExplosionEffect, HitLocation, rotator(vect(0,0,1)));
				ExplosionPSC.ActivateSystem();
			}
		}
	}
}

// When this weapon hits, explode with given template
simulated state MeleeHeavyAttacking
{
	simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
	{
		local KFPawn_Monster Victim;
		local KFExplosionActorReplicated ExploActor;
	
		// On local player or server, we cache off our time dilation setting here
		if (WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_DedicatedServer || Instigator.Controller != None)
		{
			bWasTimeDilated = WorldInfo.TimeDilation < 1.f;
		}

		if (HitActor.bWorldGeometry)
		{
			return;
		}
	
		Victim = KFPawn_Monster(HitActor);
		if ( Victim == None || (Victim.bPlayedDeath && `TimeSince(Victim.TimeOfDeath) > 0.f) )
		{
			return;
		}

		if(Victim != none)
		{
			// hit something with a melee attack so gain charge
			AdjustUltimateCharge(UltimateChargePerHit[CurrentFireMode]);
		}

		if ( Role == ROLE_Authority && Instigator != None && Instigator.IsLocallyControlled() )
		{
			// Nudge explosion location
			// HitLocation = HitLocation + (vect(0,0,1) * 128.f);
	
			// Explode using the given template
			ExploActor = Spawn(class'KFExplosionActorReplicated', self,, HitLocation, rotator(vect(0,0,1)),, true);
			if (ExploActor != None)
			{
				ExploActor.InstigatorController = Instigator.Controller;
				ExploActor.Instigator = Instigator;
				ExploActor.bIgnoreInstigator = true;
				HeavyExplosionTemplate.Damage = ExplosionOriginalDamage * GetUpgradeDamageMod(DEFAULT_FIREMODE);
				HeavyExplosionTemplate.Damage = ExplosionOriginalDamage * GetUpgradeDamageMod(HEAVY_ATK_FIREMODE);
				HeavyExplosionTemplate.Damage = ExplosionOriginalDamage * GetUpgradeDamageMod(BASH_FIREMODE);
	
				ExploActor.Explode(HeavyExplosionTemplate);
			}

			// tell remote clients that we fired, to trigger effects in third person
			// IncrementFlashCount();
		}
	
		if (WorldInfo.NetMode != NM_DedicatedServer)
		{
			if (ExplosionEffect != None)
			{
				ExplosionPSC = WorldInfo.MyEmitterPool.SpawnEmitter(ExplosionEffect, HitLocation, rotator(vect(0,0,1)));
				ExplosionPSC.ActivateSystem();
			}
		}
	}
}

/** When this weapon parries an attack */
simulated function NotifyAttackParried()
{
	AdjustUltimateCharge(UltimateChargePerParry);
}

/** When this weapon blocks an attack */
simulated function NotifyAttackBlocked()
{
	AdjustUltimateCharge(UltimateChargePerBlock);
}

/** Whether the weapon is fully charged */
simulated function bool IsFullyCharged()
{
	return UltimateCharge >= MaxUltimateCharge;
}

/** Increase or decrease ultimate charge as long as not already fully charged*/
simulated function AdjustUltimateCharge(float AdjustAmount)
{
	if (!IsFullyCharged())
	{
		UltimateCharge = FClamp(UltimateCharge + AdjustAmount, 0.f, MaxUltimateCharge);
		// AdjustChargeFX();
	}
}

// simulated function AdjustChargeFX()
// {
// 	if (WorldInfo.NetMode != NM_DedicatedServer)
// 	{
// 		if (IsFullyCharged())
// 		{
// 			ActivatePSC(ChargedPSC, ChargedEffect, 'Hand_FX_Start_R');
// 		}
// 	}
// }

// Launch projectile ONLY if we are fully charged and if we have a lock on active
simulated function StartFire(byte FireModeNum)
{
	local KFPawn TargetPawn;
				
	if ( FireModeNum == RELOAD_FIREMODE && IsFullyCharged() && FindTarget(TargetPawn) )
	{
		FireModeNum = CUSTOM_FIREMODE;
	}

	super.StartFire(FireModeNum);
}

// State for the fully charged Ultimate attack 
simulated state UltimateAttackState extends MeleeHeavyAttacking
{
	simulated function bool TryPutDown() { return false; }

	simulated event BeginState(Name PreviousStateName)
	{
		// local vector MuzzleLocation, HitLocation, HitNormal;
		// local KFPawn TargetPawn;

		super.BeginState(PreviousStateName);

		// stop the player from interrupting the super attack with another attack
		StartFireDisabled = true;

		ProjectileFireCustom();

	/*
		if (Role == ROLE_Authority)
		{
			MuzzleLocation = GetMuzzleLoc();
			Trace( HitLocation, HitNormal, MuzzleLocation + vect(0,0,1) * 500, MuzzleLocation,,,,TRACEFLAG_BULLET);
		}

		if (WorldInfo.NetMode != NM_DedicatedServer)
		{
			if (HitLocation == vect(0,0,0) && FindTarget(TargetPawn))
			{
				MySkelMesh.GetSocketWorldLocationAndRotation('FireFX', MuzzleLocation);
				ProjectileFireCustom();
			}
			else
			{
				TestGrenade();
			}
		}
*/
	}

/*
	simulated event vector GetMuzzleLoc()
	{
		local vector MuzzleLocation;

		MuzzleLocation = Global.GetMuzzleLoc();

		return MuzzleLocation;
	}
*/

	simulated function name GetMeleeAnimName(EPawnOctant AtkDir, EMeleeAttackType AtkType)
	{
		// use the special attack anim
		return UltimateAttackAnim;
	}

	simulated event EndState(Name NextStateName)
	{
		super.EndState(NextStateName);

		// consume charge
		UltimateCharge = 0;

		// if (ChargedPSC != none)
		// {
		// 	ChargedPSC.DeactivateSystem();
		// }

		// player can now interrupt attacks with other attacks again
		StartFireDisabled = false;
	}
}

/*
function TestGrenade()
{
	local KFProj_Grenade SpawnedGrenade;
	local class<KFProj_Grenade> GrenadeClass;

    GrenadeClass = class<KFProj_Grenade>(DynamicLoadObject("DTest.KFProj_Blast_Inferno", class'Class'));

	// Spawn Grenade
	SpawnedGrenade = Spawn( GrenadeClass, self);
	if( SpawnedGrenade != none && !SpawnedGrenade.bDeleteMe )
	{
		SpawnedGrenade.UpgradeDamageMod = GetUpgradeDamageMod();
		
		// return;
	}
}
*/

simulated event bool HasAmmo(byte FireModeNum, optional int Amount)
{
	if (FireModeNum == CUSTOM_FIREMODE)
	{
		return IsFullyCharged();
	}

	return super.HasAmmo(FireModeNum, Amount);
}

// Given an potential target TA determine if we can lock on to it.  By default only allow locking on to pawns.
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

// Spawn projectile is called once for each rocket fired. In burst mode it will cycle through targets until it runs out
simulated function KFProjectile SpawnProjectile( class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir )
{
	local KFProj_Rocket_Inferno RocketProj;
	local KFPawn TargetPawn;

    if( CurrentFireMode == GRENADE_FIREMODE )
    {
        return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
    }

    if ( CurrentFireMode == CUSTOM_FIREMODE )
	{
		FindTarget(TargetPawn);

		RocketProj = KFProj_Rocket_Inferno( super.SpawnProjectile( class<KFProjectile>(WeaponProjectiles[CurrentFireMode]) , RealStartLoc, AimDir) );
		if( RocketProj != none )
		{
			// We'll aim our rocket at a target here otherwise we will spawn a dumbfire rocket at the end of the function
			if ( TargetPawn != none)
			{
				//Seek to new target, then remove it
				RocketProj.SetLockedTarget( TargetPawn );
			}
		}

		return RocketProj;
	}

   	return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
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
		MySkelMesh.GetSocketWorldLocationAndRotation( 'FireFX', StartTrace, AimRot);
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
	if (KFSkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation('FireFX', MuzzleLoc, MuzzleRot) == false)
	{
		`Log("MuzzleFlash not found!");
	}

	// To World Coordinates. (Rotation should be 0 so no taken into account)
	// MuzzleLoc = Location + QuatRotateVector(QuatFromRotator(Rotation), MuzzleLoc);
}


/*
// State when heavy attacking
simulated state SwordThrowAttackState extends MeleeHeavyAttacking
{
	simulated event BeginState(Name PreviousStateName)
	{
		//local name WeaponFireAnimName; // you have to play animation (bash has anims)
        local KFPerk InstigatorPerk;

        InstigatorPerk = GetPerk();
        if( InstigatorPerk != none )
        {
            SetZedTimeResist( InstigatorPerk.GetZedTimeModifier(self) );
        }

		`LogInv("PreviousStateName:" @ PreviousStateName);

		ConsumeAmmo(CurrentFireMode);

	    // set timer for spawning projectile
		TimeWeaponFiring(CurrentFireMode);
		ClearPendingFire(CurrentFireMode);

		NotifyBeginState();
	}

	simulated function name GetMeleeAnimName(EPawnOctant AtkDir, EMeleeAttackType AtkType)
	{
		// use the special attack anim
		return SwordThrowAttackAnim;
	}

	simulated event EndState(Name NextStateName)
	{
		super.EndState(NextStateName);

		ClearZedTimeResist();
		NotifyEndState();

		// Spawn projectile
		// (don't use FireAmmunition because that causes FireAnim to be played again)
		ProjectileFire();
		NotifyWeaponFired(CurrentFireMode);
	}
}
*/



/*
simulated state SwordThrowAttackState extends MeleeHeavyAttacking
{
	// Overriden to not call FireAmmunition right at the start of the state
    simulated event BeginState( Name PreviousStateName )
	{
		local name WeaponFireAnimName;
        local KFPerk InstigatorPerk;

        InstigatorPerk = GetPerk();
        if( InstigatorPerk != none )
        {
            SetZedTimeResist( InstigatorPerk.GetZedTimeModifier(self) );
        }

		`LogInv("PreviousStateName:" @ PreviousStateName);

		ConsumeAmmo(CurrentFireMode);

		// play animation here since we're not calling super (because we don't want to call FireAmmunition yet)
		if( Instigator != none && Instigator.IsFirstPerson() )
	    {
	    	WeaponFireAnimName = GetWeaponFireAnim(CurrentFireMode);
	    	if ( WeaponFireAnimName != '' )
	    	{
	    		PlayAnimation(WeaponFireAnimName, MySkelMesh.GetAnimLength(WeaponFireAnimName),,FireTweenTime);
	    	}
	    }

	    // set timer for spawning projectile
		TimeWeaponFiring(CurrentFireMode);
		ClearPendingFire(CurrentFireMode);

		NotifyBeginState();

		// called here and ignored in ProjectileFire in EndState because we want to play the 3p anims now
		IncrementFlashCount();
	}

	simulated function name GetMeleeAnimName(EPawnOctant AtkDir, EMeleeAttackType AtkType)
	{
		// use the special attack anim
		return SwordThrowAttackAnim;
	}

	simulated function EndState(Name NextStateName)
	{
		Super.EndState(NextStateName);
		NotifyEndState();

		// Spawn projectile
		// (don't use FireAmmunition because that causes FireAnim to be played again)
		ProjectileFire();
		NotifyWeaponFired(CurrentFireMode);
	}
}
*/



/*
simulated event Tick( FLOAT DeltaTime )
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if ( MaxUltimateCharge > 99.0f )
		{
			NotifyAdjustChargeReady(true);
		}
	}

	Super.Tick(DeltaTime);
}

simulated function NotifyAdjustChargeReady(bool bActive)
{
	local KFPawn KFP;

	if (WorldInfo.NetMode != NM_Client)
	{
		KFP = KFPawn(Instigator);
		KFP.OnWeaponSpecialAction(bActive ? 2 : 1);
	}
}
*/

/*
// Explosion actor class to spawn
var class<KFExplosionActor> ExplosionActorClass;
var() KFGameExplosion ExplosionTemplate;

var transient Actor BlastAttachee;
// Spawn location offset to improve cone hit detection
var transient float BlastSpawnOffset;

var bool bWasTimeDilated;
var bool bFriendlyFireEnabled;

replication
{
	if (bNetInitial)
		bFriendlyFireEnabled;
}

simulated event PreBeginPlay()
{
	Super.PreBeginPlay();

	// Initially check whether friendly fire is on or not
	if(Role == ROLE_Authority && KFGameInfo(WorldInfo.Game).FriendlyFireScale != 0.f)
	{
		bFriendlyFireEnabled = true;
	}
}

simulated state MeleeChainAttacking
{
	simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
	{
		local KFExplosionActor ExploActor;
		local vector SpawnLoc;
		local rotator SpawnRot;

		local KFPawn Victim;

		if ( Instigator != None && Instigator.IsLocallyControlled() )
		{
			// On local player or server, we cache off our time dilation setting here
			if (WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_DedicatedServer || Instigator.Controller != None)
			{
				bWasTimeDilated = WorldInfo.TimeDilation < 1.f;
			}

			// only detonate when the pulverizer hits a pawn so that level geometry doesn't get in the way
			if ( HitActor.bWorldGeometry )
			{
				return;
			}

			Victim = KFPawn(HitActor);
			if ( Victim == None ||
				(!bFriendlyFireEnabled && Victim.GetTeamNum() == Instigator.GetTeamNum()) ||
				(Victim.bPlayedDeath && `TimeSince(Victim.TimeOfDeath) > 0.f) )
			{
				return;
			}

			SpawnLoc = Instigator.GetWeaponStartTraceLocation();

			// nudge backwards to give a wider code near the player
			SpawnLoc += vector(SpawnRot) * BlastSpawnOffset;

			// explode using the given template
			ExploActor = Spawn(ExplosionActorClass, self,, SpawnLoc, SpawnRot,, true);
			if (ExploActor != None)
			{
				ExploActor.InstigatorController = Instigator.Controller;
				ExploActor.Instigator = Instigator;

				// Force the actor we collided with to get hit again (when DirectionalExplosionAngleDeg is small)
				// This is only necessary on server since GetEffectCheckRadius() will be zero on client
				ExploActor.Attachee = BlastAttachee;
				ExplosionTemplate.bFullDamageToAttachee = true;

				// enable muzzle location sync
				ExploActor.bReplicateInstigator = true;
				// ExploActor.SetSyncToMuzzleLocation(true);

				ExploActor.Explode(ExplosionTemplate, vector(SpawnRot));
			}

			// tell remote clients that we fired, to trigger effects in third person
			IncrementFlashCount();
		}
	}
}

simulated state MeleeAttackBasic
{
	simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
	{
		local KFExplosionActor ExploActor;
		local vector SpawnLoc;
		local rotator SpawnRot;

		local KFPawn Victim;

		if ( Instigator != None && Instigator.IsLocallyControlled() )
		{
			// On local player or server, we cache off our time dilation setting here
			if (WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_DedicatedServer || Instigator.Controller != None)
			{
				bWasTimeDilated = WorldInfo.TimeDilation < 1.f;
			}

			// only detonate when the pulverizer hits a pawn so that level geometry doesn't get in the way
			if ( HitActor.bWorldGeometry )
			{
				return;
			}

			Victim = KFPawn(HitActor);
			if ( Victim == None ||
				(!bFriendlyFireEnabled && Victim.GetTeamNum() == Instigator.GetTeamNum()) ||
				(Victim.bPlayedDeath && `TimeSince(Victim.TimeOfDeath) > 0.f) )
			{
				return;
			}

			SpawnLoc = Instigator.GetWeaponStartTraceLocation();

			// nudge backwards to give a wider code near the player
			SpawnLoc += vector(SpawnRot) * BlastSpawnOffset;

			// explode using the given template
			ExploActor = Spawn(ExplosionActorClass, self,, SpawnLoc, SpawnRot,, true);
			if (ExploActor != None)
			{
				ExploActor.InstigatorController = Instigator.Controller;
				ExploActor.Instigator = Instigator;

				// Force the actor we collided with to get hit again (when DirectionalExplosionAngleDeg is small)
				// This is only necessary on server since GetEffectCheckRadius() will be zero on client
				ExploActor.Attachee = BlastAttachee;
				ExplosionTemplate.bFullDamageToAttachee = true;

				// enable muzzle location sync
				ExploActor.bReplicateInstigator = true;
				// ExploActor.SetSyncToMuzzleLocation(true);

				ExploActor.Explode(ExplosionTemplate, vector(SpawnRot));
			}

			// tell remote clients that we fired, to trigger effects in third person
			IncrementFlashCount();
		}
	}
}

simulated state MeleeHeavyAttacking
{
	simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
	{
		local KFExplosionActor ExploActor;
		local vector SpawnLoc;
		local rotator SpawnRot;

		local KFPawn Victim;

		if ( Instigator != None && Instigator.IsLocallyControlled() )c
		{
			// On local player or server, we cache off our time dilation setting here
			if (WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_DedicatedServer || Instigator.Controller != None)
			{
				bWasTimeDilated = WorldInfo.TimeDilation < 1.f;
			}

			// only detonate when the pulverizer hits a pawn so that level geometry doesn't get in the way
			if ( HitActor.bWorldGeometry )
			{
				return;
			}

			Victim = KFPawn(HitActor);
			if ( Victim == None ||
				(!bFriendlyFireEnabled && Victim.GetTeamNum() == Instigator.GetTeamNum()) ||
				(Victim.bPlayedDeath && `TimeSince(Victim.TimeOfDeath) > 0.f) )
			{
				return;
			}

			SpawnLoc = Instigator.GetWeaponStartTraceLocation();

			// nudge backwards to give a wider code near the player
			SpawnLoc += vector(SpawnRot) * BlastSpawnOffset;

			// explode using the given template
			ExploActor = Spawn(ExplosionActorClass, self,, SpawnLoc, SpawnRot,, true);
			if (ExploActor != None)
			{
				ExploActor.InstigatorController = Instigator.Controller;
				ExploActor.Instigator = Instigator;

				// Force the actor we collided with to get hit again (when DirectionalExplosionAngleDeg is small)
				// This is only necessary on server since GetEffectCheckRadius() will be zero on client
				ExploActor.Attachee = BlastAttachee;
				ExplosionTemplate.bFullDamageToAttachee = true;

				// enable muzzle location sync
				ExploActor.bReplicateInstigator = true;
				// ExploActor.SetSyncToMuzzleLocation(true);

				ExploActor.Explode(ExplosionTemplate, vector(SpawnRot));
			}

			// tell remote clients that we fired, to trigger effects in third person
			IncrementFlashCount();
		}
	}
}
*/

// simulated state MeleeHeavyAttacking
// {
// 	simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
// 	{
// 		local KFPawn Victim;

// 		if ( Instigator != None && Instigator.IsLocallyControlled() )
// 		{
// 			if ( HitActor.bWorldGeometry )
// 			{
// 				return;
// 			}

// 			Victim = KFPawn(HitActor);
// 			if ( Victim == None || (Victim.bPlayedDeath && `TimeSince(Victim.TimeOfDeath) > 0.f) )
// 			{
// 				return;
// 			}

// 			TestSpawnGrenade();
// 		}
// 	}
// }

// function TestSpawnGrenade()
// {
//     local class<KFProj_Grenade> GrenadeClass;
//     local KFProj_Grenade SpawnedGrenade;

// 	local vector NudgedLocation;

//     GrenadeClass = class<KFProj_Grenade>(DynamicLoadObject("KFGameContent.KFProj_DynamiteGrenade", class'Class'));

// 	NudgedLocation = Location + (vect(0,0,1) * 2000.f);

//     // Spawn Grenade
//     SpawnedGrenade = Spawn( GrenadeClass, self,, NudgedLocation );
//     if( SpawnedGrenade != none && !SpawnedGrenade.bDeleteMe )
//     {
// 		// SpawnedGrenade.Velocity = Vect(0,0,1) * 1250.f;

//     	return;
//         // SpawnedGrenade.ExplosionTemplate = class'KFPerk_Berser'.static.GetNukeExplosionTemplate();
//         // SpawnedGrenade.ExplosionActorClass = class'KFPerk_Demolitionist'.static.GetNukeExplosionActorClass();
//     }
// }

simulated state WeaponEquipping
{
	// when picked up, start the persistent sound
	simulated event BeginState(Name PreviousStateName)
	{
		// local KFPawn InstigatorPawn;

		super.BeginState(PreviousStateName);

		ActivatePSC(FirePSC, FireFXTemplate, 'FireFX');

		if (MySkelMesh != none)
		{
			MySkelMesh.AttachComponentToSocket(IdleLight, LightAttachBone);
			IdleLight.SetEnabled(true);
		}

		// if (Instigator != none)
		// {
		// 	InstigatorPawn = KFPawn(Instigator);
		// 	if (InstigatorPawn != none)
		// 	{
		// 		InstigatorPawn.PlayWeaponSoundEvent(AmbientSoundPlayEvent);
		// 	}
		// }
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

	if (FirePSC != none)
	{
		FirePSC.SetFOV(NewFOV);
	}
}

simulated state Inactive
{
	// when dropped, destroyed, etc, play the stop on the persistent sound
	simulated event BeginState(Name PreviousStateName)
	{
		// local KFPawn InstigatorPawn;

		super.BeginState(PreviousStateName);

		if (FirePSC != none)
		{
			FirePSC.DeactivateSystem();
		}

		IdleLight.SetEnabled(false);

		// if (Instigator != none)
		// {
		// 	InstigatorPawn = KFPawn(Instigator);
		// 	if (InstigatorPawn != none)
		// 	{
		// 		InstigatorPawn.PlayWeaponSoundEvent(AmbientSoundStopEvent);
		// 	}
		// }
	}
}

// Returns trader filter index based on weapon type
static simulated event EFilterTypeUI GetTraderFilter()
{
	// return FT_Projectile;
	return FT_Explosive;
}

/*
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
*/

defaultproperties
{
	// Zooming/Position
	PlayerViewOffset=(X=2,Y=0,Z=0)

	// Content
	PackageKey="Inferno"
	FirstPersonMeshName="WEP_Inferno_MESH.Wep_1stP_Inferno_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_Zweihander_ANIM.Wep_1stP_Zweihander_Anim"
	PickupMeshName="WEP_Inferno_MESH.Wep_Inferno_Pickup"
	AttachmentArchetypeName="WEP_Inferno_ARCH.WEP_Inferno_3P"

	Begin Object Name=MeleeHelper_0
		MaxHitRange=240
		// Override automatic hitbox creation (advanced)
		HitboxChain.Add((BoneOffset=(X=+3,Z=190)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=170)))
		HitboxChain.Add((BoneOffset=(X=+3,Z=150)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=130)))
		HitboxChain.Add((BoneOffset=(X=+3,Z=110)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=90)))
		HitboxChain.Add((BoneOffset=(X=+3,Z=70)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=50)))
		HitboxChain.Add((BoneOffset=(X=+3,Z=30)))
		HitboxChain.Add((BoneOffset=(Z=10)))
		WorldImpactEffects=KFImpactEffectInfo'FX_Impacts_ARCH.Bladed_melee_impact'
		MeleeImpactCamShakeScale=0.04f //0.5
		// modified combo sequences
		ChainSequence_F=(DIR_ForwardRight, DIR_ForwardLeft, DIR_ForwardRight, DIR_ForwardLeft)
		ChainSequence_B=(DIR_BackwardLeft, DIR_BackwardRight, DIR_BackwardLeft, DIR_ForwardRight, DIR_Left, DIR_Right, DIR_Left)
		ChainSequence_L=(DIR_Right, DIR_Left, DIR_ForwardRight, DIR_ForwardLeft, DIR_Right, DIR_Left)
		ChainSequence_R=(DIR_Left, DIR_Right, DIR_ForwardLeft, DIR_ForwardRight, DIR_Left, DIR_Right)
	End Object

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=245,G=190,B=140,A=255)
		Brightness=0.5f
		Radius=400.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	ExplosionEffect=ParticleSystem'DTest_EMIT.FX_500kg_ExplosionD'

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=40 //200
        DamageRadius=400 //800
		DamageFalloffExponent=0.5f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_RPG7'

		MomentumTransferScale=10000
		bAlwaysFullDamage=true
		bDoCylinderCheck=true

		// Damage Effects
		KnockDownStrength=150
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionSound=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Explosion'
		ExplosionEffects=KFImpactEffectInfo'WEP_Saiga12_ARCH.WEP_Saiga12_Impacts'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.3

		bIgnoreInstigator=true
		ActorClassToIgnoreForDamage=class'KFPawn_Human'

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=150
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	LightExplosionTemplate=ExploTemplate0

	Begin Object Class=KFGameExplosion Name=ExploTemplate1
		Damage=90 //85
        DamageRadius=400 //800
		DamageFalloffExponent=0.5f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_RPG7'

		MomentumTransferScale=10000
		bAlwaysFullDamage=true
		bDoCylinderCheck=true

		// Damage Effects
		KnockDownStrength=150
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionSound=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Explosion'
		ExplosionEffects=KFImpactEffectInfo'WEP_Saiga12_ARCH.WEP_Saiga12_Impacts'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.3

		bIgnoreInstigator=true
		ActorClassToIgnoreForDamage=class'KFPawn_Human'

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=150
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	HeavyExplosionTemplate=ExploTemplate1

	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Slashing_Inferno_Light'
	InstantHitMomentum(DEFAULT_FIREMODE)=30000.f
	InstantHitDamage(DEFAULT_FIREMODE)=95 //100

	// FiringStatesArray(HEAVY_ATK_FIREMODE)=SwordThrowAttackState
	// WeaponFireTypes(HEAVY_ATK_FIREMODE)=EWFT_Custom
	// WeaponProjectiles(HEAVY_ATK_FIREMODE)=class'KFProj_Rocket_Inferno'
	InstantHitDamageTypes(HEAVY_ATK_FIREMODE)=class'KFDT_Slashing_Inferno_Heavy'
	// FireInterval(HEAVY_ATK_FIREMODE)=0.15
	InstantHitMomentum(HEAVY_ATK_FIREMODE)=30000.f
	InstantHitDamage(HEAVY_ATK_FIREMODE)=205 //225
	// NumPellets(HEAVY_ATK_FIREMODE)=1
	// Spread(HEAVY_ATK_FIREMODE)=0

	// SwordThrowAttackAnim=Atk_F

	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Piercing_Inferno_Stab'
	InstantHitDamage(BASH_FIREMODE)=80 //85

	// melee blocking ?
	FiringStatesArray(CUSTOM_FIREMODE)=UltimateAttackState
	WeaponFireTypes(CUSTOM_FIREMODE)=EWFT_Custom
	WeaponProjectiles(CUSTOM_FIREMODE)=class'KFProj_Rocket_Inferno'
	InstantHitDamageTypes(CUSTOM_FIREMODE)=class'KFDT_Slashing_IonThrusterSpecial'
	InstantHitDamage(CUSTOM_FIREMODE)=80
	NumPellets(CUSTOM_FIREMODE)=4
	Spread(CUSTOM_FIREMODE)=1.25

	MaxTargetAngle=30 //20

	UltimateCharge=0.0f
	MaxUltimateCharge=100.0f;

	UltimateChargePerHit(DEFAULT_FIREMODE)=10.0f
	UltimateChargePerHit(BASH_FIREMODE)=7.0f
	UltimateChargePerHit(HEAVY_ATK_FIREMODE)=15.0f
	UltimateChargePerHit(CUSTOM_FIREMODE)=0.0f
	UltimateChargePerBlock=4.0f
	UltimateChargePerParry=45 //15 10

	UltimateAttackAnim=Brace_In

	// NumOfGrenades=4

	// Create all these particle system components off the bat so that the tick group can be set
	// fixes issue where the particle systems get offset during animations
/*
	Begin Object Class=KFParticleSystemComponent Name=ChargedParticleSystem
		TickGroup=TG_PostUpdateWork
	End Object
	ChargedPSC=ChargedParticleSystem
	ChargedEffect=ParticleSystem'WEP_Ion_Sword_EMIT.FX_ION_Charged_Ring_01'
*/

	// Explosion settings.  Using archetype so that clients can serialize the content
	// without loading the 1st person weapon content (avoid 'Begin Object')!
	// ExplosionActorClass=class'KFExplosionActorReplicated' // ignores instagator
	// ExplosionTemplate=KFGameExplosion'WEP_Pulverizer_ARCH.Wep_Pulverizer_Explosion' //plays explosion and sound
	// BlastSpawnOffset=10.f

	// Create all these particle system components off the bat so that the tick group can be set
	// fixes issue where the particle systems get offset during animations
	Begin Object Class=KFParticleSystemComponent Name=BasePSC0
		TickGroup=TG_PostUpdateWork
	End Object
	FirePSC=BasePSC0
	FireFXTemplate=ParticleSystem'DTest_EMIT.FX_Inferno_FireFX'

	// Inventory
	GroupPriority=21 // funny number
	InventorySize=7 //6
	WeaponSelectTexture=Texture2D'WEP_Inferno_MAT.UI_WeaponSelect_Inferno'
	AssociatedPerkClasses(0)=class'KFPerk_Berserker'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DTest' // Loot beam fx (no offset)

	// Block Sounds
	BlockSound=AkEvent'WW_WEP_Bullet_Impacts.Play_Block_MEL_Katana'
	ParrySound=AkEvent'WW_WEP_Bullet_Impacts.Play_Parry_Metal'

	ParryDamageMitigationPercent=0.4
	BlockDamageMitigation=0.5
	ParryStrength=5

    Begin Object Class=PointLightComponent Name=IdlePointLight
		LightColor=(R=250,G=150,B=85,A=255)
		Brightness=1.5f //0.125f
		FalloffExponent=4.f
		Radius=250.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=TRUE
		bCastPerObjectShadows=false
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object
	IdleLight=IdlePointLight
	LightAttachBone=FireFX

	//Ambient Sounds
    // AmbientSoundPlayEvent=AkEvent'WEP_Inferno_SND.Play_SchattenFreestyle_Loop_1P'
    // AmbientSoundStopEvent=AkEvent'WEP_Inferno_SND.Stop_SchattenFreestyle_Loop_1P'

	DistortTrailParticle=ParticleSystem'DTest_EMIT.FX_Trail_Inferno'
	WhiteTrailParticle=ParticleSystem'DTest_EMIT.FX_Trail_Inferno'
	BlueTrailParticle=ParticleSystem'DTest_EMIT.FX_Trail_Inferno'
	RedTrailParticle=ParticleSystem'DTest_EMIT.FX_Trail_Inferno'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.2f), (Stat=EWUS_Damage1, Scale=1.2f), (Stat=EWUS_Damage2, Scale=1.2f), (Stat=EWUS_Weight, Add=1)))
}