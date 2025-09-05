class KFProj_Bolt_Radium extends KFProjectile; //KFProj_BallisticExplosive

// Fuze time when sticked
var() float SecondsBeforeDetonation;
var() bool bIsProjActive;

// Explosion actor class to use for ground fire
var const protected class<KFExplosionActorLingering> GroundExplosionActorClass;
// Explosion template to use for ground fire
var KFGameExplosion GroundExplosionTemplate;

// How long the ground fire should stick around
var const protected float EffectDuration;
// How often, in seconds, we should apply burn
var const protected float DamageInterval;

var bool bSpawnGroundFire;

/** Our intended target actor */
// var private KFPawn LockedTarget;
/** How much 'stickyness' when seeking toward our target. Determines how accurate rocket is */
// var const float SeekStrength;

replication
{
	if( bNetInitial )
		/*LockedTarget,*/ bSpawnGroundFire;
}

simulated function NotifyStick()
{
    SetTimer(SecondsBeforeDetonation, false, nameof(Timer_Detonate));
}

function Timer_Detonate()
{
	Detonate();
}

// Called when the owning instigator controller has left a game
simulated function OnInstigatorControllerLeft()
{
	if( WorldInfo.NetMode != NM_Client )
	{
		SetTimer( 1.f + Rand(5) + fRand(), false, nameOf(Timer_Detonate) ); //Destory
	}
}

function Detonate()
{
	local vector ExplosionNormal;

	StickHelper.UnPin();

	ExplosionNormal = vect(0,0,1) >> Rotation;
	Explode(Location, ExplosionNormal);
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	StickHelper.UnPin();
	super.Explode(HitLocation, HitNormal);
}

// Trace down and get the location to spawn the explosion effects and decal
simulated function GetExplodeEffectLocation(out vector HitLocation, out vector HitRotation, out Actor HitActor)
{
    local vector EffectStartTrace, EffectEndTrace;
	local TraceHitInfo HitInfo;

	EffectStartTrace = Location + vect(0,0,1) * 4.f;
	EffectEndTrace = EffectStartTrace - vect(0,0,1) * 32.f;

    // Find where to put the decal
	HitActor = Trace(HitLocation, HitRotation, EffectEndTrace, EffectStartTrace, false,, HitInfo, TRACEFLAG_Bullet);

	// If the locations are zero (probably because this exploded in the air) set defaults
    if (IsZero(HitLocation))
    {
        HitLocation = Location;
    }

	if (IsZero(HitRotation))
    {
        HitRotation = vect(0,0,1);
    }
}

simulated function SyncOriginalLocation()
{
	local Actor HitActor;
	local vector HitLocation, HitNormal;
	local TraceHitInfo HitInfo;

	if (Role < ROLE_Authority && Instigator != none && Instigator.IsLocallyControlled())
	{
		HitActor = Trace(HitLocation, HitNormal, OriginalLocation, Location,,, HitInfo, TRACEFLAG_Bullet);
		if (HitActor != none)
		{
			StickHelper.TryStick(HitNormal, HitLocation, HitActor);
		}
	}
}

/*
function SetLockedTarget( KFPawn NewTarget )
{
	LockedTarget = NewTarget;
}
*/

simulated event Tick( float DeltaTime )
{
	// local vector TargetImpactPos, DirToTarget;

	super.Tick(DeltaTime);

	StickHelper.Tick(DeltaTime);

    if (bIsProjActive)
    {
	    StickHelper.Tick(DeltaTime);
    }

	if (!IsZero(Velocity))
	{
		SetRelativeRotation(rotator(Velocity));
	}

/*
	// Skip the first frame, then start seeking
	if( !bHasExploded
		&& LockedTarget != none
		&& Physics == PHYS_Projectile
		&& Velocity != vect(0,0,0)
		&& LockedTarget.IsAliveAndWell()
		&& `TimeSince(CreationTime) > 0.03f )
	{
		// Grab our desired relative impact location from the weapon class
		TargetImpactPos = class'KFWeap_RocketLauncher_Seeker6'.static.GetLockedTargetLoc( LockedTarget );

		// Seek towards target
		Speed = VSize( Velocity );
		DirToTarget = Normal( TargetImpactPos - Location );
		Velocity = Normal( Velocity + (DirToTarget * (SeekStrength * DeltaTime)) ) * Speed;

		// Aim rotation towards velocity every frame
		SetRotation( rotator(Velocity) );
	}
*/
}

// Ground effect
simulated function PostBeginPlay()
{
	local KFWeap_Radium Cannon;

	if(Role == ROLE_Authority)
	{
		Cannon = KFWeap_Radium(Owner);
		if (Cannon != none)
		{
			bSpawnGroundFire = true;
		}
	}

	super.PostBeginPlay();
}

simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local KFExplosionActorLingering GFExplosionActor;
	local vector GroundExplosionHitNormal;

	if (bHasDisintegrated)
	{
		return;
	}

	if (!bHasExploded && bSpawnGroundFire)
	{
		GroundExplosionHitNormal = HitNormal;

		// Spawn our explosion and set up its parameters
		GFExplosionActor = Spawn(GroundExplosionActorClass, self, , HitLocation + (HitNormal * 20.f), rotator(HitNormal)); //1
		if (GFExplosionActor != None)
		{
			GFExplosionActor.Instigator = Instigator;
			GFExplosionActor.InstigatorController = InstigatorController;

			// These are needed for the decal tracing later in GameExplosionActor.Explode()
			GroundExplosionTemplate.HitLocation = HitLocation;
			GroundExplosionTemplate.HitNormal = GroundExplosionHitNormal;

			// Apply explosion direction
			if (GroundExplosionTemplate.bDirectionalExplosion)
			{
				GroundExplosionHitNormal = GetExplosionDirection(GroundExplosionHitNormal);
			}

			// Set our duration
			GFExplosionActor.MaxTime = EffectDuration;
			// Set our burn interval
			GFExplosionActor.Interval = DamageInterval;
			// Boom
			GFExplosionActor.Explode(GroundExplosionTemplate, GroundExplosionHitNormal);
		}
	}

	super.TriggerExplosion(HitLocation, HitNormal, HitActor);
}

simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	ExplosionTemplate.bIgnoreInstigator = true;
	GroundExplosionTemplate.bIgnoreInstigator = true;
}

defaultproperties
{
	Physics=PHYS_Projectile
    MaxSpeed=11000 //7500
	Speed=11000
	TossZ=0
	GravityScale=1.0
    // MomentumTransfer=40000
	LifeSpan=15 //7.0
	// PostExplosionLifetime=1

    // SeekStrength=928000.0f  // 128000.0f

	ProjFlightTemplate=ParticleSystem'DTest_EMIT.FX_Radium_Bolt'
	ProjFlightTemplateZedTime=ParticleSystem'DTest_EMIT.FX_Radium_Bolt'

    bCanDisintegrate=false
	// ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

    // ********************* General settings *********************
    
	bWarnAIWhenFired=true

    bCanBeDamaged=false
	bIgnoreFoliageTouch=true

	bBlockedByInstigator=false
	bAlwaysReplicateExplosion=true

	bNetTemporary=false
	NetPriority=5
	NetUpdateFrequency=200

	bNoReplicationToInstigator=false
	bUseClientSideHitDetection=true
	bUpdateSimulatedPosition=true
	bSyncToOriginalLocation=true
	bSyncToThirdPersonMuzzleLocation=true

    // ********************* Ground effect *********************

	// Ground effect
	EffectDuration=6.0f //13.0f
	DamageInterval=0.5f // 0.5
	GroundExplosionActorClass=class'KFExplosion_Radium'

	// Ground effect
	Begin Object Class=KFGameExplosion Name=ExploTemplate1
		Damage=40 //20
		DamageRadius=400 //500
		DamageFalloffExponent=1.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Toxic_DoT_Radium'

		MomentumTransferScale=0 //1
        bIgnoreInstigator=true
		// bDirectionalExplosion=true // directionl damage

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=0
		ExplosionEffects=KFImpactEffectInfo'wep_molotov_arch.Molotov_GroundFire' // ground effect is inside Class

		// Camera Shake
		CamShake=none
	End Object
	GroundExplosionTemplate=ExploTemplate1

    // ********************* Collisions *********************

    // bCollideActors=true
    bCollideComplex=true

	Begin Object Name=CollisionCylinder
		BlockNonZeroExtent=false
		// for siren scream
		CollideActors=true
	End Object

	// Begin Object Name=CollisionCylinder
	// 	CollisionRadius=1 //10
	// 	CollisionHeight=1 //10
	// 	BlockNonZeroExtent=true
	// 	// for siren scream
	// 	CollideActors=true
	// End Object
	// ExtraLineCollisionOffsets.Add((Y=-1)) //-10
 	// ExtraLineCollisionOffsets.Add((Y=1)) //10
  	// // Since we're still using an extent cylinder, we need a line at 0
  	// ExtraLineCollisionOffsets.Add(())

    // ********************* Sticking *********************

    SecondsBeforeDetonation=1.0f //5.0f
    bIsProjActive=true

	bCanStick=true
	bCanPin=true
	Begin Object Class=KFProjectileStickHelper_Radium Name=StickHelper0 //Class=KFProjectileStickHelper Name=StickHelper0
	End Object
	StickHelper=StickHelper0
	PinBoneIdx=INDEX_None

    // ********************* Explosion *********************

	ExplosionActorClass=class'KFExplosionActor'

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=4.f
		Radius=2000.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=190
		DamageRadius=550
		DamageFalloffExponent=1.0
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_Radium'

		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'wep_molotov_arch.Molotov_Explosion'
		ExplosionSound=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Explosion'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=500
		CamShakeFalloff=3.f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}