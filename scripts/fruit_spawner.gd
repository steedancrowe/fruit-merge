extends Node2D

# Array of available fruit types and their progression
var fruit_types = ["blueberry", "strawberry", "apple", "orange", "melon"]
var fruit_scenes = {
	"blueberry": preload("res://scenes/blueberry.tscn"),
	"strawberry": preload("res://scenes/strawberry.tscn"),
	"apple": preload("res://scenes/apple.tscn"),
	"orange": preload("res://scenes/orange.tscn"),
	"melon": preload("res://scenes/melon.tscn")
}

var next_fruit_type: String
var preview_fruit: RigidBody2D
var projection_line: Line2D
var can_spawn: bool = true
var spawn_timer: Timer

func _ready():
	randomize()
	
	# Add spawn timer
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.wait_time = 0.5
	spawn_timer.connect("timeout", _on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	# Setup projection line
	projection_line = Line2D.new()
	projection_line.default_color = Color(255, 255, 255, 1.0)
	projection_line.width = 4.0
	projection_line.z_index = -1
	projection_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	projection_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	projection_line.texture = _create_dotted_line_texture()
	projection_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	add_child(projection_line)
	
	# get_tree().get_root().set_content_scale_mode(Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)
	# get_tree().get_root().set_content_scale_aspect(Window.CONTENT_SCALE_ASPECT_EXPAND)
	
	_select_next_fruit()

func _select_next_fruit():
	next_fruit_type = fruit_types[randi() % fruit_types.size()]
	
	# Remove previous preview if it exists
	if preview_fruit:
		preview_fruit.queue_free()
	
	# Create new preview fruit
	preview_fruit = fruit_scenes[next_fruit_type].instantiate()
	preview_fruit.position = Vector2(position.x, 50)
	# Disable physics and collision for preview
	preview_fruit.set_physics_process(false)
	preview_fruit.set_process(false)
	preview_fruit.collision_layer = 0
	preview_fruit.collision_mask = 0
	preview_fruit.freeze = true  # Prevents physics interactions
	add_child(preview_fruit)

func _process(_delta):
	if can_spawn and preview_fruit:
		var mouse_pos = get_viewport().get_mouse_position()
		var viewport_rect = get_viewport_rect()
		var clamped_x = clamp(mouse_pos.x, 0, viewport_rect.size.x)
		preview_fruit.position = Vector2(clamped_x, 50)
		
		# Update projection line
		projection_line.clear_points()
		projection_line.add_point(Vector2(clamped_x, preview_fruit.position.y))
		projection_line.add_point(Vector2(clamped_x, 600))

func spawn_fruit(spawn_position: Vector2):
	if can_spawn:
		var fruit = fruit_scenes[next_fruit_type].instantiate()
		var clamped_x = clamp(spawn_position.x, 0, get_viewport_rect().size.x)
		fruit.position = Vector2(clamped_x, 0)
		add_child(fruit)
		
		fruit.connect("fruit_landed", _on_fruit_landed)
		fruit.connect("fruits_merged", _on_fruits_merged)
		
		# Hide preview until fruit passes the spawner
		if preview_fruit:
			preview_fruit.visible = false
		projection_line.visible = false
		can_spawn = false

func _get_next_fruit_type(current_type: String) -> String:
	var index = fruit_types.find(current_type)
	if index != -1 and index < fruit_types.size() - 1:
		return fruit_types[index + 1]
	return ""

func _on_fruits_merged(merge_position: Vector2, current_type: String):
	var next_type = _get_next_fruit_type(current_type)
	if next_type != "":
		var new_fruit = fruit_scenes[next_type].instantiate()
		new_fruit.position = merge_position
		new_fruit.connect("fruit_landed", _on_fruit_landed)
		new_fruit.connect("fruits_merged", _on_fruits_merged)
		add_child(new_fruit)

func _create_dotted_line_texture() -> GradientTexture1D:
	# Create a gradient for dotted line effect
	var gradient = Gradient.new()
	gradient.set_color(0, Color(99, 178, 252, 1))
	gradient.set_color(0, Color(99, 178, 252, 1))
	gradient.set_color(1, Color(99, 178, 252, 0))
	gradient.set_color(1, Color(99, 178, 252, 0))
	
	# Create the texture
	var texture = GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 12  # Adjust this to change dot spacing
	return texture

func _on_fruit_landed():
	pass
	# Note: we don't set can_spawn = true here anymore
	# It will be set when the timer finishes

func _on_spawn_timer_timeout():
	can_spawn = true
	preview_fruit.visible = true
	projection_line.visible = true
	_select_next_fruit()

func _input(event):
	# Only handle input if we can spawn
	if can_spawn and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		spawn_fruit(event.position)
		spawn_timer.start()
