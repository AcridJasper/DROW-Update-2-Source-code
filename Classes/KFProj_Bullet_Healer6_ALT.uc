class KFProj_Bullet_Healer6_ALT extends KFProj_Bullet;

defaultproperties
{
	MaxSpeed=18000
	Speed=18000

	ProjFlightTemplate=ParticleSystem'DTest_EMIT.FX_MuzzleFlash_Null'
	ProjFlightTemplateZedTime=ParticleSystem'DTest_EMIT.FX_Healer6_Tracer_ZedTime'

	ImpactEffects=KFImpactEffectInfo'FX_Impacts_ARCH.Heavy_bullet_impact'
}