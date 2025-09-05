class KFProj_Bullet_Kavotia extends KFProj_Bullet
    hidedropdown;

defaultproperties
{
    MaxSpeed=22500
    Speed=22500

    DamageRadius=0

    ProjFlightTemplate=ParticleSystem'DTest_EMIT.FX_MuzzleFlash_Null'
    ProjFlightTemplateZedTime=ParticleSystem'DTest_EMIT.FX_Kavotia_Tracer_ZedTime'

    ImpactEffects=KFImpactEffectInfo'WEP_Kavotia_ARCH.Kavotia_Bullet_Impact'
}