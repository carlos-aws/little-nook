class_name SaveStore
extends RefCounted

var path: String
var last_error := ""
var recovered := false

func _init(save_path := "user://progress.json") -> void:
	path = save_path

func load_progress(now: float) -> Dictionary:
	last_error = ""
	recovered = false
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var parsed: Variant = _read_json(candidate)
		var clean := NookState.validate(parsed, now)
		if not clean.is_empty():
			recovered = candidate.ends_with(".bak")
			return clean
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".corrupt")
		last_error = "The save could not be read. A fresh nook is open; the old file has been kept."
	return NookState.fresh(now)

func save_progress(data: Dictionary) -> bool:
	last_error = ""
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Progress could not be saved on this device."
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		last_error = "The device could not finish writing your progress."
		return false
	# Only replace the good backup when the previous primary save is valid.
	if FileAccess.file_exists(path):
		var previous: Variant = _read_json(path)
		if not NookState.validate(previous, Time.get_unix_time_from_system()).is_empty():
			var backup_error := DirAccess.copy_absolute(path, path + ".bak")
			if backup_error != OK:
				last_error = "The backup could not be written. Your previous save is safe."
				return false
	var err := DirAccess.rename_absolute(path + ".tmp", path)
	if err != OK:
		last_error = "Progress could not be saved. Your previous save is safe."
		return false
	return true

func _read_json(candidate: String) -> Variant:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(candidate)) != OK:
		return null
	return json.data
