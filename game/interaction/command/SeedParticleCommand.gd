class_name SeedParticleCommand
extends Command

# Station a particle "seed" at an endpoint (the tray's swatch-onto-endpoint verb).
# The seed is the source identity a player-drawn line inherits when pulled out from
# here (see CreateEdgeCommand). It is a presentation/authoring hint only — judging
# reads edge/half-edge ids, never the node seed. Undo restores the prior seed.

var _model: GraphModel = null
var _node: RefCounted = null
var _to_particle: StringName = &""
var _from_particle: StringName = &""


func configure(model: GraphModel, node: RefCounted, particle_id: StringName) -> SeedParticleCommand:
	label = &"seed_particle"
	_model = model
	_node = node
	_to_particle = particle_id
	if node != null:
		_from_particle = node.particle_id
	return self


func do() -> bool:
	if _model == null or _node == null:
		return false
	return _model.set_node_particle(_node, _to_particle)


func undo() -> bool:
	if _model == null or _node == null:
		return false
	return _model.set_node_particle(_node, _from_particle)
