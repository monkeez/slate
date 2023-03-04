extends Node2D


@onready var light := $Light
@onready var slate = $Slate as Slate


func _ready() -> void:
	$Slate/On/D.entered.connect(func(): light.show())
	$Slate/On/D.exited.connect(func(): light.hide())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		slate.send_event("flick")
