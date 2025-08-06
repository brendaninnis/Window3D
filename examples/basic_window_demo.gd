extends Node3D

@onready var window: UIWindow3D = $UIWindow3D

func _ready():
	# Connect to window signals to demonstrate functionality
	window.window_clicked.connect(_on_window_clicked)
	window.window_hovered.connect(_on_window_hovered)
	window.window_dragged.connect(_on_window_dragged)

func _on_load_ui_timer_timeout():
	# Load the interactive sample UI into the window
	if window.load_scene("res://addons/window3d/examples/sample_ui_with_script.tscn"):
		print("Sample UI loaded successfully!")
	else:
		# Fallback to basic UI if the scripted one doesn't exist
		window.load_scene("res://addons/window3d/examples/sample_ui.tscn")

func _on_window_clicked(point: Vector3):
	print("Window clicked at: ", point)

func _on_window_hovered(point: Vector3):
	# Uncomment to see hover events (can be spammy)
	# print("Window hovered at: ", point)
	pass

func _on_window_dragged(dragged_window: UIWindow3D, point: Vector3):
	print("Window dragged to: ", point)

# Simple mouse interaction for testing
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Cast a ray from camera through mouse position
			var camera = get_viewport().get_camera_3d()
			if camera:
				var from = camera.project_ray_origin(event.position)
				var to = from + camera.project_ray_normal(event.position) * 1000
				
				var space_state = get_world_3d().direct_space_state
				var query = PhysicsRayQueryParameters3D.create(from, to)
				var result = space_state.intersect_ray(query)
				
				if result and result.get("collider") == window:
					var point = result.get("position")
					window.hover_at_point(point)
					window.pressed_at_point(point, camera.global_position, camera.global_transform.basis.z)
	
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var camera = get_viewport().get_camera_3d()
			if camera:
				var from = camera.project_ray_origin(event.position)
				var to = from + camera.project_ray_normal(event.position) * 1000
				
				var space_state = get_world_3d().direct_space_state
				var query = PhysicsRayQueryParameters3D.create(from, to)
				var result = space_state.intersect_ray(query)
				
				if result:
					var point = result.get("position")
					window.released_at_point(point)
