@tool
class_name UIWindow3D
extends StaticBody3D

## A 3D window for VR/AR applications with raycast-based interaction
##
## This class creates a 3D window that can display UI content and respond to
## raycast-based input. Perfect for VR/AR applications where traditional
## 2D UI isn't suitable.

## Window dimensions in meters
@export var width: float = 0.97: set = set_width
@export var height: float = 0.6: set = set_height

## Interaction settings
@export_group("Interaction")
## Pixels per meter - affects UI sharpness. Lower values for VR comfort (400-600), higher for desktop (800-1200)
@export var pixels_per_meter: int = 960: set = set_pixels_per_meter
## Milliseconds before click becomes drag
@export var click_to_drag_threshold_ms: int = 250
## Whether clicks on interactive controls should prevent window dragging
@export var prevent_drag_on_controls: bool = true

## Window material settings
@export_group("Material")
@export var transparency: BaseMaterial3D.Transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
@export var albedo_color: Color = Color.WHITE
## Enable mipmaps for better quality when scaled
@export var use_mipmaps: bool = true

## Advanced settings
@export_group("Advanced")
## Render target update mode for the internal viewport
@export var render_update_mode: SubViewport.UpdateMode = SubViewport.UPDATE_ALWAYS
## Automatically size window based on UI content (experimental)
@export var auto_size_to_content: bool = false
## Minimum size when auto-sizing (meters)
@export var min_auto_size: Vector2 = Vector2(0.3, 0.2)
## Maximum size when auto-sizing (meters)  
@export var max_auto_size: Vector2 = Vector2(2.0, 1.5)

signal window_clicked(point: Vector3)
signal window_hovered(point: Vector3)
signal window_dragged(window: UIWindow3D, point: Vector3)

# Static lookup table for interactive control types (O(1) performance)
static var _interactive_control_types := {
	"Button": true,
	"CheckBox": true,
	"OptionButton": true,
	"Slider": true,
	"SpinBox": true,
	"TextEdit": true,
	"LineEdit": true,
	"TabContainer": true,
	"ItemList": true,
	"Tree": true,
	"HScrollBar": true,
	"VScrollBar": true,
	"HSlider": true,
	"VSlider": true,
	"Range": true,
	"MenuButton": true,
	"PopupMenu": true,
	"ColorPicker": true,
	"FileDialog": true,
	"CodeEdit": true,
	"RichTextLabel": true,
	"GraphEdit": true,
	"GraphNode": true,
}

var window_mesh: MeshInstance3D
var collision_shape: CollisionShape3D
var viewport: SubViewport
var ui: Control
var ui_panel: Panel

var is_clicked: bool = false:
	set(value):
		is_clicked = value
		if value:
			click_start_time = Time.get_ticks_msec()
		else:
			click_start_time = 0.0
var click_start_time: float = 0.0
var is_control_clicked: bool = false
var is_dragged: bool = false:
	set(value):
		is_dragged = value
		if !value:
			drag_offset = Vector3.ZERO
var drag_offset: Vector3 = Vector3.ZERO

func _ready() -> void:
	if not Engine.is_editor_hint():
		_setup_window()

func _setup_window():
	if not _validate_configuration():
		return
	_create_viewport()
	_create_ui()
	_create_window_mesh()
	_create_collision_shape()

func _validate_configuration() -> bool:
	if width <= 0 or height <= 0:
		push_error("UIWindow3D: Width and height must be positive values")
		return false
	if pixels_per_meter < 50:
		push_error("UIWindow3D: pixels_per_meter too low, minimum is 50")
		return false
	if pixels_per_meter > 2000:
		push_warning(
				"UIWindow3D: pixels_per_meter very high (%d), may impact performance"
				% pixels_per_meter
		)
	return true

func set_width(value: float):
	width = value
	if is_inside_tree() and not Engine.is_editor_hint():
		_update_window_size()

func set_height(value: float):
	height = value
	if is_inside_tree() and not Engine.is_editor_hint():
		_update_window_size()

func set_pixels_per_meter(value: int):
	pixels_per_meter = value
	if is_inside_tree() and not Engine.is_editor_hint():
		_update_window_size()

func _update_window_size():
	if viewport:
		viewport.size = Vector2(width * pixels_per_meter, height * pixels_per_meter)
	if ui:
		ui.size = viewport.size
	if ui_panel:
		ui_panel.size = ui.size
	if window_mesh and window_mesh.mesh:
		(window_mesh.mesh as PlaneMesh).size = Vector2(width, height)
	if collision_shape and collision_shape.shape:
		(collision_shape.shape as BoxShape3D).size = Vector3(width, height, 0.02)

func _create_viewport():
	viewport = SubViewport.new()
	viewport.name = "Viewport"
	viewport.size = Vector2(width * pixels_per_meter, height * pixels_per_meter)
	viewport.render_target_update_mode = render_update_mode
	viewport.gui_embed_subwindows = true
	viewport.transparent_bg = true
	add_child(viewport)

func _create_ui():
	# Create a UI root and add it to the viewport
	ui = Control.new()
	ui.name = "UI"
	ui.size = viewport.size
	viewport.add_child(ui)
	# Create a background panel for the window
	ui_panel = Panel.new()
	ui_panel.name = "Panel"
	ui_panel.size = ui.size
	ui.add_child(ui_panel)

func _create_window_mesh():
	# Initialize the window mesh
	window_mesh = MeshInstance3D.new()
	window_mesh.name = "WindowMesh"
	# Create a plane mesh for the window
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(width, height)
	mesh.orientation = PlaneMesh.FACE_Z
	window_mesh.mesh = mesh
	# Create a material for the window
	var window_material = StandardMaterial3D.new()
	window_material.transparency = transparency
	window_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	window_material.albedo_color = albedo_color
	window_material.albedo_texture = viewport.get_texture()
	window_mesh.set_surface_override_material(0, window_material)
	# Add the window mesh to the scene
	add_child(window_mesh)

