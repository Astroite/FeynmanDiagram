extends GdUnitTestSuite

const ParticleSpecScript := preload("res://core/physics/ParticleSpec.gd")


func test_electron_quantum_numbers() -> void:
	var electron = ParticleSpecScript.get_spec(&"electron")
	assert_that(electron).is_not_null()
	assert_int(electron.charge3).is_equal(-3)
	assert_int(electron.lepton_e).is_equal(1)
	assert_int(electron.fermion_sign).is_equal(1)
	assert_that(electron.family).is_equal(&"electron")
	assert_that(electron.antiparticle).is_equal(&"positron")
	assert_bool(electron.is_fermion()).is_true()


func test_positron_is_electron_family_antimatter() -> void:
	var positron = ParticleSpecScript.get_spec(&"positron")
	assert_int(positron.charge3).is_equal(3)
	assert_int(positron.lepton_e).is_equal(-1)
	assert_int(positron.fermion_sign).is_equal(-1)
	assert_that(positron.family).is_equal(&"electron")


func test_muon_family_distinct_from_electron() -> void:
	var muon = ParticleSpecScript.get_spec(&"muon")
	var anti_muon = ParticleSpecScript.get_spec(&"anti_muon")
	assert_that(muon.family).is_equal(&"muon")
	assert_that(anti_muon.family).is_equal(&"muon")
	assert_int(muon.lepton_mu).is_equal(1)
	assert_int(anti_muon.lepton_mu).is_equal(-1)
	assert_int(muon.lepton_e).is_equal(0)


func test_photon_is_neutral_boson() -> void:
	var photon = ParticleSpecScript.get_spec(&"photon")
	assert_int(photon.charge3).is_equal(0)
	assert_int(photon.fermion_sign).is_equal(0)
	assert_bool(photon.is_boson()).is_true()


func test_unknown_and_empty_ids() -> void:
	assert_that(ParticleSpecScript.get_spec(&"graviton")).is_null()
	assert_bool(ParticleSpecScript.has(&"electron")).is_true()
	assert_bool(ParticleSpecScript.has(&"")).is_false()
	assert_int(ParticleSpecScript.qed_ids().size()).is_equal(5)
