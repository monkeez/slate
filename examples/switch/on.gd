extends Slate


# Called when an event is sent.
func _on_event(event: String) -> void:
	if event == "flick":
		transition_to("Off")
		set_event_as_handled()
