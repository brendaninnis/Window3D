@tool
extends EditorPlugin

func _enter_tree():
	# Add the custom types
	add_custom_type(
		"UIWindow3D",
		"StaticBody3D",
		preload("res://addons/window3d/ui_window_3d.gd"),
		preload("res://addons/window3d/icons/window3d_icon.svg")
	)
	add_custom_type(
		"WindowInteractionManager",
		"Node",
		preload("res://addons/window3d/window_interaction_manager.gd"),
		preload("res://addons/window3d/icons/interaction_manager_icon.svg")
	)

func _exit_tree():
	# Clean up
	remove_custom_type("UIWindow3D")
	remove_custom_type("WindowInteractionManager")