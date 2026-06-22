class_name ParticleSpec
extends RefCounted

# QED particle catalog. Conserved quantities are exact integers (charge in thirds
# of e: electron = -3). `family` groups a fermion line (e- and e+ share the
# "electron" family); `fermion_sign` is +1 matter / -1 antimatter / 0 boson and
# encodes the fermion-arrow orientation along an edge.

enum Kind { FERMION, BOSON }

var id: StringName
var symbol: String
var display_name: String
var charge3: int
var lepton_e: int
var lepton_mu: int
var kind: int
var family: StringName
var antiparticle: StringName
var fermion_sign: int

static var _registry: Dictionary = {}


func is_fermion() -> bool:
	return kind == Kind.FERMION


func is_boson() -> bool:
	return kind == Kind.BOSON


# Lookup by particle id (the StringName stored on edges/half-edges). Returns null
# for unknown / empty ids (e.g. the topology-only iteration-0 levels).
static func get_spec(particle_id) -> ParticleSpec:
	_ensure_registry()
	return _registry.get(StringName(str(particle_id)), null)


static func has(particle_id) -> bool:
	return get_spec(particle_id) != null


# Ids in a stable display order, for the tray and codex.
static func qed_ids() -> Array[StringName]:
	return [&"electron", &"positron", &"photon", &"muon", &"anti_muon"]


static func qed_specs() -> Array[ParticleSpec]:
	var result: Array[ParticleSpec] = []
	for particle_id in qed_ids():
		result.append(get_spec(particle_id))
	return result


static func _ensure_registry() -> void:
	if not _registry.is_empty():
		return
	# charge3, lepton_e, lepton_mu, kind, family, antiparticle, fermion_sign
	_register(&"electron", "e⁻", "电子", -3, 1, 0, Kind.FERMION, &"electron", &"positron", 1)
	_register(&"positron", "e⁺", "正电子", 3, -1, 0, Kind.FERMION, &"electron", &"electron", -1)
	_register(&"muon", "μ⁻", "μ 子", -3, 0, 1, Kind.FERMION, &"muon", &"anti_muon", 1)
	_register(&"anti_muon", "μ⁺", "反 μ 子", 3, 0, -1, Kind.FERMION, &"muon", &"muon", -1)
	_register(&"photon", "γ", "光子", 0, 0, 0, Kind.BOSON, &"photon", &"photon", 0)


static func _register(id: StringName, symbol: String, display_name: String, charge3: int, lepton_e: int, lepton_mu: int, kind: int, family: StringName, antiparticle: StringName, fermion_sign: int) -> void:
	var spec := ParticleSpec.new()
	spec.id = id
	spec.symbol = symbol
	spec.display_name = display_name
	spec.charge3 = charge3
	spec.lepton_e = lepton_e
	spec.lepton_mu = lepton_mu
	spec.kind = kind
	spec.family = family
	spec.antiparticle = antiparticle
	spec.fermion_sign = fermion_sign
	_registry[id] = spec
