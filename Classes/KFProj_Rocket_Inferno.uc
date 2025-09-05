class KFProj_Rocket_Inferno extends KFProj_BallisticExplosive
	hidedropdown;

// var float FinalSpeed;
// var float ProjectileTime;

// Number of lingering fires/fireballs to spawn
var() int NumResidualFlames;
var class<KFProjectile> ResidualFlameProjClass;

// Our intended target actor
var private KFPawn LockedTarget;
// How much 'stickyness' when seeking toward our target. Determines how accurate rocket is
var const float SeekStrength;

replication
{
	if( bNetInitial )
		LockedTarget; //FinalSpeed
}

/*
simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	SetPhysics(PHYS_Falling);

	if( Role == ROLE_Authority )
	{
	   SetTimer(ProjectileTime, false, 'ProjectileTimer');
	}
}

function ProjectileTimer()
{
	SetPhysics(PHYS_Projectile);

	Speed = FinalSpeed;
	FinalSpeed = 10000;
}
*/

function SetLockedTarget( KFPawn NewTarget )
{
	LockedTarget = NewTarget;
}

simulated event Tick( float DeltaTime )
{
	local vector TargetImpactPos, DirToTarget;

	super.Tick( DeltaTime );

	// Skip the first frame, then start seeking
	if( !bHasExploded
		&& LockedTarget != none
		&& Physics == PHYS_Projectile
		&& Velocity != vect(0,0,0)
		&& LockedTarget.IsAliveAndWell()
		&& `TimeSince(CreationTime) > 0.16f ) //0.03
	{
		// Grab our desired relative impact location from the weapon class
		TargetImpactPos = class'KFWeap_Inferno'.static.GetLockedTargetLoc( LockedTarget );

		// Seek towards target
		Speed = VSize( Velocity );
		DirToTarget = Normal( TargetImpactPos - Location );
		Velocity = Normal( Velocity + (DirToTarget * (SeekStrength * DeltaTime)) ) * Speed;

		// Aim rotation towards velocity every frame
		SetRotation( rotator(Velocity) );
	}
}

// Overridden to spawn residual flames
simulated function Explode(vector HitLocation, vector HitNormal)
{
	local vector HitVelocity;
	// local KFPerk InstigatorPerk;

	// local rotator FlareRot;
	
	// velocity is set to 0 in Explode, so cache it here
	HitVelocity = Velocity;

    super.Explode( HitLocation, HitNormal );

    if( Role < Role_Authority )
    {
    	return;
    }

    SpawnResidualFlames( HitLocation, HitNormal, HitVelocity );

    // spawn flare for flarotov
    // if( Instigator != none && Instigator.Controller != none )
    // {
    // 	InstigatorPerk = KFPlayerController(Instigator.Controller).GetPerk();
    // 	if( InstigatorPerk.IsFlarotovActive() )
    // 	{
    // 		FlareRot = rotator( HitVelocity );
    // 		FlareRot.Pitch = 0;
    // 		Spawn( class'KFProj_MolotovFlare', self,, HitLocation + HitNormal * 20, FlareRot );
    // 	}
    // }
}

// Spawn several projectiles that explode and linger on impact
function SpawnResidualFlames( vector HitLocation, vector HitNormal, vector HitVelocity )
{
	local int i;
	local vector HitVelDir;
	local float HitVelMag;
	local vector SpawnLoc, SpawnVel;

	HitVelMag = VSize( HitVelocity );
	HitVelDir = Normal( HitVelocity );

	SpawnLoc = HitLocation + (HitNormal * 10.f);

	// spawn random lingering fires (rather, projectiles that cause little fires)
	for( i = 0; i < NumResidualFlames; ++i )
	{
		SpawnVel = CalculateResidualFlameVelocity( HitNormal, HitVelDir, HitVelMag );
		SpawnResidualFlame( ResidualFlameProjClass, SpawnLoc, SpawnVel );
	}

	// spawn one where we hit to a flame
	// (we don't give this class a lingering flame because it can hit zeds, and if they die the lingering flame could be left floating)
	SpawnResidualFlame( ResidualFlameProjClass, HitLocation, HitVelocity/3.f );
}

simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	ExplosionTemplate.bIgnoreInstigator = true;
}

defaultproperties
{
	Physics=PHYS_Projectile
	Speed=3000 //2000
	MaxSpeed=3000
	TossZ=0
	GravityScale=1.0
    MomentumTransfer=50000.0f
	ArmDistSquared=0
    
    // ProjectileTime=0.4

    SeekStrength=32000.0f //28000.0f

	bWarnAIWhenFired=true

	bCanDisintegrate=false

	ProjFlightTemplate=ParticleSystem'DTest_EMIT.FX_Inferno_Tracer'
	ProjFlightTemplateZedTime=ParticleSystem'DTest_EMIT.FX_Inferno_Tracer'

	ResidualFlameProjClass=class'KFProj_MolotovSplash' //KFProj_InfernoRocketSplash
	NumResidualFlames=4

	AmbientSoundPlayEvent=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Rocket_LP'
  	AmbientSoundStopEvent=AkEvent'WW_WEP_ZEDMKIII.Stop_WEP_ZEDMKIII_Rocket_LP'

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
		Damage=80 //200
		DamageRadius=300
		DamageFalloffExponent=2
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_ZedMKIII'

		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_Inferno_ARCH.Inferno_Explosion'
		ExplosionSound=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Explosion'

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