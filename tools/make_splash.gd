extends SceneTree
## Godot accepts PNG boot images; retain the editable SVG as the source.
func _init() -> void:
	var image := Image.new()
	var error := image.load_svg_from_string(FileAccess.get_file_as_string("res://assets/art/icon.svg"), 2.0)
	if error == OK:
		error = image.save_png("res://assets/art/splash.png")
	print("Splash generated from original SVG: ", error_string(error))
	quit(error)
