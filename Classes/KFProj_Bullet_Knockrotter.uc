class KFProj_Bullet_Knockrotter extends KFProj_Bullet;

// Our intended target actor
var private KFPawn LockedTarget;
// How much 'stickyness' when seeking toward our target. Determines how accurate rocket is
var const float SeekStrength;

replication
{
	if( bNetInitial )
		LockedTarget;
}

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
		&& `TimeSince(CreationTime) > 0.01f ) //0.03
	{
		// Grab our desired relative impact location from the weapon class
		TargetImpactPos = class'KFWeap_Knockrotter'.static.GetLockedTargetLoc( LockedTarget );

		// Seek towards target
		Speed = VSize( Velocity );
		DirToTarget = Normal( TargetImpactPos - Location );
		Velocity = Normal( Velocity + (DirToTarget * (SeekStrength * DeltaTime)) ) * Speed;

		// Aim rotation towards velocity every frame
		SetRotation( rotator(Velocity) );
	}
}

defaultproperties
{
	Speed=6500 //10000
	MaxSpeed=6500

	TouchTimeThreshhold=0.0

    SeekStrength=428000.0f //528000.0f

	Begin Object Name=CollisionCylinder
		CollisionRadius=6
		CollisionHeight=6
	End Object
	ExtraLineCollisionOffsets.Add((Y=-4))
	ExtraLineCollisionOffsets.Add((Y=4))
	ExtraLineCollisionOffsets.Add((Z=-4))
	ExtraLineCollisionOffsets.Add((Z=4))
	// Since we're still using an extent cylinder, we need a line at 0
	ExtraLineCollisionOffsets.Add(())
	
	ProjFlightTemplate=ParticleSystem'DTest_EMIT.FX_Knockrotter_Tracer'
	ProjFlightTemplateZedTime=ParticleSystem'DTest_EMIT.FX_Knockrotter_Tracer'

	ImpactEffects=KFImpactEffectInfo'WEP_Knockrotter_ARCH.Knockrotter_Impact'
}