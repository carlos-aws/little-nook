extends SceneTree
## Dependency-free model, content and disk-persistence regression tests.

var checks := 0
var failures := 0
const CLOCK := 1789905600.0

func _init() -> void:
	_test_care_and_limits()
	_test_rest_and_growth()
	_test_shop()
	_test_content()
	_test_save_validation()
	_test_disk_persistence()
	print("Rules, content, and persistence: %d/%d checks passed" % [checks-failures, checks])
	quit(1 if failures else 0)

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("CHECK FAILED: " + description)

func _test_care_and_limits() -> void:
	var data := NookState.fresh(CLOCK)
	for i in range(6):
		var earned := NookState.complete(data, "math", true, CLOCK)
		check(earned.stars == 1 and earned.coins == 5, "activities award a star and first-try bonus")
	check(data.today.stars == 6 and data.stars == 6, "daily goal is six")
	data.needs.food = 30.0
	var practice := NookState.complete(data, "math", false, CLOCK)
	check(practice.stars == 0 and practice.coins == 1, "practice beyond the cap earns care and one coin")
	check(data.needs.food == 60.0, "care continues after the cap")
	NookState.ensure_day(data, CLOCK + 86400)
	check(data.today.stars == 0 and data.stars == 6, "new day clears only daily stars")
	check(NookState.complete(data, "science", true, CLOCK+86400).stars == 1, "stars resume on a new day")
	check(data.visited_days.size() == 2, "visited days are distinct")
	check(data.skills.math == 2, "an assisted round gently lowers the adaptive level")
	data.settings.goal = 3
	for i in range(5): NookState.complete(data, "english", true, CLOCK+86400)
	check(data.today.stars == 3, "custom daily goal respected")
	check(data.skills.english == 3, "perfect rounds advance level to at most three")
	check(data.needs.food <= 100 and data.needs.energy >= 25, "need bounds preserved")

func _test_rest_and_growth() -> void:
	var data := NookState.fresh(CLOCK)
	NookState.tick(data, CLOCK + 3600*24*30)
	for need in NookState.NEEDS:
		check(data.needs[need] >= 25, "long breaks are gentle: " + need)
	data = NookState.fresh(CLOCK)
	data.sleeping = true
	data.needs.energy = 30.0
	NookState.tick(data, CLOCK+3600)
	check(data.needs.energy == 48.0, "rest restores energy in real time")
	NookState.tick(data, CLOCK+5*3600)
	check(data.needs.energy == 100 and not data.sleeping, "fully rested companion wakes")
	data = NookState.fresh(CLOCK)
	NookState.tick(data, CLOCK-3600)
	check(data.last_tick == CLOCK and data.needs.food == 76, "backward clock never reverses progress")
	data.stars = 11
	NookState.complete(data, "math", true, CLOCK)
	check(data.stage == 0, "stars alone cannot rush growth")
	var grown := NookState.complete(data, "math", true, CLOCK+2*86400)
	check(grown.evolved and data.stage == 1, "stars and time together unlock growth")
	check(data.stage_since == CLOCK+2*86400, "growth resets the stage clock")

func _test_shop() -> void:
	var data := NookState.fresh(CLOCK)
	check(not NookState.buy(data, "unknown"), "unknown items rejected")
	check(not NookState.buy(data, "lamp"), "insufficient balance rejected")
	check(data.coins == 12, "failed purchase keeps balance")
	check(NookState.buy(data, "plant"), "affordable item can be purchased")
	check(data.coins == 0 and "plant" in data.equipped, "purchase charges exact amount and equips")
	check(not NookState.buy(data, "plant") and data.coins == 0, "duplicate purchase never charged")
	check(NookState.equip(data, "plant") and "plant" not in data.equipped, "owned items can be put away")
	check(NookState.equip(data, "plant") and "plant" in data.equipped, "owned items can be placed")
	check(not NookState.equip(data, "lamp"), "unowned items cannot be equipped")

func _test_content() -> void:
	var rng := RandomNumberGenerator.new()
	for seed_value in range(80):
		rng.seed = seed_value
		for subject in ["math", "english", "science"]:
			for level in range(1,4):
				var questions := Lessons.build(subject, level, rng)
				check(questions.size() == 3, "every lesson has three questions")
				for q in questions:
					check(q.choices.size() == 3, "three choices")
					check(q.choices.count(q.answer) == 1, "exactly one correct choice")
					check(q.choices[0] != q.choices[1] and q.choices[1] != q.choices[2] and q.choices[0] != q.choices[2], "choices are unique")
					check(not q.fact.is_empty() and not q.prompt.is_empty(), "question includes useful feedback")
					check(ResourceLoader.exists("res://assets/art/%s.svg" % q.icon), "question art exists")
				check(questions[0].prompt != questions[1].prompt and questions[1].prompt != questions[2].prompt and questions[0].prompt != questions[2].prompt, "questions within a round do not repeat")

func _test_save_validation() -> void:
	check(NookState.validate(null, CLOCK).is_empty(), "invalid JSON rejected")
	check(NookState.validate({"version": 2}, CLOCK).is_empty(), "unknown save versions rejected")
	var data := NookState.fresh(CLOCK)
	data.coins = "a lot"
	check(NookState.validate(data, CLOCK).is_empty(), "invalid numeric type rejected")
	data = NookState.fresh(CLOCK)
	data.needs = []
	check(NookState.validate(data, CLOCK).is_empty(), "invalid needs structure rejected")
	data = NookState.fresh(CLOCK)
	data.coins = -50
	data.skills.math = 500
	data.name = "  "
	data.owned = ["plant", "plant", "bad"]
	data.equipped = ["plant", "lamp", "bad"]
	data.journal = [{"date": "bad"}]
	var clean := NookState.validate(data, CLOCK)
	check(clean.coins == 0 and clean.skills.math == 3, "out-of-range values clamped")
	check(clean.name == "Pip", "empty name gets a friendly default")
	check(clean.owned == ["plant"] and clean.equipped == ["plant"], "inventory validated and deduplicated")
	check(clean.journal.is_empty(), "malformed history filtered")
	data = NookState.fresh(CLOCK)
	data.last_tick = INF
	check(NookState.validate(data, CLOCK).is_empty(), "nonfinite numbers rejected")

func _test_disk_persistence() -> void:
	var test_path := "user://rules-test-%d.json" % OS.get_process_id()
	var store := SaveStore.new(test_path)
	var data := NookState.fresh(CLOCK)
	check(store.save_progress(data), "first save writes successfully")
	data.coins = 73
	check(store.save_progress(data), "updated save writes successfully")
	var loaded := store.load_progress(CLOCK)
	check(loaded.coins == 73, "save survives a fresh load")
	check(loaded.name == "Pip" and loaded.needs.food == 76.0, "JSON round-trip preserves model")
	var file := FileAccess.open(test_path, FileAccess.WRITE)
	file.store_string("{ broken json")
	file.close()
	loaded = store.load_progress(CLOCK)
	check(store.recovered and loaded.coins == 12, "corrupt primary recovers previous valid backup")
	check(store.save_progress(loaded), "recovered progress can be saved")
	check(store.load_progress(CLOCK).coins == 12, "recovered save remains readable")
	var bad_store := SaveStore.new("user://does-not-exist/subdir/progress.json")
	check(not bad_store.save_progress(data) and not bad_store.last_error.is_empty(), "unwritable save returns actionable failure")
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(test_path + suffix):
			DirAccess.remove_absolute(test_path + suffix)
