extends Control
## Fixed logical canvas with aspect-preserving scaling: mouse, touch and keyboard.

const CREAM := Color("#faf6ed")
const PAPER := Color("#fffcf5")
const INK := Color("#584c42")
const MUTED := Color("#918577")
const LINE := Color("#e9dfd0")
const SAGE := Color("#83956e")
const PALE_SAGE := Color("#eaf0df")
const PEACH := Color("#f3dfd0")
const GOLD := Color("#dec08a")
const SUBJECTS := {
	"math": {"title": "Snack time", "label": "MATHS", "icon": "carrot", "color": "#f4e3d1", "need": "food", "verb": "Let's count something delicious.", "done": "A full tummy and a happy heart."},
	"english": {"title": "Story time", "label": "ENGLISH", "icon": "book", "color": "#e6ebdc", "need": "joy", "verb": "Little words, big adventures.", "done": "A new word, a new little wonder."},
	"science": {"title": "Wonder time", "label": "SCIENCE", "icon": "leaf", "color": "#eee4ea", "need": "curiosity", "verb": "There's a whole world to discover.", "done": "The world feels a little bigger now."},
}

var body_font: Font
var title_font: Font
var state: Dictionary
var store := SaveStore.new()
var rng := RandomNumberGenerator.new()
var screen := "home"
var page: Control
var popup: Control
var toast_panel: Panel
var toast_timer: SceneTreeTimer
var audio: AudioStreamPlayer
var demo := false
var elapsed := 0.0
var autosave_elapsed := 0.0
var pet_texture: TextureRect
var pet_origin := Vector2.ZERO
var room_time_badge: Label
var current_subject := ""
var questions: Array = []
var question_index := 0
var question_misses := 0
var wrong_choices: Array[String] = []
var first_try := true
var answer_locked := false
var round_finished := false
var choice_buttons: Array[Button] = []
var feedback_label: Label
var continue_button: Button
var tidy_items: Array = []
var tidy_selected := ""
var tidy_misses := false
var tidy_sorted := 0
var last_reward: Dictionary = {}
var test_failures := 0
var toast_duration := 4.5

func _ready() -> void:
	var body_variation := FontVariation.new()
	body_variation.base_font = preload("res://assets/fonts/Nunito.ttf")
	body_variation.variation_opentype = {2003265652: 550.0}
	body_font = body_variation
	var title_variation := FontVariation.new()
	title_variation.base_font = preload("res://assets/fonts/Fraunces.ttf")
	title_variation.variation_opentype = {2003265652: 530.0, 1869640570: 36.0, 1397704276: 70.0, 1464815179: 1.0}
	title_font = title_variation
	rng.randomize()
	demo = "--demo" in OS.get_cmdline_user_args() or "--ui-test" in OS.get_cmdline_user_args()
	if "--ui-test" in OS.get_cmdline_user_args():
		toast_duration = .05
	state = NookState.fresh(now()) if demo else store.load_progress(now())
	NookState.tick(state, now())
	if demo:
		state.today.stars = 2
		state.stars = 5
		state.coins = 24
	audio = AudioStreamPlayer.new()
	audio.volume_db = -7
	add_child(audio)
	theme = Theme.new()
	theme.default_font = body_font
	theme.default_font_size = 18
	for control_type in ["Button", "CheckButton", "LineEdit", "OptionButton", "PopupMenu"]:
		theme.set_color("font_color", control_type, INK)
		theme.set_color("font_hover_color", control_type, INK)
		theme.set_color("font_pressed_color", control_type, INK)
		theme.set_color("font_placeholder_color", control_type, MUTED)
	theme.set_stylebox("panel", "PopupMenu", _style(PAPER, 12))
	theme.set_stylebox("focus", "LineEdit", _style(Color(0,0,0,0), 12, SAGE, 2))
	_render()
	if store.recovered:
		_toast("Your nook was restored from its backup.")
	elif not store.last_error.is_empty():
		_toast(store.last_error)
	if "--ui-test" in OS.get_cmdline_user_args():
		_run_ui_tests.call_deferred()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture.call_deferred(arg.trim_prefix("--capture="))
		if arg.begins_with("--screen="):
			_navigate(arg.trim_prefix("--screen="))
	if "--smoke" in OS.get_cmdline_user_args():
		get_tree().create_timer(1.0).timeout.connect(func(): get_tree().quit())

func now() -> float:
	return Time.get_unix_time_from_system()

func _process(delta: float) -> void:
	elapsed += delta
	autosave_elapsed += delta
	if is_instance_valid(pet_texture):
		pet_texture.position.y = pet_origin.y + (sin(elapsed * 1.8) * 2.0 if state.settings.motion else 0.0)
	if autosave_elapsed > 30.0:
		autosave_elapsed = 0.0
		NookState.tick(state, now())
		_save()
		if screen == "home" and not is_instance_valid(popup):
			_render()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not state.is_empty():
			_save()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(popup):
			_close_popup()
		elif screen in ["lesson", "tidy"] and not round_finished:
			_confirm_leave("home")
		else:
			_navigate("home")
		get_viewport().set_input_as_handled()

func _save() -> void:
	if not demo and not store.save_progress(state):
		_toast(store.last_error)

