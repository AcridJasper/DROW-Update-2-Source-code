class KFProj_Bullet_Valkyrie extends KFProj_Bullet
	hidedropdown;

defaultproperties
{
	MaxSpeed=18000 //22500
	Speed=18000

	DamageRadius=0

	ProjFlightTemplate=ParticleSystem'DTest_EMIT.FX_Valkyrie_Tracer'
	ProjFlightTemplateZedTime=ParticleSystem'DTest_EMIT.FX_Valkyrie_Tracer'

	ImpactEffects=KFImpactEffectInfo'WEP_Laser_Cutter_ARCH.Laser_Cutter_bullet_impact'
}