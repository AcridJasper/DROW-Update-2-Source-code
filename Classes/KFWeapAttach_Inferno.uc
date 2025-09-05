class KFWeapAttach_Inferno extends KFWeapAttach_SprayBase; //KFWeaponAttachment;

// var transient KFPlayerController KFPC;

// var float F;

/** Name of the special anim used for the heavy attack */
// var name SwordThrowAttackAnim;
/** Name of the special anim used for the heavy attack while crouching */
// var name SwordThrowAttackAnimCrouch;

/** Name of the special anim used for the ultimate attack */
var name UltimateAttackAnim;
/** Name of the special anim used for the ultimate attack while crouching */
var name UltimateAttackAnimCrouch;

// Effect that happens while charging up the beam
var transient ParticleSystemComponent FirePSC;
var const ParticleSystem FireEffect;

// var ParticleSystem ObEffect;

// var transient ParticleSystemComponent ShieldPSC;
// var ParticleSystem ShieldEffect;



// var ParticleSystem InvulnerableShieldFX;
// var ParticleSystemComponent InvulnerableShieldPSC;
// var name ShieldSocketName;

// var repnotify bool bShieldUp;

// replication
// {
//     if (bNetDirty)
//         bShieldUp;
// }

// simulated event ReplicatedEvent(name VarName)
// {
//     switch (VarName)
//     {
// 	case nameof(bShieldUp):
// 		// SetShieldUp(bShieldUp);
// 		break;
//     default:
//         super.ReplicatedEvent(VarName);
//     };
// }



/*
var transient ParticleSystemComponent ChargePSC;
var const ParticleSystem ChargeEffect;

const ChargeSocketName = 'RW_Weapon';

function OnSpecialEvent(int Arg)
{
	if (Arg <= 2)
	{
		// UpdateAdjustCharge(Arg == 2);
		ToggleChargeFX(Arg == 2);
	}
}
*/

//simulated function UpdateAdjustCharge()
// {
// 	ToggleChargeFX(true);
// }

/*
simulated function ToggleChargeFX(bool bEnable)
{
	if (bEnable)
	{
		ChargePSC.DeactivateSystem();
		ChargePSC.SetTemplate(ChargeEffect);
		ChargePSC.ActivateSystem();
	}
	else
	{
		ChargePSC.DeactivateSystem();
	}
}
*/

/*
simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	if (Role == ROLE_Authority)
	{
		KFPC = KFPlayerController(Instigator.Controller);
		// Pawn = KFPawn(Outer);
		
		// TestSpawnGrenade();
		SpawnAIVss();
	}
}
*/

// function TestSpawnGrenade()
// {
// 	local class<KFPawn_Monster> MonsterClass;
//     local vector SpawnLoc;
//     local rotator SpawnRot;
//     local KFPawn KFP;

// 	if (Role == ROLE_Authority)
// 	{
//     	MonsterClass = class<KFPawn_Monster>(DynamicLoadObject("KFGameContent.KFPawn_ZedFleshPound_Versus", class'Class'));

//     	if( MonsterClass != none )
//     	{
//     	    SpawnLoc = Location;
	
//     	    SpawnLoc += 200.f * vector(Rotation) + vect(0,0,1) * 15.f;
//     	    SpawnRot.Yaw = Rotation.Yaw + 32768;
	
//     	    KFP = Spawn( MonsterClass,,, SpawnLoc, SpawnRot,, false );
//     	    if( KFP != none )
//     	    {
//     	    	// if(Pawn != none)
//     	    	// {
//     	        // 	KFP.Destroy();
//     	    	// }
	
//     	        // if( KFP.Controller != none )
//     	        // {
//     	        //     KFP.Controller.Destroy();
//     	        // }
//     	        KFGameInfo(WorldInfo.Game).SetTeam( KFPlayerController(Outer), KFGameInfo(WorldInfo.Game).Teams[0] );
//     	        KFPC.Possess( KFP, false );
//     	        KFPC.ServerCamera( 'ThirdPerson' );
//     	        KFP.SetPhysics( PHYS_Falling );
//     	    }
//     	}
// 	}
// }

/*
function SpawnAIVss(optional float Distance = 500.f)
{
    local class<KFPawn_Monster> MonsterClass;
    local vector SpawnLoc;
    local rotator SpawnRot;
	// local KFPlayerController KFPC;
    local KFPawn KFP;

    MonsterClass = class<KFPawn_Monster>(DynamicLoadObject("KFGameContent.KFPawn_ZedFleshPound_Versus", class'Class'));

    if( MonsterClass != none )
    {
        SpawnLoc = Location;

        SpawnLoc += Distance * vector(Rotation) + vect(0,0,1) * 15.f;
        SpawnRot.Yaw = Rotation.Yaw + 32768;

        KFP = Spawn( MonsterClass,,, SpawnLoc, SpawnRot,, false );
        if( KFP != none )
        {
            KFP.SetPhysics( PHYS_Falling );
            if( KFPC != none )
            {
    	        KFGameInfo(WorldInfo.Game).SetTeam( KFPlayerController(Outer), KFGameInfo(WorldInfo.Game).Teams[0] );
                KFPC.Possess( KFP, false );
    	    	KFPC.ServerCamera( 'ThirdPerson' );
            }
        }
    }
}
*/

