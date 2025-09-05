class KFWeap_SplitRifle extends KFWeap_MedicBase;

// per bullet shot burst anims
const SecondaryBurstFireAnim     = 'Shoot';
const SecondaryBurstFireIronAnim = 'Shoot_Iron';

simulated function name GetWeaponFireAnim(byte FireModeNum)
{
	if (FireModeNum == ALTFIRE_FIREMODE)
	{
		return bUsingSights ? SecondaryBurstFireIronAnim : SecondaryBurstFireAnim;
	}

	return super.GetWeaponFireAnim(FireModeNum);
}

// Called during reload state
simulated function bool CanOverrideMagReload(byte FireModeNum)
{
	return super.CanOverrideMagReload(FireModeNum) || FireModeNum == ALTFIRE_FIREMODE;
}

// Returns trader filter index based on weapon type
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Assault;
}

defaultproperties
{
    // FOV
	MeshFOV=70
	MeshIronSightFOV=52
    PlayerIronSightFOV=70

	// Zooming/Position
	IronSightPosition=(X=10,Y=-0.015,Z=-0.15)
	PlayerViewOffset=(X=30.0,Y=10,Z=-2.5)

	// Content
	PackageKey="SplitRifle"
	FirstPersonMeshName="WEP_SplitRifle_MESH.Wep_1stP_SplitRifle_Rig"
	FirstPersonAnimSetNames(0)="WEP_SplitRifle_ARCH.WEP_1P_SplitRifle_ANIM"
	PickupMeshName="WEP_SplitRifle_MESH.Wep_SplitRifle_Pickup"
	AttachmentArchetypeName="WEP_SplitRifle_ARCH.WEP_SplitRifle_3P"
	MuzzleFlashTemplateName="WEP_SplitRifle_ARCH.Wep_SplitRifle_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=40
	SpareAmmoCapacity[0]=360
	InitialSpareMags[0]=2
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=125
	minRecoilPitch=100
	maxRecoilYaw=120
	minRecoilYaw=-100
	RecoilRate=0.085
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=75
	RecoilISMinYawLimit=65460
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	IronSightMeshFOVCompensationScale=4.0

	// Inventory
	InventorySize=8
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_SplitRifle_MAT.UI_WeaponSelect_SplitRifle'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DTest' // Loot beam fx (no offset)

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_InstantHit
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_SplitRifle'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_SplitRifle'
	InstantHitDamage(DEFAULT_FIREMODE)=40 //50
	FireInterval(DEFAULT_FIREMODE)=+0.1 // 600 RPM
	Spread(DEFAULT_FIREMODE)=0.0085
	PenetrationPower(DEFAULT_FIREMODE)=0.0
	FireOffset=(X=30,Y=4.5,Z=-5)

	// ALTFIRE_FIREMODE
	SecondaryAmmoTexture=Texture2D'UI_SecondaryAmmo_TEX.MedicDarts'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponBurstFiring
	AmmoCost(ALTFIRE_FIREMODE)=30
	FireInterval(ALTFIRE_FIREMODE)=+0.1 // 600 RPM
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_HealingDart_MedicBase'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Dart_Toxic'
	InstantHitDamage(ALTFIRE_FIREMODE)=5.0

	BurstAmount=3
	// BurstFire1RdAnim=Shoot
	// BurstFire2RdAnim=Shoot_Burst2
	// BurstFire3RdAnim=Shoot_Burst //3 round burst anim
	// BurstFire2RdSightedAnim=Shoot_Burst2_Iron
	// BurstFire3RdSightedAnim=Shoot_Burst_Iron

	// Healing charge
    HealAmount=15
	HealFullRechargeSeconds=10
	HealingDartDamageType=class'KFDT_Dart_Healing'

	OpticsUIClass=class'KFGFxWorld_MedicOptics'

	DartFireSnd=(DefaultCue=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Dart_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Dart_Fire_1P')
	LockAcquiredSoundFirstPerson=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Alert_Locked_1P'
	LockLostSoundFirstPerson=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Alert_Lost_1P'
	LockTargetingSoundFirstPerson=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Alert_Locking_1P'
    HealImpactSoundPlayEvent=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Dart_Heal'
    HurtImpactSoundPlayEvent=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Dart_Hurt'
	HealingDartWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Default_Recoil'

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_MicrowaveRifle'
	InstantHitDamage(BASH_FIREMODE)=26

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Helios.Play_WEP_Helios_Shoot_FullAuto_LP_3P', FirstPersonCue=AkEvent'WW_WEP_Helios.Play_WEP_Helios_Shoot_FullAuto_LP_1P')
	WeaponFireLoopEndSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Helios.Play_WEP_Helios_Shoot_FullAuto_LP_End_3P', FirstPersonCue=AkEvent'WW_WEP_Helios.Play_WEP_Helios_Shoot_FullAuto_LP_End_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_SCAR.Play_WEP_SA_SCAR_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_SCAR.Play_WEP_SA_SCAR_Handling_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=true
	bLoopingFireSnd(DEFAULT_FIREMODE)=true
	WeaponFireSnd(2)=(DefaultCue=AkEvent'WW_WEP_Helios.Play_WEP_Helios_Shoot_Single_3P', FirstPersonCue=AkEvent'WW_WEP_Helios.Play_WEP_Helios_Shoot_Single_1P')
	SingleFireSoundIndex=2

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	AssociatedPerkClasses(0)=class'KFPerk_FieldMedic'
}