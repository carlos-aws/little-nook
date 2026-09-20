class_name TidyItem
extends Button
## Godot's native drag-and-drop, plus tap-to-select for touch and keyboard users.

var item_id := ""
var category := ""
var art: Texture2D

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := TextureRect.new()
	preview.texture = art
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(82, 82)
	preview.size = Vector2(82, 82)
	preview.position = Vector2(-41, -41)
	var holder := Control.new()
	holder.add_child(preview)
	set_drag_preview(holder)
	return {"id": item_id, "category": category}
