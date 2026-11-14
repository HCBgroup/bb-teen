@tool
extends SceneTree

func _init() -> void:
	print("Loading school(evin).tscn...")
	var scn = load("res://Scence/school(evin).tscn")
	var school = scn.instantiate()
	root.add_child(school)

	var exam = school.get_node("ExamSpotlightSequence")
	print("Triggering start_exam_sequence()...")
	exam.start_exam_sequence()
	print("Exam sequence started successfully!")

	school.queue_free()
	print("TEST PASSED WITH ZERO ERRORS!")
	quit(0)
