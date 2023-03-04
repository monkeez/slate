class_name Slate
extends Node
## Statechart node.
##
## The primary feature of statecharts is that states can be organized 
## in a hierarchy:  A statechart is a state machine where each state in 
## the state machine may define its own subordinate state machines, 
## called substates.  Those states can again define substates.
##
## @tutorial(What is a statechart): https://statecharts.dev/what-is-a-statechart.html


## Emitted after the state is entered
signal entered


## Emitted after the state has exited
signal exited


enum Status {
	INACTIVE, ## Don't process state.
	ENTERING, ## State is set to enter.
	ACTIVE,   ## Process the state.
	EXITING,  ## State is set to exit.
}


enum History {
	NONE,    ## Don't use history for state transition.
	SHALLOW, ## Use history for the state being transitioned to.
	DEEP,    ## Use history for the state being transitioned and all substates.
}


## Enables this state in the state chart.
@export
var enabled := true:
	set(value):
		enabled = value
		if is_active(self) and not enabled:
			pass # Exit state/transition to next


## Region for state to run in. Setting states to different regions
## will mean the parent state will run in parallel mode.
@export
var region := 0


@export_group("Slate Timer")
@export_range(0.0, 30.0, 0.1, "suffix:s", "exp", "or_greater")
var wait_time := 0.0


## Current status of this state node.
var status := Status.INACTIVE:
	set(value):
		status = value
		match status:
			Status.ACTIVE:
				process_mode = Node.PROCESS_MODE_INHERIT
			Status.INACTIVE:
				process_mode = Node.PROCESS_MODE_DISABLED


var _event_handled := false
var _history: Dictionary
var _regions: Dictionary
var _timer: Timer


func _ready() -> void:
	_update_regions()
	if get_root() == self and enabled:
		_set_entering()
		_enter()
	else:
		status = Status.INACTIVE


## Checks if this state is the root node of the state chart.
func is_root() -> bool:
	return not get_parent() is Slate


## Returns the root state of the state chart.
func get_root() -> Slate:
	var parent := self
	while not parent.is_root():
		parent = parent.get_parent() as Slate
	return parent


## Returns an array of references to this state's substates.
func get_substates() -> Array[Slate]:
	var substates: Array[Slate]
	substates.append_array(get_children().filter(is_state))
	return substates


## Transitions to the given state.
func transition_to_state(state: Slate, internal := false, history := History.NONE) -> void:
	if status != Status.ACTIVE:
		return
	
	var names := String(get_path_to(state)).split("/")
	var get_node_at_index = func(i: int) -> Slate:
		return get_node("/".join(names.slice(0, i + 1))) as Slate
	
	var nodes = range(names.size()).map(get_node_at_index)
	nodes.push_front(self)

	# Return if any states in the transition are disabled
	if not nodes.all(is_enabled):
		return
	
	# This finds the root index of the state transition
	var root_index = names.rfind("..") + 1
	var root = nodes[root_index]
	
	var skip_root = not state == self
	if state.get_parent() == self or get_parent() == state:
		skip_root = internal
	
	root._set_exiting(skip_root)
	root._exit()
	
	for node in nodes.slice(root_index + 1):
		if node == root:
			continue
		node.status = Status.ENTERING
	
	root._set_entering(skip_root, history)
	root._enter()


## Transitions to the state with the given [kbd]name[/kbd].
## [br][br]When [kbd]name[/kbd] is a [String] it will first search for 
## sibling states. If none are found it will then search for child states. 
## If none are found it will search from the root of the state chart.
## If name is determined to be a [NodePath] it will will use [method Node.get_node_or_null] 
## to find the node.
## [br][br]When [kbd]internal[/kbd] is [code]true[/code] the transition will
## skip exiting and entering the parent state.
func transition_to(name: String, internal := false, history := History.NONE) -> void:
	if status != Status.ACTIVE:
		return
	
	var state: Slate
	if not ("/" in name or "." in name):
		state = get_node_or_null("../" + name) as Slate
		state = state if state else get_node_or_null(name) as Slate
		state = state if state else get_root().find_child(name) as Slate
	else:
		state = get_node_or_null(name) as Slate

	if not state:
		return
	transition_to_state(state, internal, history)


## Transitions to the next state.
func transition_to_next() -> void:
	if status != Status.ACTIVE:
		return


func send_event(event: String) -> void:
	_reset_event_handled()
	_event(event)


func set_event_as_handled() -> void:
	var parent := self
	while not parent.is_root():
		parent = parent.get_parent() as Slate
		parent._event_handled = true


## Called when state has entered.
func _on_enter() -> void:
	pass


## Called when node has exited.
func _on_exit() -> void:
	pass


## Called when an event is received
func _on_event(event: String) -> void:
	pass


## Called when the timer ends.
func _on_timeout() -> void:
	pass


func _create_timer() -> void:
	if wait_time > 0.0:
		_timer = Timer.new()
		add_child(_timer)
		_timer.one_shot = true
		_timer.timeout.connect(_on_timeout)
		_timer.start(wait_time)


func _delete_timer() -> void:
	if _timer != null:
		_timer.timeout.disconnect(_on_timeout)
		_timer.queue_free()


func _update_regions():
	var dict := {}
	for substate in get_substates():
		if substate.region in dict:
			dict[substate.region].append(substate)
		else:
			dict[substate.region] = [substate]
	_regions = dict


func _set_entering(skip_self := false, history := History.NONE) -> void:
	if not skip_self:
		status = Status.ENTERING
	for i in _regions:
		var substates = _regions[i].filter(is_entering)
		if substates.is_empty():
			substates = _regions[i].filter(is_enabled)
			if history == History.SHALLOW or history == History.DEEP:
				if history == History.SHALLOW:
					history = History.NONE
				if _history[i].enabled:
					substates = [_history[i]]
		for substate in substates:
			substate._set_entering(false, history)
			break


func _set_exiting(skip_self: bool = false) -> void:
	if not skip_self:
		status = Status.EXITING
	for i in _regions:
		for substate in _regions[i].filter(is_active):
			_history[i] = substate
			substate._set_exiting()


func _reset_event_handled() -> void:
	_event_handled = false
	for state in get_substates():
		state._reset_event_handled()


func _event(event: String) -> void:
	for i in _regions:
		for state in _regions[i].filter(is_active):
			state._event(event)
	if not _event_handled:
		_on_event(event)


func _enter() -> void:
	if status == Status.ENTERING:
		_create_timer()
		status = Status.ACTIVE
		_on_enter()
		entered.emit()
		prints(self, "entering")
	for i in _regions:
		for state in _regions[i].filter(is_entering):
			state._enter()


func _exit() -> void:
	for i in _regions:
		for state in _regions[i].filter(is_exiting):
			state._exit()
	if status == Status.EXITING:
		_delete_timer()
		prints(self, "exiting")
		_on_exit()
		exited.emit()
		status = Status.INACTIVE


## Checks if the given [kbd]node[/kbd] is a [Slate] node.
static func is_state(node: Node) -> bool:
	return node is Slate


## Checks if the given [kbd]state[/kbd] is entering.
static func is_entering(state: Slate) -> bool:
	return state.status == Status.ENTERING


## Checks if the given [kbd]state[/kbd] is exiting.
static func is_exiting(state: Slate) -> bool:
	return state.status == Status.EXITING


## Checks if the given [kbd]state[/kbd] is active.
static func is_active(state: Slate) -> bool:
	return state.status == Status.ACTIVE


## Checks if the given [kbd]state[/kbd] is enabled.
static func is_enabled(state: Slate) -> bool:
	return state.enabled
