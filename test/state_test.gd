# GdUnit generated TestSuite
class_name SlateTest
extends GdUnitTestSuite
@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")


# TestSuite generated from
const __source = 'res://addons/slate/nodes/slate_state.gd'


func test_is_state() -> void:
	var runner := scene_runner("res://examples/simple/simple.tscn")
	var scene = runner.scene()
	
	assert_bool(Slate.is_state(scene)).is_true()
	assert_bool(Slate.is_state(scene.a)).is_true()
	assert_bool(Slate.is_state(scene.b)).is_true()
	assert_bool(Slate.is_state(scene.node)).is_false()


func test_status() -> void:
	var runner := scene_runner("res://examples/simple/simple.tscn")
	var scene = runner.scene()
	
	assert_that(scene.status).is_equal(Slate.Status.ACTIVE)
	assert_that(scene.a.status).is_equal(Slate.Status.ACTIVE)
	assert_that(scene.b.status).is_equal(Slate.Status.INACTIVE)


func test_transition_to() -> void:
	var runner := scene_runner("res://examples/simple/simple.tscn")
	var scene = runner.scene()
	
	assert_that(scene.a.status).is_equal(Slate.Status.ACTIVE)
	scene.a.transition_to("B")
	assert_that(scene.a.status).is_equal(Slate.Status.INACTIVE)


func test_is_root() -> void:
	var runner := scene_runner("res://examples/simple/simple.tscn")
	var scene = runner.scene()

	assert_bool(scene.a.is_root()).is_false()
	assert_bool(scene.b.is_root()).is_false()
	assert_bool(scene.is_root()).is_true()


func test_get_root() -> void:
	var runner := scene_runner("res://examples/simple/simple.tscn")
	var scene = runner.scene()

	assert_object(scene.get_root()).is_same(scene)
	assert_object(scene.a.get_root()).is_same(scene)
	assert_object(scene.b.get_root()).is_same(scene)


func test_get_substates() -> void:
	var runner := scene_runner("res://examples/simple/simple.tscn")
	var scene = runner.scene()

	assert_array(scene.get_children()).contains_exactly([scene.a, scene.b, scene.node])
	assert_array(scene.get_substates()).contains_exactly([scene.a, scene.b])
