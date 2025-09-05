class KFWeap_MononokeGiri extends KFWeap_MeleeBase;

var transient KFParticleSystemComponent ParticlePSC;
var const ParticleSystem ParticleFXTemplate;

/* Light that is applied to the blade and the bone to attach to*/
var PointLightComponent IdleLight;
var Name LightAttachBone;

simulated state WeaponEquipping
{
	// when picked up, start the persistent sound
	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		ActivatePSC(ParticlePSC, ParticleFXTemplate, 'ParticleFX');

		if (MySkelMesh != none)
		{
			MySkelMesh.AttachComponentToSocket(IdleLight, LightAttachBone);
			IdleLight.SetEnabled(true);
		}
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
		OutPSC.SetDepthPriorityGroup(SDPG_Foreground);
		// OutPSC.SetAbsolute(false, false, false);
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

simulated state Inactive
{
	// when dropped, destroyed, etc, play the stop on the persistent sound
	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		if (ParticlePSC != none)
		{
			ParticlePSC.DeactivateSystem();
		}

		IdleLight.SetEnabled(false);
	}
}

defaultproperties
{
	// Zooming/Position
	PlayerViewOffset=(X=2,Y=0,Z=0)

	// Content
	PackageKey="MononokeGiri"
	FirstPersonMeshName="WEP_MononokeGiri_MESH.Wep_1stP_MononokeGiri_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_KATANA_ANIM.Katana_Anim_Master"
	PickupMeshName="WEP_MononokeGiri_MESH.Wep_MononokeGiri_Pickup"
	AttachmentArchetypeName="WEP_MononokeGiri_ARCH.WEP_MononokeGiri_3P"

	// Create all these particle system components off the bat so that the tick group can be set
	// fixes issue where the particle systems get offset during animations
	Begin Object Class=KFParticleSystemComponent Name=BasePSC0
		TickGroup=TG_PostUpdateWork
	End Object
	ParticlePSC=BasePSC0
	ParticleFXTemplate=ParticleSystem'DTest_EMIT.FX_MononokeGiri_ParticleFX'

    Begin Object Class=PointLightComponent Name=IdlePointLight
		LightColor=(R=250,G=150,B=250,A=255)
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
	LightAttachBone=ParticleFX
	
	Begin Object Name=MeleeHelper_0
		MaxHitRange=215 //190
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
		MeleeImpactCamShakeScale=0.03f //0.3
		// modified combo sequences
		ChainSequence_F=(DIR_Left, DIR_ForwardRight, DIR_ForwardLeft, DIR_ForwardRight, DIR_ForwardLeft)
		ChainSequence_B=(DIR_BackwardRight, DIR_ForwardLeft, DIR_BackwardLeft, DIR_ForwardRight, DIR_Left, DIR_Right, DIR_Left)
		ChainSequence_L=(DIR_Right, DIR_Left, DIR_ForwardRight, DIR_ForwardLeft, DIR_Right, DIR_Left)
		ChainSequence_R=(DIR_Left, DIR_Right, DIR_ForwardLeft, DIR_ForwardRight, DIR_Left, DIR_Right)
	End Object
	
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Slashing_Katana'
	InstantHitDamage(DEFAULT_FIREMODE)=165
	
	InstantHitDamageTypes(HEAVY_ATK_FIREMODE)=class'KFDT_Slashing_KatanaHeavy'
	InstantHitDamage(HEAVY_ATK_FIREMODE)=250

	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Piercing_KatanaStab'
	InstantHitDamage(BASH_FIREMODE)=100

	// Inventory
	GroupPriority=21 // funny number
	InventorySize=5 //4
	WeaponSelectTexture=Texture2D'WEP_MononokeGiri_MAT.UI_WeaponSelect_MononokeGiri'
	AssociatedPerkClasses(0)=class'KFPerk_Berserker'
	
	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DTest' // Loot beam fx (no offset)
	
	// Block Sounds
	BlockSound=AkEvent'WW_WEP_Bullet_Impacts.Play_Block_MEL_Katana'
	ParrySound=AkEvent'WW_WEP_Bullet_Impacts.Play_Parry_Metal'
	
	ParryDamageMitigationPercent=0.50
	BlockDamageMitigation=0.60
	ParryStrength=4
}