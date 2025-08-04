extends Node3D

@onready var window = $UIWindow3D
@onready var interaction_manager = $WindowInteractionManager
@onready var controller: XRController3D = $XROrigin3D/RightController
@onready var raycast: RayCast3D = $XROrigin3D/RightController/RayCast3D

func _ready():
	# Set up the interaction manager
	interaction_manager.raycast = raycast
	
	# Connect to interaction signals
	interaction_manager.window_interaction_started.connect(_on_window_interaction_started)
	interaction_manager.window_interaction_ended.connect(_on_window_interaction_ended)
	interaction_manager.window_clicked.connect(_on_window_clicked)
	interaction_manager.window_drag_started.connect(_on_window_drag_started)
	
	# Connect controller input (you'll need to implement this based on your XR setup)
	# For example:
	# controller.button_pressed.connect(_on_controller_button_pressed)
	# controller.button_released.connect(_on_controller_button_released)

func _on_load_ui_timer_timeout():
	# Load the interactive sample UI into the window
	if window.load_scene("res://addons/window3d/examples/sample_ui_with_script.tscn"):
		print("Interactive UI loaded successfully!")
	else:
		# Fallback to basic UI if the scripted one doesn't exist
		window.load_scene("res://addons/window3d/examples/sample_ui.tscn")

func _on_window_interaction_started(window):
	print("Window interaction started: ", window.name)

func _on_window_interaction_ended(window):
	print("Window interaction ended: ", window.name)

func _on_window_clicked(window, point: Vector3):
	print("Window clicked: ", window.name, " at ", point)

func _on_window_drag_started(window, point: Vector3):
	print("Window drag started: ", window.name, " at ", point)

# Example input handling - adapt this to your XR input system
func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_SPACE:
				interaction_manager.handle_interaction_pressed()
		else:
			if event.keycode == KEY_SPACE:
				interaction_manager.handle_interaction_released()

# If using OpenXR, you might use something like this instead:
# func _on_controller_button_pressed(button_name: String):
#	if button_name == "trigger_click":
#		interaction_manager.handle_interaction_pressed()

# func _on_controller_button_released(button_name: String):
#	if button_name == "trigger_click":
#		interaction_manager.handle_interaction_released()
