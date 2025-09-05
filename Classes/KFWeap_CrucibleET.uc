class KFWeap_CrucibleET extends KFWeap_MeleeBase;

// Particle system
var transient KFParticleSystemComponent ParticlePSC;
var const ParticleSystem ParticleFXTemplate;

// Equiping particle system
// var transient KFParticleSystemComponent EquipPSC;
// var const ParticleSystem EquipFXTemplate;

// Point light
var PointLightComponent IdleLight;
var Name LightAttachBone;

// Ambient Sounds
var AkEvent AmbientSoundPlayEvent;
var AkEvent	AmbientSoundStopEvent;

// Attack animrate mod
var transient bool bIsMur;
var const float MurAttackAnimRate;

simulated state WeaponEquipping
{
	simulated function BeginState(Name PreviousStateName)
	{
		local KFPawn InstigatorPawn;

		super.BeginState(PreviousStateName);

		ActivatePSC(ParticlePSC, ParticleFXTemplate, 'ParticleFX');

		// if( Role == ROLE_Authority )
		// {
		// 	SetTimer(0.9, false, nameof(Timer_ActivateEquipFX));
		// }

		if (MySkelMesh != none)
		{
			MySkelMesh.AttachComponentToSocket(IdleLight, LightAttachBone);
			IdleLight.SetEnabled(true);
		}
		
		if (Instigator != none)
		{
			InstigatorPawn = KFPawn(Instigator);
			if (InstigatorPawn != none)
			{
				InstigatorPawn.PlayWeaponSoundEvent(AmbientSoundPlayEvent);
			}
		}

    	NotifyServerMode(bIsMur);

	    if (WorldInfo.NetMode != NM_Client)
        {
            NotifyInitialState(bIsMur);
        }
	}
}

// function Timer_ActivateEquipFX()
// {
// 	ActivatePSC(EquipPSC, EquipFXTemplate, 'ParticleFX');
// }

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
		local KFPawn InstigatorPawn;

		Super.BeginState(PreviousStateName);

		if (ParticlePSC != none)
		{
			ParticlePSC.DeactivateSystem();
		}

		// if (EquipPSC != none)
		// {
		// 	EquipPSC.DeactivateSystem();
		// }

		IdleLight.SetEnabled(false);

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

simulated function ModifyMeleeAttackSpeed(out float InSpeed, optional int FireMode = DEFAULT_FIREMODE, optional int UpgradeIndex = INDEX_NONE, optional KFPerk CurrentPerk)
{
    Super.ModifyMeleeAttackSpeed(InSpeed, FireMode, UpgradeIndex, CurrentPerk);

    if (bIsMur)
    {
        InSpeed *= MurAttackAnimRate;
    }
}

// Should replicate to 3P to show the shield effects
simulated function NotifyInitialState(bool bMur)
{
	local KFPawn KFP;

	if (WorldInfo.NetMode != NM_Client)
	{
        `Log("NotifyInitialState: " $bMur);

		KFP = KFPawn(Instigator);
		KFP.OnWeaponSpecialAction(bMur ? 0 : 1);
	}
}

reliable server function NotifyServerMode(bool bMur)
{
    bIsMur = bMur;
}

defaultproperties
{
	// Zooming/Position
	PlayerViewOffset=(X=12,Y=0,Z=-7)

	// Content
	PackageKey="Crucible"
	FirstPersonMeshName="WEP_Crucible_MESH.Wep_1stP_CrucibleET_Rig"
	FirstPersonAnimSetNames(0)="WEP_Crucible_ARCH.CrucibleET_Anim_Master"
	PickupMeshName="WEP_Crucible_MESH.WEP_CrucibleET_Pickup"
	AttachmentArchetypeName="WEP_Crucible_ARCH.WEP_CrucibleET_3P"

	Begin Object Name=MeleeHelper_0
		MaxHitRange=220
		// Override automatic hitbox creation (advanced)
		HitboxChain.Add((BoneOffset=(X=+3,Z=220)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=200)))
		HitboxChain.Add((BoneOffset=(X=+3,Z=180)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=160)))
		HitboxChain.Add((BoneOffset=(X=+3,Z=130)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=100)))
		HitboxChain.Add((BoneOffset=(X=+3,Z=80)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=60)))
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

    bIsMur=true
    MurAttackAnimRate=1.25f

	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Slashing_CrucibleET_Light'
	InstantHitDamage(DEFAULT_FIREMODE)=210
	InstantHitMomentum(DEFAULT_FIREMODE)=30000.f

	InstantHitDamageTypes(HEAVY_ATK_FIREMODE)=class'KFDT_Slashing_CrucibleET_Heavy'
	InstantHitDamage(HEAVY_ATK_FIREMODE)=280
	InstantHitMomentum(HEAVY_ATK_FIREMODE)=30000.f

	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Piercing_CrucibleET_Stab'
	InstantHitDamage(BASH_FIREMODE)=115
	InstantHitMomentum(BASH_FIREMODE)=100000.f

	// Inventory
	GroupPriority=21 // funny number
	InventorySize=8
	WeaponSelectTexture=Texture2D'WEP_Crucible_MAT.UI_WeaponSelect_CrucibleET'
	AssociatedPerkClasses(0)=class'KFPerk_Berserker'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DTest' // Loot beam fx (no offset)

	// Block Sounds
	BlockSound=AkEvent'WW_WEP_Bullet_Impacts.Play_Block_MEL_Katana'
	ParrySound=AkEvent'WW_WEP_Bullet_Impacts.Play_Parry_Metal'

	ParryDamageMitigationPercent=0.4
	BlockDamageMitigation=0.5
	ParryStrength=5

	// Particle system
	Begin Object Class=KFParticleSystemComponent Name=BasePSC0
		TickGroup=TG_PostUpdateWork
	End Object
	ParticlePSC=BasePSC0
	ParticleFXTemplate=ParticleSystem'DTest_EMIT.FX_CrucibleET_ParticleFX'

	// Equiping particle system
	// Begin Object Class=KFParticleSystemComponent Name=BasePSC1
	// 	TickGroup=TG_PostUpdateWork
	// End Object
	// EquipPSC=BasePSC1
	// EquipFXTemplate=ParticleSystem'DTest_EMIT.FX_CrucibleET_EquipFX'
	
	// Point light
    Begin Object Class=PointLightComponent Name=IdlePointLight
		LightColor=(R=250,G=0,B=0,A=255)
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
	LightAttachBone=LightSource

	// Ambient Sounds
    AmbientSoundPlayEvent=AkEvent'WW_ENV_BurningParis.Play_ENV_Paris_Underground_LP_01'
    AmbientSoundStopEvent=AkEvent'WW_ENV_BurningParis.Stop_ENV_Paris_Underground_LP_01'

	// Motify trails
    DistortTrailParticle=ParticleSystem'DTest_EMIT.FX_Crucible_Inferno'
	WhiteTrailParticle=ParticleSystem'DTest_EMIT.FX_Crucible_Inferno'
	BlueTrailParticle=ParticleSystem'DTest_EMIT.FX_Crucible_Inferno'
	RedTrailParticle=ParticleSystem'DTest_EMIT.FX_Crucible_Inferno'
}