func _create_collision_shape():
	collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(width, height, 0.02)
	collision_shape.shape = box_shape
	add_child(collision_shape)

## Load a Control node as the window content
func load_ui(root: Control) -> bool:
	if not root:
		push_error("UIWindow3D: Cannot load null Control node")
		return false
		
	unload_scene()
	ui_panel.add_child(root)
	
	if auto_size_to_content:
		_auto_size_to_content()
		
	return true

## Load a scene file as the window content
func load_scene(scene_path: String) -> bool:
	unload_scene()
	var scene = load(scene_path)
	if not scene:
		push_error("UIWindow3D: Failed to load scene: " + scene_path)
		return false
		
	var scene_instance = scene.instantiate()
	if not scene_instance:
		push_error("UIWindow3D: Failed to instantiate scene: " + scene_path)
		return false
		
	ui_panel.add_child(scene_instance)
	
	if auto_size_to_content:
		_auto_size_to_content()
		
	return true

## Remove the current window content
func unload_scene() -> void:
	if ui_panel and ui_panel.get_child_count() > 0:
		var child = ui_panel.get_child(0)
		ui_panel.remove_child(child)
		child.queue_free()

## Get a UI node by path
func get_ui_node(path: String) -> Node:
	if ui_panel:
		return ui_panel.get_node(path)
	return null

## Handle hover interaction at a 3D point
func hover_at_point(point: Vector3) -> void:
	window_hovered.emit(point)
	var viewport_point = _convert_global_point_to_viewport(point)
	var event = InputEventMouseMotion.new()
	event.position = viewport_point
	viewport.push_input(event)

## Handle press interaction at a 3D point
func pressed_at_point(point: Vector3, origin: Vector3 = Vector3.ZERO, forward: Vector3 = Vector3.FORWARD) -> void:
	if is_clicked:
		_perform_drag_at_point(point, origin, forward)
	elif !is_clicked:
		_click_at_point(point)

func _perform_drag_at_point(point: Vector3, origin: Vector3, forward: Vector3) -> void:
	hover_at_point(point)
	
	if Time.get_ticks_msec() - click_start_time > click_to_drag_threshold_ms and (!is_control_clicked or !prevent_drag_on_controls):
		if !is_dragged:
			is_dragged = true
			drag_offset = global_transform.origin - point
			_release_click_at_point(Vector3.ZERO)
			window_dragged.emit(self, point)
		var window_position = origin + forward + Vector3(drag_offset.x, drag_offset.y, 0)
		look_at_from_position(window_position, window_position + forward)

func _click_at_point(point: Vector3) -> void:
	window_clicked.emit(point)
	var viewport_point = _convert_global_point_to_viewport(point)
	var event = InputEventMouseButton.new()
	event.position = viewport_point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	viewport.push_input(event)
	is_clicked = true
	is_control_clicked = _is_control_clicked()

func _is_control_clicked() -> bool:
	if not viewport:
		return false
	var hovered_control = viewport.gui_get_hovered_control()
	if hovered_control:
		# Check if the control is interactive (can receive input)
		return _is_interactive_control(hovered_control)
	return false

## Check if a control is interactive and should prevent window dragging
func _is_interactive_control(control: Control) -> bool:
	var control_class = control.get_class()
	return _interactive_control_types.has(control_class) or control.has_method("_gui_input")

func _release_click_at_point(point: Vector3) -> void:
	var viewport_point = _convert_global_point_to_viewport(point)
	var event = InputEventMouseButton.new()
	event.position = viewport_point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	viewport.push_input(event)

## Handle release interaction at a 3D point
func released_at_point(point: Vector3) -> void:
	if is_clicked and !is_dragged:
		_release_click_at_point(point)
	is_clicked = false
	is_control_clicked = false
	is_dragged = false

func _convert_global_point_to_viewport(point: Vector3) -> Vector2:
	var window_collision_point = global_transform.affine_inverse() * point
	var x = window_collision_point.x + width / 2
	var y = -window_collision_point.y + height / 2
	return Vector2(x * pixels_per_meter, y * pixels_per_meter)

## Get debug information about the window
func get_debug_info() -> String:
	var info = "UIWindow3D Debug Info:\n"
	info += "Size: %s x %s meters\n" % [width, height]
	info += "Viewport Size: %s\n" % [str(viewport.size) if viewport else "None"]
	info += "Is Clicked: %s\n" % is_clicked
	info += "Is Dragged: %s\n" % is_dragged
	var ui_root = _find_ui_root()
	if ui_root:
		info += "UI Root: %s\n" % ui_root.get_class()
	else:
		info += "UI Root: None\n"
	return info

func _find_ui_root() -> Control:
	if ui_panel and ui_panel.get_child_count() > 0:
		return ui_panel.get_child(0) as Control
	return null

## Automatically resize window to fit content (experimental)
func _auto_size_to_content():
	var ui_root = _find_ui_root()
	if not ui_root:
		return
		
	# Wait a frame for UI to settle
	await get_tree().process_frame
	
	var content_size = ui_root.get_rect().size
	if content_size.x > 0 and content_size.y > 0:
		# Convert from pixels to meters
		var new_size = content_size / pixels_per_meter
		# Clamp to min/max sizes
		new_size = new_size.clamp(min_auto_size, max_auto_size)
		
		width = new_size.x
		height = new_size.y
		_update_window_size()
