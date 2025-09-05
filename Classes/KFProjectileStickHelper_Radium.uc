class KFProjectileStickHelper_Radium extends KFProjectileStickHelper;

simulated function TryStick(vector HitNormal, optional vector HitLocation, optional Actor HitActor)
{
	local TraceHitInfo HitInfo;

	if (Instigator == None || !Instigator.IsLocallyControlled() || (Physics == PHYS_None && StuckToActor != none))
	{
		return;
	}

	if (HitActor != none && (HitActor == StuckToActor || HitActor == PinPawn))
	{
		return;
	}

	GetImpactInfo(Velocity, HitLocation, HitNormal, HitInfo);

	if (HitInfo.HitComponent != none && GetImpactResult(HitActor, HitInfo.HitComponent))
	{
		
		Stick(HitActor, HitLocation, HitNormal, HitInfo);

		if( WorldInfo.NetMode != NM_DedicatedServer )
		{
			`ImpactEffectManager.PlayImpactEffects(HitLocation, Instigator,, KFProj_Bolt_Radium(Outer).ImpactEffects);
		}
	}
}

/** Stops movement of projectile and calculates orientation to surface */
simulated function Stick(Actor HitActor, vector HitLocation, vector HitNormal, const out TraceHitInfo HitInfo)
{
	local int BoneIdx;

	local KFPawn_Monster HitMonster;
	local array<ImpactInfo> HitZoneImpactList;
	local vector StartTrace, EndTrace, Direction, ClosestBoneLocation;
	local name BoneName;

	BoneName = HitInfo.BoneName;

	HitMonster = KFPawn_Monster(HitActor);
	if (HitMonster != none)
	{
		// get injury hit zone
		StartTrace = HitLocation;
		Direction = Normal(Velocity);
		EndTrace = StartTrace + Direction * (HitMonster.CylinderComponent.CollisionRadius * 6.0);
		TraceProjHitZones(HitMonster, EndTrace, StartTrace, HitZoneImpactList);

		if (BoneName == '')
		{
			// get the best bone to attach to
			ClosestBoneLocation = HitMonster.Mesh.GetClosestCollidingBoneLocation(HitLocation, true, false);
			BoneName = HitMonster.Mesh.FindClosestBone(ClosestBoneLocation, ClosestBoneLocation);
		}

		// do impact damage
		if (KFWeapon(Owner) != none)
		{
			HitZoneImpactList[0].RayDir = Normal(EndTrace - StartTrace); // add a raydir here since TraceProjHitZones doesn't fill this out (so certain afflictions apply)
			KFWeapon(Owner).HandleProjectileImpact(WeaponFireMode, HitZoneImpactList[0], PenetrationPower);
		}
	}

    if (!IsZero(HitLocation))
    {
    	SetLocation(HitLocation);
    }

	SetStickOrientation(HitNormal);

	BoneIdx = INDEX_NONE;

	if (BoneName != '')
	{
		BoneIdx = GetBoneIndexFromActor(HitActor, BoneName);
	}

    StickToActor(HitActor, HitInfo.HitComponent, BoneIdx, true);

    if (Role < ROLE_Authority)
	{
		Outer.ServerStick(HitActor, BoneIdx, StuckToLocation, StuckToRotation);
	}

	if (WorldInfo.NetMode != NM_DedicatedServer && StickAkEvent != none)
	{
		PlaySoundBase(StickAkEvent);
	}
}

/** Changes the base of the charge to the stick actor and sets its relative loc/rot */
simulated function StickToActor(Actor StickTo, PrimitiveComponent HitComp, int BoneIdx, optional bool bCalculateRelativeLocRot)
{
	local SkeletalMeshComponent SkelMeshComp;
	local Name BoneName;

	local vector RelStuckToLocation;
	local rotator RelStuckToRotation;

	local KFPawn StickToPawn;

	StickToPawn = KFPawn(StickTo);

	if (bCanPin && (StickToPawn == none || StickToPawn.bCanBePinned))
	{
		// if StickTo pawn is dead, pin it and keep flying
		if (Role == ROLE_Authority)
		{
			if (StickToPawn != none && !StickToPawn.IsAliveAndWell())
			{
				if (PinPawn == none)
				{
					Pin(StickTo, BoneIdx);
				}

				return;
			}
		}

		if (WorldInfo.NetMode != NM_DedicatedServer && PinPawn != none)
		{
			if (StickToPawn == none)
			{
				// Pin pinned pawn to StickTo actor
				//PinPawn.Mesh.RetardRBLinearVelocity(vector(Rotation), 0.75);
				PinPawn.Mesh.SetRBPosition(Location, PinBoneName);

				PinConstraint = Spawn(class'RB_ConstraintActorSpawnable',,,Location);
				PinConstraint.InitConstraint(PinPawn, none, PinBoneName, '');
			}

			PinPawn = none;
		}
	}

	SetPhysics(PHYS_None);

	PrevStuckToActor = StuckToActor;
	StuckToActor = StickTo;
	StuckToBoneIdx = BoneIdx;

	// if we found a skel mesh, set our base to it and set relative loc/rot
	if (BoneIdx != INDEX_NONE)
	{
		SkelMeshComp = SkeletalMeshComponent(HitComp);

		BoneName = SkelMeshComp.GetBoneName(BoneIdx);

		if (bCalculateRelativeLocRot)
		{
			StuckToLocation = Location;
			StuckToRotation = Rotation;
		}

		SkelMeshComp.TransformToBoneSpace(BoneName, StuckToLocation, StuckToRotation, RelStuckToLocation, RelStuckToRotation);

		SetBase(StickTo,, SkelMeshComp, BoneName);
		SetRelativeLocation(RelStuckToLocation);
		SetRelativeRotation(RelStuckToRotation);

	}
	// otherwise, just set our base
	else
	{
		if (bCalculateRelativeLocRot)
		{
			// set replicated loc/rot
			StuckToLocation = Location;
			StuckToRotation = Rotation;
		}
		else
		{
			// set loc/rot to replicated loc/rot
			SetLocation(StuckToLocation);
			SetRotation(StuckToRotation);
		}

		SetBase(StickTo);
	}

	KFProj_Bolt_Radium(Outer).NotifyStick();
}

simulated function UnStick()
{
	PrevStuckToActor = StuckToActor;

	StuckToActor = none;
	StuckToBoneIdx = INDEX_NONE;

	StuckToLocation = vect(0,0,0);
	StuckToRotation = rot(0,0,0);
	if (!PrevStuckToActor.bTearOff)
	{
		SetBase(none);
		SetPhysics(default.Physics);	
	}
}

/** Returns appropriate interaction with HitActor (stick or ignore, for now. add bounce later?) */
simulated function bool GetImpactResult(Actor HitActor, PrimitiveComponent HitComp)
{
	local StaticMeshComponent StaticMeshComp;

	StaticMeshComp = StaticMeshComponent(HitComp);
	if (StaticMeshComp != none)
	{
		return true;
	}

	if (super.GetImpactResult(HitActor, HitComp))
	{
		return true;
	}

	// Check if it is water
	return (InterpActor(HitActor) != none && InterpActor(HitActor).bDestroyProjectilesOnEncroach);
}

defaultproperties
{

}