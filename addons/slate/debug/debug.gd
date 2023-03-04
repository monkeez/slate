extends Tree


@export var slate: Slate


func _ready() -> void:
	add_state(slate)


func add_state(state: Slate, parent: TreeItem = null) -> void:
	var item := create_item(parent)
	item.set_text(0, state.name)
	state.entered.connect(_on_Slate_entered.bind(state, item))
	state.exited.connect(_on_Slate_exited.bind(state, item))
	for substate in state.get_substates():
		add_state(substate, item)


func _on_Slate_entered(state: Slate, item: TreeItem) -> void:
	update_item_colour(item, Color.GREEN)


func _on_Slate_exited(state: Slate, item: TreeItem) -> void:
	update_item_colour(item, Color.RED)


func update_item_colour(treeitem: TreeItem, colour: Color) -> void:
	treeitem.set_custom_bg_color(0, colour)