func _style(color: Color, radius := 18, border := LINE, width := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	return s

func _panel(parent: Node, rect: Rect2, color := PAPER, radius := 20, border := LINE) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", _style(color, radius, border))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func _label(parent: Node, text: String, rect: Rect2, font_size := 18, color := INK, heading := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.clip_text = true
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_override("font", title_font if heading else body_font)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func _wrapped(parent: Node, text: String, rect: Rect2, font_size := 18, color := INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := _label(parent, text, rect, font_size, color, false, align)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size = rect.size
	return node

func _image(parent: Node, icon_name: String, rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture = load("res://assets/art/%s.svg" % icon_name)
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func _button(parent: Node, text: String, rect: Rect2, callback: Callable, color := PAPER, font_size := 18) -> Button:
	var b := Button.new()
	_setup_button(b, text, rect, color, font_size)
	parent.add_child(b)
	b.pressed.connect(func():
		_sound("tap")
		callback.call()
	)
	return b

func _setup_button(b: Button, text: String, rect: Rect2, color := PAPER, font_size := 18) -> void:
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.add_theme_stylebox_override("normal", _style(color, 16))
	b.add_theme_stylebox_override("hover", _style(color.lightened(.04), 16, Color("#b4bea0"), 2))
	b.add_theme_stylebox_override("pressed", _style(color.darkened(.045), 16, SAGE, 2))
	b.add_theme_stylebox_override("focus", _style(Color(0,0,0,0), 16, SAGE, 3))
	b.add_theme_stylebox_override("disabled", _style(Color("#f0ece2"), 16))

func _primary(parent: Node, text: String, rect: Rect2, callback: Callable) -> Button:
	var b := _button(parent, text, rect, callback, SAGE, 18)
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(key, PAPER)
	return b

func _sound(sound_name: String) -> void:
	if state.settings.sound and DisplayServer.get_name() != "headless":
		audio.stop()
		audio.stream = load("res://assets/audio/%s.wav" % sound_name)
		audio.play()

func _render() -> void:
	if is_instance_valid(page):
		remove_child(page)
		page.queue_free()
	pet_texture = null
	page = Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	move_child(page, 0)
	_panel(page, Rect2(0, 0, 1440, 900), CREAM, 0, CREAM)
	_panel(page, Rect2(0, 0, 248, 900), Color("#f2ede2"), 0, Color("#f2ede2"))
	_image(page, "home", Rect2(26, 28, 44, 44))
	_label(page, "little nook", Rect2(76, 24, 166, 50), 29, INK, true)
	_label(page, "small moments, happy hearts", Rect2(30, 78, 207, 23), 12, MUTED)
	_label(page, "MAKE A LITTLE ROOM", Rect2(31, 138, 197, 24), 11, MUTED)
	var nav := [
		["home", "My cozy home", "home"],
		["lessons", "Little lessons", "book"],
		["tidy", "Tidy time", "broom"],
		["shop", "The nook shop", "bag"],
		["journal", "Our little story", "heart"],
	]
	for i in range(nav.size()):
		var item: Array = nav[i]
		var active: bool = screen == item[0] or (screen == "lesson" and item[0] == "lessons")
		var b := _button(page, "", Rect2(21, 178+i*62, 207, 51), func(): _navigate(item[0]), Color("#e2e8d6") if active else Color("#f2ede2"), 17)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_label(b, item[1], Rect2(53, 10, 150, 31), 17)
		if not active:
			b.add_theme_stylebox_override("normal", _style(Color("#f2ede2"), 13, Color("#f2ede2")))
		_image(b, item[2], Rect2(13, 10, 31, 31))
	_sidebar()
	_label(page, "A LITTLE LEARNING. A LITTLE CARE.", Rect2(286, 26, 660, 36), 12, MUTED)
	var coin_button := _button(page, "", Rect2(1065, 24, 104, 45), func(): _navigate("shop"), PAPER, 19)
	_image(coin_button, "coin", Rect2(12, 8, 29, 29))
	_label(coin_button, str(state.coins), Rect2(47, 7, 48, 31), 19)
	var star_button := _button(page, "", Rect2(1180, 24, 120, 45), func(): _navigate("journal"), PAPER, 17)
	_image(star_button, "star", Rect2(10, 8, 28, 28))
	_label(star_button, "%d / %d" % [state.today.stars, state.settings.goal], Rect2(46, 8, 69, 29), 17)
	var sound_button := _button(page, "", Rect2(1314, 24, 43, 45), _toggle_sound)
	sound_button.tooltip_text = "Sound on" if state.settings.sound else "Sound off"
	var sound_icon := _image(sound_button, "sound", Rect2(9, 9, 26, 26))
	sound_icon.modulate.a = 1.0 if state.settings.sound else .3
	var settings_button := _button(page, "", Rect2(1368, 24, 43, 45), _parent_gate)
	settings_button.tooltip_text = "Grown-ups' corner"
	_image(settings_button, "settings", Rect2(9, 9, 26, 26))
	_panel(page, Rect2(286, 87, 1125, 1), LINE, 0, LINE)
	match screen:
		"home": _home()
		"lessons": _lessons_page()
		"lesson": _lesson_page()
		"tidy": _tidy_page()
		"shop": _shop_page()
		"journal": _journal_page()
	_label(page, "Made for unhurried days.", Rect2(288, 865, 400, 22), 13, MUTED)
	_label(page, "Little Nook  /  a place to grow", Rect2(1030, 865, 377, 22), 12, MUTED, false, HORIZONTAL_ALIGNMENT_RIGHT)

func _sidebar() -> void:
	var card := _panel(page, Rect2(23, 536, 202, 213), Color("#fbf6e9"), 17)
	_image(card, "plant", Rect2(14, 15, 44, 48))
	_label(card, "GROWING TOGETHER", Rect2(64, 17, 132, 24), 10, MUTED)
	_label(card, state.name + "'s story", Rect2(64, 39, 129, 26), 16, INK, true)
	_label(card, NookState.STAGES[state.stage].name, Rect2(16, 85, 175, 28), 20, INK, true)
	var next_stars: int = NookState.STAGES[mini(state.stage+1, NookState.STAGES.size()-1)].stars
	_panel(card, Rect2(16, 128, 169, 7), Color("#e8e1cd"), 3, Color("#e8e1cd"))
	_panel(card, Rect2(16, 128, maxf(7.0, 169.0*minf(1.0, float(state.stars)/maxi(1,next_stars))), 7), SAGE, 3, SAGE)
	_label(card, "%d / %d little stars" % [state.stars, next_stars], Rect2(16, 141, 168, 23), 13, MUTED)
	_wrapped(card, "Good things take a little time.", Rect2(16, 169, 170, 33), 12, MUTED)
	_image(page, "heart", Rect2(31, 790, 21, 21))
	_label(page, "A happy place to come back to.", Rect2(60, 785, 166, 32), 11, MUTED)
	_label(page, "Progress saves on this device.", Rect2(31, 826, 204, 22), 11, MUTED)

func _heading(title: String, subtitle: String) -> void:
	_label(page, title, Rect2(286, 105, 1095, 56), 37, INK, true)
	_label(page, subtitle, Rect2(288, 163, 1100, 27), 17, MUTED)

func _home() -> void:
	_heading("Good things grow here.", "A soft place to land, a little friend to care for.")
	var room := _panel(page, Rect2(286, 211, 1125, 430), Color("#f1e8d9"), 24, Color("#e6d9c5"))
	_label(room, "PIP'S LITTLE PLACE".replace("PIP", state.name.to_upper()), Rect2(27, 21, 320, 25), 11, MUTED)
	_image(room, "leaf", Rect2(27, 71, 40, 43))
	_label(room, "Room to\nbe yourself.", Rect2(28, 116, 230, 83), 28, INK, true)
	_wrapped(room, "A book, a warm snack,\nand your favourite company.", Rect2(29, 209, 192, 72), 15, MUTED)
	_image(page, "room", Rect2(493, 198, 899, 454))
	# The room texture is aspect fitted; positions below follow its inner canvas.
	pet_texture = _image(page, "pip_sleep" if state.sleeping else "pip", Rect2(836, 456, 140, 129))
	pet_origin = pet_texture.position
	var pet_button := _button(page, "", Rect2(839, 449, 132, 140), _pet)
	pet_button.tooltip_text = "Say hello to " + state.name
	for key in ["normal", "hover", "pressed"]:
		pet_button.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	_button(room, "  Wake Pip" if state.sleeping else "  A little rest", Rect2(28, 340, 172, 49), _sleep, PAPER, 15).text = ("Wake " + state.name) if state.sleeping else "A little rest"
	var day_tag := _panel(page, Rect2(1187, 229, 201, 38), Color("#fffaee"), 18)
	_image(day_tag, "moon" if state.sleeping else "flower", Rect2(9, 5, 27, 27))
	room_time_badge = _label(day_tag, "Quiet time" if state.sleeping else "A lovely little day", Rect2(43, 5, 148, 27), 13, MUTED)
	_room_decorations()
	var speech := "Zzz... growing takes rest." if state.sleeping else "I'm so glad you're here."
	var bubble := _panel(page, Rect2(816, 416, 241, 43), Color("#fffaf0"), 17)
	_label(bubble, speech, Rect2(8, 4, 225, 35), 15, INK, false, HORIZONTAL_ALIGNMENT_CENTER)
	_label(page, "A LITTLE CARE GOES A LONG WAY", Rect2(290, 657, 590, 30), 11, MUTED)
	_label(page, "Pick a moment to share", Rect2(1090, 658, 316, 28), 13, MUTED, false, HORIZONTAL_ALIGNMENT_RIGHT)
	var activities := [
		["math", "Snack time", "Count & care", "carrot", "#f4e3d1", "food"],
		["english", "Story time", "Read & play", "book", "#e6ebdc", "joy"],
		["science", "Wonder time", "Look & learn", "leaf", "#eee4ea", "curiosity"],
		["tidy", "Tidy time", "Sort & settle", "broom", "#f4e9ce", "tidiness"],
	]
	for i in range(4):
		var a: Array = activities[i]
		var b := _button(page, "", Rect2(286+i*286, 700, 267, 140), func(): _navigate("tidy") if a[0] == "tidy" else _start_lesson(a[0]), PAPER)
		_panel(b, Rect2(15, 15, 54, 54), Color(a[4]), 16, Color(a[4]))
		_image(b, a[3], Rect2(20, 20, 44, 44))
		_label(b, a[1], Rect2(82, 17, 170, 29), 21, INK, true)
		_label(b, a[2], Rect2(83, 49, 173, 22), 13, MUTED)
		_label(b, "Feeling " + _need_word(state.needs[a[5]]), Rect2(17, 89, 191, 20), 12, MUTED)
		_image(b, "arrow", Rect2(230, 43, 20, 20))
		_panel(b, Rect2(17, 117, 232, 5), Color("#eee8dc"), 3, Color("#eee8dc"))
		_panel(b, Rect2(17, 117, 232*state.needs[a[5]]/100.0, 5), Color("#b2be9e"), 3, Color("#b2be9e"))

func _room_decorations() -> void:
	var placements := {
		"plant": Rect2(861, 362, 42, 53), "cushion": Rect2(997, 438, 48, 42),
		"flower": Rect2(753, 359, 51, 54), "lamp": Rect2(1200, 434, 85, 85),
		"picture": Rect2(1216, 328, 47, 59), "mushroom": Rect2(768, 555, 46, 49),
	}
	for item_id in state.equipped:
		_image(page, item_id, placements[item_id])

func _need_word(value: float) -> String:
	if value >= 80: return "lovely"
	if value >= 55: return "good"
	return "a little low"

func _pet() -> void:
	_sound("soft")
	if state.sleeping:
		_toast(state.name + " is having a lovely little dream.")
	else:
		var lines := ["You make this place feel like home.", "Shall we learn something together?", "I saved you the coziest spot.", "Small steps count, too."]
		_toast(lines[rng.randi_range(0, lines.size()-1)])
		if state.settings.motion:
			var tween := create_tween()
			pet_texture.pivot_offset = pet_texture.size / 2
			tween.tween_property(pet_texture, "scale", Vector2(1.07,.95), .12)
			tween.tween_property(pet_texture, "scale", Vector2.ONE, .2)

func _sleep() -> void:
	NookState.tick(state, now())
	state.sleeping = not state.sleeping
	_save()
	_render()
	_toast("Rest restores energy over time. You can wake %s whenever you like." % state.name if state.sleeping else state.name + " is ready for a little adventure.")

func _navigate(destination: String) -> void:
	if destination == screen:
		return
	if screen in ["lesson", "tidy"] and not round_finished and destination != screen:
		_confirm_leave(destination)
		return
	_go(destination)

func _go(destination: String) -> void:
	_clear_toast()
	_close_popup()
	if destination not in ["home", "lessons", "shop", "journal", "tidy"]:
		destination = "home"
	screen = destination
	if screen == "tidy":
		_begin_tidy()
	_render()

func _confirm_leave(destination: String) -> void:
	var p := _modal("One little pause?", "This activity's reward is earned when you finish.\nYour earlier progress is already saved.")
	_button(p, "Keep going", Rect2(36, 220, 221, 52), _close_popup)
	_primary(p, "Leave activity", Rect2(275, 220, 221, 52), func(): _go(destination))

func _lessons_page() -> void:
	_heading("Little lessons, lovely moments.", "Three small questions. A little care. Something new to carry with you.")
	var subjects := ["math", "english", "science"]
	for i in range(3):
		var subject: String = subjects[i]
		var info: Dictionary = SUBJECTS[subject]
		var p := _panel(page, Rect2(286+i*382, 226, 361, 446), PAPER, 24)
		_panel(p, Rect2(19, 18, 323, 184), Color(info.color), 18, Color(info.color))
		_image(p, info.icon, Rect2(119, 44, 123, 123))
		_label(p, info.label, Rect2(24, 222, 314, 25), 12, MUTED)
		_label(p, info.title, Rect2(24, 257, 314, 47), 30, INK, true)
		_wrapped(p, info.verb, Rect2(24, 312, 304, 42), 16, MUTED)
		var level: int = state.settings.level if state.settings.level > 0 else state.skills[subject]
		_label(p, "Level %d  ·  3 gentle questions" % level, Rect2(24, 354, 308, 27), 14, MUTED)
		_primary(p, "Let's begin", Rect2(24, 390, 312, 40), func(): _start_lesson(subject))
	var note := _panel(page, Rect2(286, 698, 1125, 119), PALE_SAGE, 20, PALE_SAGE)
	_image(note, "heart", Rect2(25, 24, 59, 59))
	_label(note, "It's okay to try again.", Rect2(111, 20, 921, 34), 25, INK, true)
	_label(note, "No timers, no lost stars. We'll figure it out together.", Rect2(112, 66, 928, 27), 17, MUTED)

func _start_lesson(subject: String) -> void:
	if state.sleeping:
		state.sleeping = false
	current_subject = subject
	var level: int = state.settings.level if state.settings.level > 0 else state.skills[subject]
	questions = Lessons.build(subject, level, rng)
	for question in questions:
		for field in ["prompt", "answer", "fact"]:
			question[field] = question[field].replace("Pip", state.name)
		for i in range(question.choices.size()):
			question.choices[i] = question.choices[i].replace("Pip", state.name)
	question_index = 0
	question_misses = 0
	wrong_choices.clear()
	first_try = true
	answer_locked = false
	round_finished = false
	screen = "lesson"
	_render()

func _lesson_page() -> void:
	var info: Dictionary = SUBJECTS[current_subject]
	_heading(info.title + " with " + state.name + ".", info.verb)
	var p := _panel(page, Rect2(286, 214, 1125, 623), PAPER, 24)
	_label(p, info.label + "  /  QUESTION %d OF 3" % (question_index+1), Rect2(34, 23, 807, 32), 13, MUTED)
	_button(p, "Read aloud", Rect2(927, 19, 163, 43), _read_aloud, Color(info.color), 15)
	for i in range(3):
		_panel(p, Rect2(36+i*354, 69, 344, 5), SAGE if i <= question_index else LINE, 2)
	var q: Dictionary = questions[question_index]
	_panel(p, Rect2(465, 100, 192, 160), Color(info.color), 28, Color(info.color))
	_image(p, q.icon, Rect2(497, 113, 127, 127))
	_wrapped(p, q.prompt, Rect2(90, 276, 945, 104), 28, INK, HORIZONTAL_ALIGNMENT_CENTER)
	choice_buttons.clear()
	for i in range(q.choices.size()):
		var choice: String = q.choices[i]
		var b := _button(p, choice, Rect2(37+i*355, 405, 339, 78), func(): _answer(choice), PAPER, 21)
		choice_buttons.append(b)
	feedback_label = _wrapped(p, "Take your time. You've got this.", Rect2(39, 503, 807, 77), 17, MUTED)
	continue_button = _primary(p, "Next little step", Rect2(855, 523, 233, 56), _next_question)
	continue_button.visible = false
	_update_question_feedback()

func _answer(choice: String) -> void:
	if answer_locked or round_finished:
		return
	var q: Dictionary = questions[question_index]
	if choice == q.answer:
		answer_locked = true
		_sound("correct")
	else:
		first_try = false
		question_misses += 1
		wrong_choices.append(choice)
		_sound("soft")
	_update_question_feedback()
	if answer_locked:
		continue_button.grab_focus()

func _update_question_feedback() -> void:
	var q: Dictionary = questions[question_index]
	if answer_locked:
		for b in choice_buttons:
			b.disabled = true
			if b.text == q.answer:
				b.add_theme_stylebox_override("disabled", _style(PALE_SAGE, 16, SAGE, 2))
		feedback_label.text = "That's it! " + q.fact
		feedback_label.add_theme_color_override("font_color", SAGE)
		continue_button.text = "Finish & care" if question_index == 2 else "Next little step"
		continue_button.visible = true
	else:
		if question_misses > 0:
			feedback_label.text = "A good try. Have another look!" if question_misses < 2 else "Let's try \"%s\". %s" % [q.answer, q.fact]
		for b in choice_buttons:
			b.disabled = b.text in wrong_choices
			if question_misses >= 2 and b.text == q.answer:
				b.add_theme_stylebox_override("normal", _style(PALE_SAGE, 16, SAGE, 2))

func _next_question() -> void:
	if not answer_locked or round_finished:
		return
	if question_index == 2:
		_finish_activity(current_subject, first_try)
	else:
		question_index += 1
		question_misses = 0
		wrong_choices.clear()
		answer_locked = false
		_render()

func _read_aloud() -> void:
	var q: Dictionary = questions[question_index]
	var text: String = q.prompt + ". " + ". ".join(q.choices)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if ('speechSynthesis' in window) { speechSynthesis.cancel(); const u = new SpeechSynthesisUtterance(%s); u.rate = 0.85; speechSynthesis.speak(u); }" % JSON.stringify(text))
	else:
		var voices := DisplayServer.tts_get_voices_for_language("en")
		if voices.is_empty():
			_toast("Read-aloud needs an English voice installed on this device.")
		else:
			DisplayServer.tts_stop()
			DisplayServer.tts_speak(text, voices[0], 65, 1.0, .85)

func _finish_activity(subject: String, perfect: bool) -> void:
	if round_finished:
		return
	round_finished = true
	last_reward = NookState.complete(state, subject, perfect, now())
	_save()
	_sound("complete")
	_render()
	var done: String = "Everything has a happy little home." if subject == "tidy" else SUBJECTS[subject].done
	var p := _modal("A little moment, well spent.", done, 570, 430)
	_image(p, "pip", Rect2(38, 161, 151, 140))
	_image(p, "star", Rect2(221, 174, 47, 47))
	_label(p, "+%d star" % last_reward.stars, Rect2(281, 174, 230, 44), 25, INK, true)
	_image(p, "coin", Rect2(224, 231, 42, 42))
	_label(p, "+%d leaf coins" % last_reward.coins, Rect2(281, 232, 235, 41), 22, INK, true)
	_label(p, "Daily stars are full. Practice still brings care!" if last_reward.stars == 0 else "A little learning helped your friend feel lovely.", Rect2(30, 309, 510, 31), 14, MUTED, false, HORIZONTAL_ALIGNMENT_CENTER)
	_primary(p, "Back to our nook", Rect2(35, 358, 500, 49), func(): _go("home"))
	if last_reward.evolved:
		_toast(state.name + " grew into a " + NookState.STAGES[state.stage].name.to_lower() + "!")

func _begin_tidy() -> void:
	state.sleeping = false
	tidy_items = [
		{"id": "book", "label": "Storybook", "category": "shelf"},
		{"id": "picture", "label": "Nature journal", "category": "shelf"},
		{"id": "apple", "label": "Apple", "category": "pantry"},
		{"id": "carrot", "label": "Carrot", "category": "pantry"},
		{"id": "yarn", "label": "Yarn ball", "category": "basket"},
		{"id": "ball", "label": "Play ball", "category": "basket"},
	]
	Lessons._shuffle(tidy_items, rng)
	tidy_selected = ""
	tidy_sorted = 0
	tidy_misses = false
	round_finished = false

func _tidy_page() -> void:
	_heading("A place for every little thing.", "Drag an object to its home, or tap an object and then a basket.")
	var p := _panel(page, Rect2(286, 214, 1125, 621), Color("#f4eadb"), 24)
	_label(p, "LET'S MAKE SOME ROOM", Rect2(29, 20, 834, 29), 12, MUTED)
	_label(p, "%d / 6 tucked away" % tidy_sorted, Rect2(835, 20, 256, 29), 15, INK, false, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(p, "A little sorting, a lot of calm.", Rect2(38, 78, 1040, 38), 26, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	var start_x := 58
	for i in range(tidy_items.size()):
		var item: Dictionary = tidy_items[i]
		if item.get("sorted", false): continue
		var b := TidyItem.new()
		b.item_id = item.id
		b.category = item.category
		b.art = load("res://assets/art/%s.svg" % ("book" if item.id == "picture" else item.id))
		var item_color := PALE_SAGE if tidy_selected == item.id else PAPER
		_setup_button(b, "", Rect2(start_x + i*171, 166, 153, 161), item_color)
		p.add_child(b)
		_image(b, "book" if item.id == "picture" else item.id, Rect2(34, 15, 85, 92))
		_label(b, item.label, Rect2(7, 115, 139, 29), 15, INK, false, HORIZONTAL_ALIGNMENT_CENTER)
		b.pressed.connect(func(): _select_tidy(item.id))
	var bins := [["shelf", "The bookshelf", "Books & journals", "book", "#e5ead8"], ["pantry", "The pantry", "Fruit & vegetables", "carrot", "#f0ddc8"], ["basket", "The play basket", "Toys & yarn", "yarn", "#e9dee7"]]
	for i in range(bins.size()):
		var info: Array = bins[i]
		var b := TidyBin.new()
		b.category = info[0]
		_setup_button(b, "", Rect2(36+i*355, 386, 339, 177), Color(info[4]))
		p.add_child(b)
		_image(b, info[3], Rect2(17, 22, 82, 88))
		_label(b, info[1], Rect2(111, 36, 213, 39), 23, INK, true)
		_label(b, info[2], Rect2(112, 84, 216, 28), 14, MUTED)
		_label(b, "Place here", Rect2(20, 131, 294, 28), 13, MUTED, false, HORIZONTAL_ALIGNMENT_CENTER)
		b.item_dropped.connect(_drop_tidy)
		b.pressed.connect(func():
			if not tidy_selected.is_empty(): _drop_tidy(tidy_selected, info[0])
			else: _toast("Choose a little object first.")
		)
	_label(p, "No rush. Everything finds its place eventually.", Rect2(40, 578, 1037, 27), 14, MUTED, false, HORIZONTAL_ALIGNMENT_CENTER)

func _select_tidy(item_id: String) -> void:
	tidy_selected = item_id
	_sound("tap")
	_render()

func _drop_tidy(item_id: String, destination: String) -> void:
	if round_finished:
		return
	for item in tidy_items:
		if item.id != item_id or item.get("sorted", false): continue
		if item.category == destination:
			item.sorted = true
			tidy_sorted += 1
			tidy_selected = ""
			_sound("correct")
			if tidy_sorted == tidy_items.size():
				_finish_activity("tidy", not tidy_misses)
			else:
				_render()
		else:
			tidy_misses = true
			_sound("soft")
			_toast("Almost! Think about what belongs together.")
		return

func _shop_page() -> void:
	_heading("Make a nook of your own.", "Little treasures for the place you share. Earn leaf coins by learning and tidying.")
	for i in range(NookState.SHOP.size()):
		var item: Dictionary = NookState.SHOP[i]
		var p := _panel(page, Rect2(286+(i%3)*382, 213+(i/3)*317, 361, 298), PAPER, 22)
		var colors := ["#e8eddc", "#eee3ea", "#f1e3cf"]
		_panel(p, Rect2(16, 15, 329, 112), Color(colors[i%3]), 16, Color(colors[i%3]))
		_image(p, item.icon, Rect2(135, 20, 92, 99))
		_label(p, item.name, Rect2(20, 138, 319, 35), 24, INK, true)
		_wrapped(p, item.description, Rect2(20, 178, 319, 40), 14, MUTED)
		var owned: bool = item.id in state.owned
		var equipped: bool = item.id in state.equipped
		var text: String = ("In your room  ·  Put away" if equipped else "Place in room") if owned else "%d leaf coins  ·  Bring home" % item.cost
		var b := _button(p, text, Rect2(20, 233, 321, 46), func(): _shop_action(item.id), PALE_SAGE if owned else Color("#f5eddc"), 15)
		if not owned and state.coins < item.cost:
			b.disabled = true
			b.text = "%d leaf coins  ·  Save a little more" % item.cost

func _shop_action(item_id: String) -> void:
	if item_id in state.owned:
		NookState.equip(state, item_id)
		_sound("tap")
	else:
		if not NookState.buy(state, item_id):
			_toast("A few more leaf coins will bring this treasure home.")
			return
		_sound("buy")
	_save()
	_render()
	_toast("A little change makes it feel like home.")

func _journal_page() -> void:
	_heading("Our little story, so far.", "Every small moment leaves something lovely behind.")
	var stats := [["star", str(state.stars), "little stars"], ["heart", str(state.completed), "moments together"], ["broom", str(state.tidy_count), "rooms made cozy"], ["leaf", str(state.visited_days.size()), "days of discovery"]]
	for i in range(4):
		var s: Array = stats[i]
		var p := _panel(page, Rect2(286+i*286, 218, 267, 126), PAPER, 20)
		_image(p, s[0], Rect2(19, 30, 58, 58))
		_label(p, s[1], Rect2(97, 19, 150, 50), 35, INK, true)
		_label(p, s[2], Rect2(97, 76, 160, 27), 14, MUTED)
	var p := _panel(page, Rect2(286, 368, 1125, 453), PAPER, 24)
	_label(p, "Small steps, growing roots.", Rect2(29, 21, 1062, 46), 28, INK, true)
	var milestones := [
		["book", "First chapter", "Finish a learning moment", state.completed > 0],
		["broom", "A tidy little home", "Finish your first tidy", state.tidy_count > 0],
		["bag", "Personal touch", "Bring home a decoration", state.owned.size() > 0],
		["star", "A lovely day", "Reach your daily star goal", state.today.stars >= state.settings.goal],
		["plant", "Putting down roots", "Visit on three different days", state.visited_days.size() >= 3],
	]
	for i in range(5):
		var m: Array = milestones[i]
		var x := 30+i*217
		_panel(p, Rect2(x, 99, 195, 194), PALE_SAGE if m[3] else Color("#f4f0e8"), 18, LINE)
		var image := _image(p, m[0], Rect2(x+60, 113, 72, 76))
		image.modulate.a = 1 if m[3] else .38
		_label(p, m[1], Rect2(x+6, 196, 183, 32), 17, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_wrapped(p, "Collected" if m[3] else m[2], Rect2(x+13, 231, 169, 47), 13, SAGE if m[3] else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var next_index: int = mini(state.stage+1, NookState.STAGES.size()-1)
	var next: Dictionary = NookState.STAGES[next_index]
	_wrapped(p, "%s is a %s. The next chapter needs %d stars and %d days of growing in this stage." % [state.name, NookState.STAGES[state.stage].name.to_lower(), next.stars, next.days] if state.stage < NookState.STAGES.size()-1 else state.name + " has become a nook guardian. There's still a whole world to discover together.", Rect2(32, 326, 1054, 61), 18, MUTED)
	_label(p, "Today: %d / %d stars  ·  Extra practice always brings care and coins." % [state.today.stars, state.settings.goal], Rect2(32, 398, 1057, 32), 15, SAGE)

func _toggle_sound() -> void:
	state.settings.sound = not state.settings.sound
	if not state.settings.sound: audio.stop()
	_save()
	_render()
	_toast("Little sounds on." if state.settings.sound else "A quiet little moment. Sounds off.")

func _modal(title: String, subtitle: String, width := 534, height := 306) -> Panel:
	_clear_toast()
	_close_popup()
	popup = Control.new()
	popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(popup)
	var shade := ColorRect.new()
	shade.color = Color(.26, .23, .20, .34)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.add_child(shade)
	var p := _panel(popup, Rect2((1440-width)/2.0, (900-height)/2.0, width, height), PAPER, 25)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	_wrapped(p, title, Rect2(34, 27, width-68, 68), 28, INK, HORIZONTAL_ALIGNMENT_CENTER).add_theme_font_override("font", title_font)
	_wrapped(p, subtitle, Rect2(34, 101, width-68, 55), 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_focus_popup.call_deferred()
	return p

func _focus_popup() -> void:
	if not is_instance_valid(popup): return
	var targets: Array[Control] = []
	for node in popup.find_children("*", "Control", true, false):
		if node.focus_mode == Control.FOCUS_ALL and node.visible:
			targets.append(node)
	if targets.is_empty(): return
	for i in range(targets.size()):
		targets[i].focus_next = targets[(i+1) % targets.size()].get_path()
		targets[i].focus_previous = targets[(i-1+targets.size()) % targets.size()].get_path()
	targets[0].grab_focus()

func _close_popup() -> void:
	if is_instance_valid(popup):
		remove_child(popup)
		popup.queue_free()
	popup = null

func _parent_gate() -> void:
	var p := _modal("For the grown-ups.", "A tiny check before we change this little world.\nWhat is 7 × 6?", 534, 335)
	var input := LineEdit.new()
	input.position = Vector2(36, 174)
	input.size = Vector2(460, 48)
	input.placeholder_text = "Your answer"
	input.add_theme_stylebox_override("normal", _style(CREAM, 12))
	p.add_child(input)
	input.grab_focus()
	var submit := func():
		if input.text.strip_edges() == "42": _settings()
		else: _toast("Try that one again, grown-up.")
	input.text_submitted.connect(func(_text): submit.call())
	_button(p, "Back", Rect2(36, 254, 160, 48), _close_popup)
	_primary(p, "Open settings", Rect2(214, 254, 282, 48), submit)

func _settings() -> void:
	var p := _modal("A nook that fits your family.", "Adjust the pace. Keep the little moments happy.", 660, 573)
	_label(p, "Your friend's name", Rect2(34, 162, 250, 39), 17)
	var name_input := LineEdit.new()
	name_input.position = Vector2(340, 162)
	name_input.size = Vector2(282, 42)
	name_input.text = state.name
	name_input.max_length = 18
	name_input.add_theme_stylebox_override("normal", _style(CREAM, 10))
	p.add_child(name_input)
	_label(p, "Daily little stars", Rect2(34, 227, 280, 42), 17)
	var goal := OptionButton.new()
	_setup_button(goal, "", Rect2(340, 227, 282, 42), CREAM, 17)
	for value in [3, 6, 9]: goal.add_item("%d stars" % value, value)
	goal.select([3,6,9].find(state.settings.goal) if state.settings.goal in [3,6,9] else 1)
	p.add_child(goal)
	_label(p, "Learning level", Rect2(34, 290, 280, 42), 17)
	var level := OptionButton.new()
	_setup_button(level, "", Rect2(340, 290, 282, 42), CREAM, 17)
	for option in ["Grows with your child", "1 · First discoveries", "2 · Growing confidence", "3 · A little challenge"]:
		level.add_item(option)
	level.select(state.settings.level)
	p.add_child(level)
	var motion := CheckButton.new()
	motion.text = "Gentle character animation"
	motion.position = Vector2(31, 361)
	motion.size = Vector2(584, 48)
	motion.button_pressed = state.settings.motion
	p.add_child(motion)
	_wrapped(p, "Progress stays on this device. There are no accounts, ads, purchases, or tracking. The daily star limit never limits caring.", Rect2(35, 423, 586, 61), 14, MUTED)
	_button(p, "Cancel", Rect2(34, 505, 165, 46), _close_popup)
	_primary(p, "Save our preferences", Rect2(216, 505, 406, 46), func():
		state.name = name_input.text.strip_edges().left(18) if not name_input.text.strip_edges().is_empty() else "Pip"
		state.settings.goal = goal.get_selected_id()
		state.settings.level = level.selected
		state.settings.motion = motion.button_pressed
		_save()
		_close_popup()
		_render()
		_toast("Just right for your little world.")
	)

func _toast(message: String) -> void:
	if not is_inside_tree(): return
	_clear_toast()
	toast_panel = _panel(self, Rect2(429, 795, 733, 57), Color("#5e6653"), 18, Color("#5e6653"))
	_wrapped(toast_panel, message, Rect2(18, 5, 697, 47), 16, PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	# Timers can outlive a replaced notification. Capture a WeakRef, not the node.
	var current: WeakRef = weakref(toast_panel)
	get_tree().create_timer(toast_duration).timeout.connect(func():
		var panel: Panel = current.get_ref()
		if is_instance_valid(panel):
			panel.queue_free()
	)

func _clear_toast() -> void:
	if is_instance_valid(toast_panel):
		remove_child(toast_panel)
		toast_panel.queue_free()
	toast_panel = null

func _capture(path: String) -> void:
	await get_tree().create_timer(1.4).timeout
	await RenderingServer.frame_post_draw
	var err := get_viewport().get_texture().get_image().save_png(path)
	print("Screenshot saved: ", path, " result=", err)
	get_tree().quit(err)

func _run_ui_tests() -> void:
	await get_tree().process_frame
	_ui_check(screen == "home", "opens at home")
	state.name = "Clover"
	_start_lesson("math")
	_ui_check(questions.size() == 3, "starts a complete lesson")
	_ui_check("Clover" in questions[0].prompt, "lessons use the companion's chosen name")
	_answer("not the answer")
	_ui_check(not first_try and question_misses == 1, "wrong answers allow retry")
	for i in range(3):
		_answer(questions[question_index].answer)
		if i == 0:
			_toggle_sound()
			_ui_check(continue_button.visible and choice_buttons.all(func(b): return b.disabled), "sound changes preserve an answered question")
		_next_question()
	_ui_check(round_finished and last_reward.stars == 1, "lesson awards once on completion")
	var stars_before: int = state.stars
	_finish_activity("math", true)
	_ui_check(state.stars == stars_before, "completion is idempotent")
	_go("tidy")
	_drop_tidy(tidy_items[0].id, "wrong")
	_ui_check(tidy_sorted == 0 and tidy_misses, "incorrect tidy drop is gentle")
	_drop_tidy(tidy_items[0].id, tidy_items[0].category)
	_navigate("tidy")
	_ui_check(tidy_sorted == 1, "active navigation does not reset tidying")
	for item in tidy_items:
		_drop_tidy(item.id, item.category)
	_ui_check(tidy_sorted == 6 and round_finished, "all tidy objects can be placed")
	_go("shop")
	_shop_action("plant")
	_ui_check("plant" in state.owned and "plant" in state.equipped, "shop purchase decorates room")
	_shop_action("plant")
	_ui_check("plant" not in state.equipped, "decorations can be put away")
	_go("home")
	_sleep()
	_ui_check(state.sleeping, "sleep starts")
	_start_lesson("science")
	_ui_check(not state.sleeping, "activities wake companion")
	_confirm_leave("home")
	_ui_check(is_instance_valid(popup), "leaving an activity asks first")
	_go("journal")
	_ui_check(screen == "journal", "journal renders")
	_settings()
	_ui_check(is_instance_valid(popup), "preferences render")
	_close_popup()
	print("UI integration checks: ", 17-test_failures, "/17 passed")
	audio.stop()
	await get_tree().create_timer(.15).timeout
	get_tree().quit(1 if test_failures else 0)

func _ui_check(condition: bool, description: String) -> void:
	if not condition:
		test_failures += 1
		push_error("UI CHECK FAILED: " + description)
