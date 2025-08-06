extends VBoxContainer

@onready var count_label: Label = $Content/CountLabel
@onready var slider_label: Label = $Content/SliderLabel
@onready var action_button: Button = $Content/ActionButton

var click_count: int = 0

func _ready():
	print("Sample UI loaded in 3D window!")

func _on_action_button_pressed():
	click_count += 1
	count_label.text = "Button clicks: %d" % click_count
	print("Action button pressed! Count: ", click_count)

func _on_check_box_toggled(toggled_on: bool):
	if toggled_on:
		print("Debug mode enabled")
		action_button.text = "Debug Action"
	else:
		print("Debug mode disabled")
		action_button.text = "Test Action"

func _on_slider_value_changed(value: float):
	slider_label.text = "Slider value: %d" % int(value)
	print("Slider value changed: ", value)