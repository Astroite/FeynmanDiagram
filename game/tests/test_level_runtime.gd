extends GdUnitTestSuite

const ForbiddenZoneScript := preload("res://level/objectives/ForbiddenZone.gd")
const LevelRuntimeScript := preload("res://level/LevelRuntime.gd")
const ObservationRingScript := preload("res://level/objectives/ObservationRing.gd")

const LEVEL_PATHS := [
	"res://level/levels/001_drag_node_ring.tres",
	"res://level/levels/002_bend_fixed_ends.tres",
	"res://level/levels/003_forbidden_weave.tres",
	"res://level/levels/004_undo_redo_path.tres",
	"res://level/levels/005_snap_half_edge.tres",
	"res://level/levels/006_three_line_convergence.tres",
]


func test_point_in_ring_objective_check() -> void:
	var ring = ObservationRingScript.new()
	ring.center = Vector2.ZERO
	ring.radius = 10.0
	ring.thickness = 4.0

	assert_that(ring.call("point_in_ring", Vector2(10.0, 0.0))).is_true()
	assert_that(ring.call("point_in_ring", Vector2(7.5, 0.0))).is_false()
	assert_that(ring.call("point_in_ring", Vector2(12.5, 0.0))).is_false()


func test_segment_vs_forbidden_zone_objective_check() -> void:
	var zone = ForbiddenZoneScript.new()
	zone.center = Vector2(10.0, 0.0)
	zone.radius = 3.0

	assert_that(zone.call("segment_intersects_zone", Vector2.ZERO, Vector2(20.0, 0.0))).is_true()
	assert_that(zone.call("segment_intersects_zone", Vector2.ZERO, Vector2(20.0, 8.0))).is_false()


func test_all_greybox_reference_solutions_complete() -> void:
	for path in LEVEL_PATHS:
		var spec: Resource = load(path)
		assert_that(spec).is_not_null()

		var runtime = LevelRuntimeScript.new()
		auto_free(runtime)
		var completions: Array[StringName] = []
		runtime.level_complete.connect(func(completed_spec): completions.append(completed_spec.level_id))

		assert_that(runtime.load_level(spec)).is_true()
		assert_that(runtime.is_level_complete()).is_false()
		assert_that(runtime.apply_reference_solution()).is_true()
		assert_that(runtime.is_level_complete()).is_true()
		assert_that(completions.has(spec.level_id)).is_true()


func test_level_spec_tres_save_load_round_trip() -> void:
	var original: Resource = load(LEVEL_PATHS[0])
	var temp_path := "user://level_round_trip.tres"

	assert_int(ResourceSaver.save(original, temp_path)).is_equal(OK)
	var copy: Resource = load(temp_path)

	assert_that(copy).is_not_null()
	assert_that(copy.level_id).is_equal(original.level_id)
	assert_that(copy.title).is_equal(original.title)
	assert_that(copy.spatial_objectives.size()).is_equal(original.spatial_objectives.size())
	assert_that(JSON.stringify(copy.givens)).is_equal(JSON.stringify(original.givens))
	assert_that(JSON.stringify(copy.reference_solution)).is_equal(JSON.stringify(original.reference_solution))
