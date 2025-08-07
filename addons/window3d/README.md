# Window3D Godot Plugin

A 3D windowing system for Godot 4 designed for VR/AR applications with raycast-based interaction.

Transform any Godot UI into an interactive 3D window that can be placed in your 3D world and controlled via raycasts - perfect for VR controllers, AR interaction, or any 3D application needing spatial UI.

## Features

- **🪟 3D Windows**: Create floating windows in 3D space with configurable dimensions
- **🎯 Raycast Interaction**: Hover, click, and drag windows using raycasts (perfect for VR controllers)
- **🎨 UI Content Loading**: Load any Godot UI scene or Control node into a window
- **✋ Smart Dragging**: Windows can be repositioned by dragging, with intelligent UI control detection
- **🎮 VR/AR Ready**: Optimized for XR applications with configurable pixel density
- **🔧 Easy Setup**: Simple node-based system with minimal configuration required
- **⚡ Performance Focused**: Efficient rendering suitable for real-time XR applications

## Installation

### Option 1: Download and Copy
1. Download or clone this repository
2. Copy the `addons/window3d` folder to your project's `addons/` directory
3. Go to **Project Settings > Plugins**
4. Enable the **"Window3D"** plugin

Then enable the plugin in **Project Settings > Plugins**.

## Quick Start

### 1. Basic Window Setup

Add a `UIWindow3D` node to your scene and load some UI content:

```gdscript
extends Node3D

@onready var window: UIWindow3D = $UIWindow3D

func _ready():
	# Load a UI scene file
	window.load_scene("res://my_ui.tscn")
	
	# Or create UI dynamically
	var button = Button.new()
	button.text = "Hello World!"
	button.pressed.connect(_on_button_pressed)
	window.load_ui(button)

func _on_button_pressed():
	print("Button in 3D window was clicked!")
```

### 2. VR/AR Interaction

Add a `WindowInteractionManager` to handle raycast-based interaction:

```gdscript
extends Node3D

@onready var window: UIWindow3D = $UIWindow3D
@onready var interaction_manager: WindowInteractionManager = $WindowInteractionManager
@onready var xr_controller: XRController3D = $XROrigin3D/RightController
@onready var raycast: RayCast3D = $XROrigin3D/RightController/RayCast3D

func _ready():
	# Set up window interaction
	interaction_manager.raycast = raycast
	
	# Configure raycast direction (optional - defaults to NEGATIVE_Y for VR)
	interaction_manager.raycast_forward_direction = WindowInteractionManager.ForwardDirection.NEGATIVE_Y
	
	# Connect controller input to interaction manager
	xr_controller.button_pressed.connect(_on_controller_button_pressed)
	xr_controller.button_released.connect(_on_controller_button_released)
	
	# Load your UI
	window.load_scene("res://ui/main_menu.tscn")

func _on_controller_button_pressed(button: String):
	if button == "trigger_click":
		interaction_manager.handle_interaction_pressed()

func _on_controller_button_released(button: String):
	if button == "trigger_click":
		interaction_manager.handle_interaction_released()
```

### 3. Window Configuration

Configure the window properties in the inspector or via code:

```gdscript
func _ready():
	# Configure window size (in meters)
	window.width = 1.2
	window.height = 0.8
	
	# Adjust pixel density (higher = sharper, but more memory)
	window.pixels_per_meter = 800  # Good for desktop
	window.pixels_per_meter = 500  # Better for VR performance
	
	# Configure interaction behavior
	window.click_to_drag_threshold_ms = 300  # Slower for VR precision
	window.prevent_drag_on_controls = true   # Don't drag when clicking buttons
```

## API Reference

### UIWindow3D

The main window component that creates a 3D window with UI content.

