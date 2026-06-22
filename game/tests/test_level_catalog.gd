extends GdUnitTestSuite

const LevelCatalogScript := preload("res://level/LevelCatalog.gd")
const LevelSpecScript := preload("res://level/LevelSpec.gd")


func test_catalog_enumerates_seven_levels_in_order() -> void:
	var catalog = LevelCatalogScript.new()
	assert_int(catalog.count()).is_equal(7)
	assert_that(catalog.spec_at(0).level_id).is_equal(&"001")
	assert_that(catalog.spec_at(6).level_id).is_equal(&"007")
	assert_that(catalog.spec_at(-1)).is_null()
	assert_that(catalog.spec_at(7)).is_null()


func test_next_of_walks_then_terminates() -> void:
	var catalog = LevelCatalogScript.new()
	assert_that(catalog.next_of(&"001").level_id).is_equal(&"002")
	assert_that(catalog.next_of(&"007")).is_null()
	assert_bool(catalog.has_next(&"006")).is_true()
	assert_bool(catalog.has_next(&"007")).is_false()


func test_index_of_unknown_is_negative() -> void:
	var catalog = LevelCatalogScript.new()
	assert_int(catalog.index_of(&"999")).is_equal(-1)


func test_display_fields_fall_back_to_title_then_id() -> void:
	var spec = LevelSpecScript.new()
	spec.level_id = &"042"
	# Nothing set: both labels fall back to the id.
	assert_str(spec.code_label()).is_equal("042")
	assert_str(spec.name_label()).is_equal("042")
	# title set: name uses it, code still the id.
	spec.title = "Internal Title"
	assert_str(spec.name_label()).is_equal("Internal Title")
	assert_str(spec.code_label()).is_equal("042")
	# display fields win when present.
	spec.display_code = "序章 · 42"
	spec.display_name = "测试关卡"
	assert_str(spec.code_label()).is_equal("序章 · 42")
	assert_str(spec.name_label()).is_equal("测试关卡")


func test_authored_levels_have_display_fields() -> void:
	var catalog = LevelCatalogScript.new()
	for index in range(catalog.count()):
		var spec = catalog.spec_at(index)
		assert_str(spec.display_code).is_not_empty()
		assert_str(spec.display_name).is_not_empty()
