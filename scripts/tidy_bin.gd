class_name TidyBin
extends Button

signal item_dropped(item_id: String, destination: String)
var category := ""

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("id") and data.has("category")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(data.id, category)