**Key Properties:**
- `width: float` - Window width in meters (default: 0.97)
- `height: float` - Window height in meters (default: 0.6)  
- `pixels_per_meter: int` - UI pixel density (default: 960)
- `click_to_drag_threshold_ms: int` - Time before click becomes drag (default: 250ms)
- `prevent_drag_on_controls: bool` - Prevent dragging when clicking UI controls (default: true)

**Key Methods:**
- `load_scene(scene_path: String) -> bool` - Load a UI scene file
- `load_ui(control: Control) -> bool` - Load a Control node directly
- `unload_scene()` - Remove current content
- `get_ui_node(path: String) -> Node` - Get a UI node by path

**Signals:**
- `window_clicked(point: Vector3)` - Emitted when window is clicked
- `window_hovered(point: Vector3)` - Emitted when window is hovered  
- `window_dragged(window: UIWindow3D, point: Vector3)` - Emitted when window is dragged

### WindowInteractionManager

Manages raycast-based interaction with UIWindow3D objects.

**Key Properties:**
- `raycast: RayCast3D` - The raycast to use for interaction
- `raycast_forward_direction: ForwardDirection` - Which axis represents forward for the raycast
- `raycast_custom_forward: Vector3` - Custom forward direction (when using CUSTOM mode)

**Key Methods:**
- `handle_interaction_pressed()` - Call when interaction action is pressed
- `handle_interaction_released()` - Call when interaction action is released

**Signals:**
- `window_interaction_started(window)` - Window interaction begins
- `window_interaction_ended(window)` - Window interaction ends
- `window_clicked(window, point: Vector3)` - Window was clicked (not dragged)

## Examples

Check the `examples/` folder for complete demo scenes:
- **basic_window_demo.tscn** - Simple desktop window example
- **vr_interaction_demo.tscn** - VR controller interaction example

## Raycast Direction Configuration

The `WindowInteractionManager` supports different raycast orientations for various setups:

```gdscript
# VR controllers pointing downward (default)
interaction_manager.raycast_forward_direction = WindowInteractionManager.ForwardDirection.NEGATIVE_Y

# Desktop mouse raycast going forward
interaction_manager.raycast_forward_direction = WindowInteractionManager.ForwardDirection.NEGATIVE_Z

# Custom direction (e.g., angled controller)
interaction_manager.raycast_forward_direction = WindowInteractionManager.ForwardDirection.CUSTOM
interaction_manager.raycast_custom_forward = Vector3(0.5, -0.8, 0.3).normalized()
```

**Direction Options:**
- `NEGATIVE_Y`: Down (-Y) - typical VR controllers
- `NEGATIVE_Z`: Forward (-Z) - typical desktop raycasts  
- `POSITIVE_Y`: Up (+Y) - upward pointing devices
- `POSITIVE_Z`: Backward (+Z) - reverse pointing
- `NEGATIVE_X`: Left (-X) - left pointing
- `POSITIVE_X`: Right (+X) - right pointing
- `CUSTOM`: User-defined direction via `raycast_custom_forward`

## Tips for VR/AR Development

### Performance Optimization
```gdscript
# For VR, use lower pixel density for better performance
window.pixels_per_meter = 500

# Update mode can be changed if window content is static
window.render_update_mode = SubViewport.UPDATE_ONCE
```

### VR-Friendly Sizing
```gdscript
# Good VR window sizes (readable at arm's length)
window.width = 1.0   # 1 meter wide
window.height = 0.6  # 0.6 meters tall

# Position at comfortable VR distance
window.position = Vector3(0, 1.5, -1.5)  # Eye level, arm's reach
```

## Requirements

- **Godot 4.0+**
- For VR/AR: **OpenXR plugin** recommended

## License

MIT License - feel free to use in commercial and personal projects.

## Contributing

Issues and pull requests welcome! This plugin is designed to be simple and focused.

### Development Setup
```bash
git clone https://github.com/yourusername/window3d-plugin.git
cd window3d-plugin
# Open in Godot and run the example scenes
```

---

**Made with ❤️ for the Godot VR/AR community**
