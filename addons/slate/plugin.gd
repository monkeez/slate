@tool
extends EditorPlugin


func _enter_tree() -> void:
	print("Slate initialized!")


func _exit_tree() -> void:
	print("Slate uninitialized!")
