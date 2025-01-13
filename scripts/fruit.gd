extends RigidBody2D

signal fruit_landed
signal fruits_merged(pos, next_type)

func _ready():
	connect("fruit_landed", Callable(self, "_on_fruit_landed"))
	connect("body_entered", Callable(self, "_on_body_entered"))

func get_fruit_type() -> String:
	# Get the scene name without the extension
	return scene_file_path.get_file().trim_suffix(".tscn")

func _on_body_entered(body):
	# Add check to prevent double merging and stop melons from merging
	if not is_queued_for_deletion() and body is RigidBody2D and body.has_method("get_fruit_type"):
		var my_type = get_fruit_type()
		var other_type = body.get_fruit_type()
		
		# Don't merge if either fruit is a melon
		if my_type == "melon" or other_type == "melon":
			return
			
		if my_type == other_type and not body.is_queued_for_deletion():
			print("Match found! Merging ", my_type)
			var merge_position = (position + body.position) / 2
			emit_signal("fruits_merged", merge_position, my_type)
			queue_free()
			body.queue_free()

func _physics_process(_delta):
	if abs(linear_velocity.length()) < 0.1:
		emit_signal("fruit_landed")
		set_physics_process(false)

func _on_fruit_landed():
	pass  # We can leave this empty since the spawner handles the logic
