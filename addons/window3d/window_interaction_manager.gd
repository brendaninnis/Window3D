@tool
class_name WindowInteractionManager
extends Node

## Manages raycast-based interaction with UIWindow3D objects
##
## This component handles interaction between a raycast (typically from a VR controller)
## and UIWindow3D objects in the scene. Connect your raycasts and it will automatically
## handle hover, click, and drag interactions.

@export var raycast: RayCast3D: set = set_raycast

## Raycast forward direction configuration
@export_group("Raycast Direction")
enum ForwardDirection {
	NEGATIVE_Z, ## Forward (-Z) - typical for desktop mouse raycasts
	NEGATIVE_Y, ## Down (-Y) - typical for VR controllers pointing down  
	POSITIVE_Y, ## Up (+Y) - for upward pointing raycasts
	POSITIVE_Z, ## Backward (+Z) - for backward pointing raycasts
	NEGATIVE_X, ## Left (-X) - for left pointing raycasts
	POSITIVE_X, ## Right (+X) - for right pointing raycasts
	CUSTOM      ## Custom direction specified by raycast_custom_forward
}

## Which axis represents the forward direction for this raycast
@export var raycast_forward_direction: ForwardDirection = ForwardDirection.NEGATIVE_Y
## Custom forward direction (only used when raycast_forward_direction is CUSTOM)
@export var raycast_custom_forward: Vector3 = Vector3(0, -1, 0)

## Emitted when a window starts being interacted with
signal window_interaction_started(window)
## Emitted when interaction with a window ends
signal window_interaction_ended(window)
## Emitted when a window is clicked (not dragged)
signal window_clicked(window, point: Vector3)
## Emitted when a window starts being dragged
signal window_drag_started(window, point: Vector3)
## Emitted when a window stops being dragged
signal window_drag_ended(window, point: Vector3)

var pressed_window = null
var is_interacting: bool = false

func set_raycast(value: RayCast3D):
	raycast = value

func _ready():
	if not raycast:
		push_warning("WindowInteractionManager: No raycast assigned. Please assign a RayCast3D node.")

## Call this when the window interaction action (trigger/click) is pressed
func handle_interaction_pressed():
	if is_interacting:
		return
		
	is_interacting = true
	
	if _is_colliding_with_window():
		pressed_window = raycast.get_collider()
		window_interaction_started.emit(pressed_window)

## Call this when the window interaction action (trigger/click) is released
func handle_interaction_released():
	if not is_interacting:
		return
		
	is_interacting = false
	
	var was_dragging = false
	if pressed_window and _is_colliding_with_window():
		var collision_point = raycast.get_collision_point()
		# Check if this was a drag or a click
		was_dragging = pressed_window.is_dragged
		if was_dragging:
			window_drag_ended.emit(pressed_window, collision_point)
		else:
			window_clicked.emit(pressed_window, collision_point)
		pressed_window.released_at_point(collision_point)
	
	if pressed_window:
		window_interaction_ended.emit(pressed_window)
	
	# Reset state
	pressed_window = null

func _process(_delta: float) -> void:
	if not raycast:
		return
		
	_handle_window_input()

func _handle_window_input() -> void:
	if pressed_window and _is_colliding_with_window(): # Pressed
		var collision_point = raycast.get_collision_point()
		var raycast_origin = raycast.global_transform.origin
		var raycast_forward = _get_raycast_forward_direction()
		pressed_window.pressed_at_point(collision_point, raycast_origin, raycast_forward)
	elif pressed_window and !_is_colliding_with_window(): # Release
		var collision_point = raycast.get_collision_point()
		pressed_window.released_at_point(collision_point)
		if pressed_window:
			window_interaction_ended.emit(pressed_window)
		pressed_window = null
	elif !is_interacting and _is_colliding_with_window(): # Hover
		var collision_point = raycast.get_collision_point()
		var window = raycast.get_collider()
		window.hover_at_point(collision_point)

func _is_colliding_with_window() -> bool:
	if not raycast:
		return false
	return raycast.is_colliding() and raycast.get_collider().has_method("load_scene")

## Get the currently hovered window, if any
func get_hovered_window():
	if _is_colliding_with_window():
		return raycast.get_collider()
	return null

## Get the currently pressed/selected window, if any
func get_pressed_window():
	return pressed_window

## Get the forward direction vector for the raycast based on configuration
func _get_raycast_forward_direction() -> Vector3:
	if not raycast:
		return Vector3(0, -1, 0)  # Default fallback
	
	match raycast_forward_direction:
		ForwardDirection.NEGATIVE_Z:
			return -raycast.global_transform.basis.z
		ForwardDirection.NEGATIVE_Y:
			return -raycast.global_transform.basis.y
		ForwardDirection.POSITIVE_Y:
			return raycast.global_transform.basis.y
		ForwardDirection.POSITIVE_Z:
			return raycast.global_transform.basis.z
		ForwardDirection.NEGATIVE_X:
			return -raycast.global_transform.basis.x
		ForwardDirection.POSITIVE_X:
			return raycast.global_transform.basis.x
		ForwardDirection.CUSTOM:
			return raycast.global_transform.basis * raycast_custom_forward
		_:
			return -raycast.global_transform.basis.y  # Default to NEGATIVE_Y
