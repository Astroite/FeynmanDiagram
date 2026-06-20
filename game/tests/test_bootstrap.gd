extends GdUnitTestSuite

func test_graph_model_can_be_created() -> void:
	assert_that(GraphModel.new()).is_not_null()