/** Play a melee attack animation */
simulated function float PlayMeleeAtkAnim(EWeaponState NewWeaponState, KFPawn P)
{
	if (P.IsFirstPerson())
	{
		return 0.0f;
	}

	// custom firemode, special attack
	if (Instigator != none && Instigator.FiringMode == 6)
	{
		if (P.bIsCrouched)
		{
			return PlayCharacterMeshAnim(P, UltimateAttackAnimCrouch);
		}
		else
		{
			return PlayCharacterMeshAnim(P, UltimateAttackAnim);
		}
	}
/*
	else if (Instigator != none && Instigator.FiringMode == 5)
	{
		if (P.bIsCrouched)
		{
			return PlayCharacterMeshAnim(P, SwordThrowAttackAnimCrouch);
		}
		else
		{
			return PlayCharacterMeshAnim(P, SwordThrowAttackAnim);
		}
	}
*/
	
	return super.PlayMeleeAtkAnim(NewWeaponState, P);
}

// Attach weapon to owner's skeletal mesh
simulated function AttachTo(KFPawn P)
{
    Super.AttachTo(P);

	// P.CylinderComponent.SetCylinderSize( P.Default.CylinderComponent.CollisionRadius * F, P.Default.CylinderComponent.CollisionHeight * F );
	// P.SetDrawScale(F);
	// P.SetLocation(P.Location);

	// if (ChargePSC != none)
	// {
	// 	P.Mesh.AttachComponentToSocket(ChargePSC, ChargeSocketName);
	// }


	// if( WeapMesh != None )
	// {
	// 	if (WorldInfo.NetMode != NM_DedicatedServer)
	// 	{
	// 		if (bShieldUp)
	// 		{
	// 			InvulnerableShieldPSC = P.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(InvulnerableShieldFX, P.Mesh, ShieldSocketName, true);
	// 			InvulnerableShieldPSC.SetAbsolute(false, true, true);
	// 		}
	// 		else
	// 		{
	// 			InvulnerableShieldPSC.DeactivateSystem();
	// 			InvulnerableShieldPSC = none;
	// 			bShieldUp = false;

	// 			InvulnerableShieldPSC.SetFloatParameter( name("DeleteLifeTime"), ????????? );
	// 		}
	// 	}
	// }

	
/*
	if ( ShieldPSC == None )
	{
		ShieldPSC = new(self) class'ParticleSystemComponent';

		if (WeapMesh != none)
		{
		    P.Mesh.AttachComponentToSocket( ShieldPSC, 'Hips' );
		}
		else
		{
			AttachComponent(ShieldPSC);
		}
	}
	else
	{
		ShieldPSC.ActivateSystem();
	}

	if(ShieldPSC != none)
	{
		ShieldPSC.SetTemplate(ShieldEffect);
		ShieldPSC.SetAbsolute(false, true, true);
	}
*/


	// setup and play the beam charge particle system
	if (FirePSC == none)
	{
		FirePSC = new(self) class'ParticleSystemComponent';

		if (WeapMesh != none)
		{
			WeapMesh.AttachComponentToSocket(FirePSC, 'FireFX');
		}
		else
		{
			AttachComponent(FirePSC);
		}
	}
	else
	{
		FirePSC.ActivateSystem();
	}

	if (FirePSC != none)
	{
		FirePSC.SetTemplate(FireEffect);
		// FirePSC.SetAbsolute(false, false, false);
		// FirePSC.SetTemplate(FireEffect);
	}
}

simulated function DetachFrom(KFPawn P)
{
	if (FirePSC != none)
	{
		FirePSC.DeactivateSystem();
	}

	// if (ShieldPSC == none)
	// {
	// 	ShieldPSC.DeactivateSystem();
	// }

	// if (InvulnerableShieldPSC == none)
	// {
	// 	InvulnerableShieldPSC.DeactivateSystem();
	// 	InvulnerableShieldPSC = none;
	// 	bShieldUp = false;
	// }

	// F=1.0

    Super.DetachFrom(P);
}

defaultproperties
{
	// SwordThrowAttackAnim=Atk_F
	// SwordThrowAttackAnimCrouch=Atk_F_CH

	UltimateAttackAnim=Brace_In
	UltimateAttackAnimCrouch=Brace_In_CH

	FireEffect=ParticleSystem'DTest_EMIT.FX_Inferno_FireFX'
	// ChargeEffect=ParticleSystem'WEP_Ion_Sword_EMIT.FX_ION_Charged_Ring_01'
	
	// F=2.5
	// ObEffect=ParticleSystem'FX_Gameplay_EMIT.FX_Char_PowerUp_HellishRage'


	// ShieldEffect=ParticleSystem'FX_Gameplay_EMIT.FX_Char_PowerUp_HellishRage'

	// bShieldUp=true
    // InvulnerableShieldFX=ParticleSystem'ZED_Matriarch_EMIT.FX_Matriarch_Shield'
    // ShieldSocketName=Root //Hips

	Begin Object Class=PointLightComponent Name=PilotPointLight0
		LightColor=(R=250,G=150,B=85,A=255)
		Brightness=1.5f
		FalloffExponent=4.f
		Radius=250.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=TRUE
		bCastPerObjectShadows=false
		bEnabled=true
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	PilotLights(0)=(Light=PilotPointLight0,LightAttachBone=FireFX)
}