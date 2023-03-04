extends Slate


# Called when the timer ends.
func _on_timeout() -> void:
	transition_to("D")
