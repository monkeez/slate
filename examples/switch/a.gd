extends Slate


# Called when an event is sent.
func _on_event(event: String) -> void:
	if event == "flick":
		transition_to_state(self)
		set_event_as_handled()


# Called when the timer ends.
func _on_timeout() -> void:
	transition_to("B")
