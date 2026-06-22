class_name PhysicsGrammar
extends RefCounted

# QED validation: judges a graph by physics rules only, never geometry. Pipeline
# order follows doc01 §4.4 (for this iteration): integrity → vertex template →
# fermion-flow continuity. Charge / fermion-number conservation is guaranteed at
# each vertex by the template itself (the only charged QED vertex is f f̄ γ / f→fγ),
# so a graph whose every vertex matches and whose fermion lines are continuous is
# conserving by construction.
#
# Result is a Dictionary: { ok: bool, stage: String, message: String, node_id: StringName }.

const STAGE_INTEGRITY := "integrity"
const STAGE_VERTEX := "vertex"
const STAGE_OK := "ok"

const MESSAGE_OK := "费曼图守恒成立 · 电荷与轻子数平衡"


func validate(graph: GraphModel) -> Dictionary:
	if graph == null:
		return _fail(STAGE_INTEGRITY, "没有可验证的图", &"")

	if graph.has_dangling_half_edges():
		return _fail(STAGE_INTEGRITY, "还有未连接的端点", &"")
	if not graph.is_graph_connected():
		return _fail(STAGE_INTEGRITY, "图尚未连通", &"")

	for node in graph.nodes.values():
		if node.kind != NodeKind.VERTEX:
			continue
		var result := check_vertex(node)
		if not result["ok"]:
			return result

	return _ok()


# A QED interaction vertex: exactly one photon leg + two fermion legs of the same
# family, with the fermion arrow continuous (one in, one out).
func check_vertex(node) -> Dictionary:
	var label := _vertex_label(node)
	var legs := vertex_legs(node)
	if legs.size() != 3:
		return _fail(STAGE_VERTEX, "顶点 %s 需要 1 光子 + 2 费米子（当前 %d 条腿）" % [label, legs.size()], node.id)

	var bosons: Array[HalfEdge] = []
	var fermions: Array[HalfEdge] = []
	for half_edge in legs:
		var spec := _spec_of(half_edge)
		if spec == null:
			return _fail(STAGE_VERTEX, "顶点 %s 连接了未知粒子" % label, node.id)
		if spec.is_boson():
			bosons.append(half_edge)
		else:
			fermions.append(half_edge)

	if bosons.size() != 1 or fermions.size() != 2:
		return _fail(STAGE_VERTEX, "顶点 %s 必须恰好连接 1 个光子和 2 条费米子线" % label, node.id)
	if String(_spec_of(bosons[0]).id) != "photon":
		return _fail(STAGE_VERTEX, "顶点 %s 的玻色子必须是光子" % label, node.id)

	var family_a := _spec_of(fermions[0]).family
	var family_b := _spec_of(fermions[1]).family
	if family_a != family_b:
		return _fail(STAGE_VERTEX, "顶点 %s 的两条费米子味道不一致" % label, node.id)

	var inflow := 0
	for fermion in fermions:
		if arrow_into_vertex(fermion):
			inflow += 1
	if inflow != 1:
		return _fail(STAGE_VERTEX, "顶点 %s 费米子流向不连续（需一进一出）" % label, node.id)

	return _ok()


# Occupied half-edges at a node, in socket order.
func vertex_legs(node) -> Array[HalfEdge]:
	var legs: Array[HalfEdge] = []
	for socket in node.sockets:
		if socket.occupied_by != null:
			legs.append(socket.occupied_by)
	return legs


# True when the fermion arrow points toward this vertex. The arrow runs a→b when
# fermion_sign > 0 and b→a when < 0; it terminates at this vertex when the leg sits
# at the arrow's head end.
func arrow_into_vertex(half_edge: HalfEdge) -> bool:
	var spec := _spec_of(half_edge)
	if spec == null or spec.fermion_sign == 0:
		return false
	var edge := half_edge.edge
	if edge == null:
		return false
	var is_a_end := edge.half_edge_a == half_edge
	if spec.fermion_sign > 0:
		return not is_a_end
	return is_a_end


func _spec_of(half_edge: HalfEdge) -> ParticleSpec:
	var particle_id := half_edge.particle_id
	if String(particle_id).is_empty() and half_edge.edge != null:
		particle_id = half_edge.edge.particle_id
	return ParticleSpec.get_spec(particle_id)


func _vertex_label(node) -> String:
	return String(node.id).to_upper()


func _ok() -> Dictionary:
	return {"ok": true, "stage": STAGE_OK, "message": MESSAGE_OK, "node_id": &""}


func _fail(stage: String, message: String, node_id: StringName) -> Dictionary:
	return {"ok": false, "stage": stage, "message": message, "node_id": node_id}
