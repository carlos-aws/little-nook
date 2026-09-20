class_name NookState
extends RefCounted
## Pure game rules. All clocks are injectable so tests never alter real progress.

const NEEDS := ["food", "joy", "curiosity", "tidiness", "energy"]
const SHOP := [
	{"id": "plant", "name": "A leafy friend", "description": "A little green for the windowsill.", "cost": 12, "icon": "plant"},
	{"id": "cushion", "name": "Cloud cushion", "description": "The softest spot for a daydream.", "cost": 18, "icon": "cushion"},
	{"id": "flower", "name": "Wildflower pot", "description": "A small bunch of everyday sunshine.", "cost": 24, "icon": "flower"},
	{"id": "lamp", "name": "Reading light", "description": "Warm light for one more chapter.", "cost": 30, "icon": "lamp"},
	{"id": "picture", "name": "Pressed leaves", "description": "A tiny treasure from a woodland walk.", "cost": 22, "icon": "picture"},
	{"id": "mushroom", "name": "Mushroom friend", "description": "A little forest magic, just for Pip.", "cost": 36, "icon": "mushroom"},
]
const STAGES := [
	{"name": "Little seedling", "stars": 0, "days": 0},
	{"name": "Curious sprout", "stars": 12, "days": 2},
	{"name": "Happy sapling", "stars": 36, "days": 5},
	{"name": "Woodland friend", "stars": 75, "days": 10},
	{"name": "Nook guardian", "stars": 120, "days": 14},
]

static func day_key(now: float) -> String:
	var offset_minutes: int = Time.get_time_zone_from_system().bias
	return Time.get_date_string_from_unix_time(int(now) + offset_minutes * 60)

static func fresh(now: float) -> Dictionary:
	return {
		"version": 1, "name": "Pip", "coins": 12, "stars": 0, "stage": 0,
		"stage_since": now, "last_tick": now, "sleeping": false,
		"needs": {"food": 76.0, "joy": 82.0, "curiosity": 65.0, "tidiness": 70.0, "energy": 88.0},
		"today": {"date": day_key(now), "stars": 0, "activities": 0, "subjects": []},
		"settings": {"sound": true, "motion": true, "goal": 6, "level": 0},
		"skills": {"math": 1, "english": 1, "science": 1},
		"streaks": {"math": 0, "english": 0, "science": 0},
		"owned": [], "equipped": [], "completed": 0, "tidy_count": 0,
		"visited_days": [], "journal": [],
	}

static func ensure_day(data: Dictionary, now: float) -> void:
	if data.today.date != day_key(now):
		data.today = {"date": day_key(now), "stars": 0, "activities": 0, "subjects": []}

static func tick(data: Dictionary, now: float) -> void:
	ensure_day(data, now)
	var hours := clampf((now - float(data.last_tick)) / 3600.0, 0.0, 48.0)
	data.last_tick = maxf(float(data.last_tick), now)
	for need in NEEDS:
		if need == "energy" and data.sleeping:
			data.needs[need] = minf(100.0, data.needs[need] + 18.0 * hours)
		else:
			var speed := 1.5 if data.sleeping else 3.0
			data.needs[need] = maxf(25.0, data.needs[need] - speed * hours)
	if data.sleeping and data.needs.energy >= 100.0:
		data.sleeping = false

static func complete(data: Dictionary, subject: String, perfect: bool, now: float) -> Dictionary:
	ensure_day(data, now)
	var need: String = {"math": "food", "english": "joy", "science": "curiosity", "tidy": "tidiness"}.get(subject, "joy")
	data.needs[need] = minf(100.0, data.needs[need] + 30.0)
	data.needs.energy = maxf(25.0, data.needs.energy - 3.0)
	var earned_star := 1 if data.today.stars < data.settings.goal else 0
	var earned_coins := (3 if earned_star else 1) + (2 if perfect else 0)
	data.today.stars += earned_star
	data.today.activities += 1
	if subject not in data.today.subjects:
		data.today.subjects.append(subject)
	data.stars += earned_star
	data.coins += earned_coins
	data.completed += 1
	if subject == "tidy":
		data.tidy_count += 1
	if day_key(now) not in data.visited_days:
		data.visited_days.append(day_key(now))
		if data.visited_days.size() > 366:
			data.visited_days.pop_front()
	if subject in data.skills:
		data.streaks[subject] = data.streaks[subject] + 1 if perfect else 0
		if data.streaks[subject] >= 2:
			data.skills[subject] = mini(3, data.skills[subject] + 1)
			data.streaks[subject] = 0
		elif not perfect:
			data.skills[subject] = maxi(1, data.skills[subject] - 1)
	var evolved := false
	if data.stage < STAGES.size() - 1:
		var next: Dictionary = STAGES[data.stage + 1]
		if data.stars >= next.stars and now - data.stage_since >= next.days * 86400:
			data.stage += 1
			data.stage_since = now
			evolved = true
	data.journal.push_front({"date": day_key(now), "subject": subject, "stars": earned_star, "coins": earned_coins})
	data.journal = data.journal.slice(0, 30)
	return {"stars": earned_star, "coins": earned_coins, "evolved": evolved}

static func buy(data: Dictionary, item_id: String) -> bool:
	for item in SHOP:
		if item.id == item_id:
			if item_id in data.owned or data.coins < item.cost:
				return false
			data.coins -= item.cost
			data.owned.append(item_id)
			data.equipped.append(item_id)
			return true
	return false

static func equip(data: Dictionary, item_id: String) -> bool:
	if item_id not in data.owned:
		return false
	if item_id in data.equipped:
		data.equipped.erase(item_id)
	else:
		data.equipped.append(item_id)
	return true

static func validate(raw: Variant, now: float) -> Dictionary:
	## Reject malformed saves before touching the active file or backup.
	if not raw is Dictionary or raw.get("version") != 1:
		return {}
	var base := fresh(now)
	for key in base:
		if not raw.has(key):
			continue
		var expected: Variant = base[key]
		var actual: Variant = raw[key]
		if expected is Dictionary:
			if not actual is Dictionary:
				return {}
			for child in expected:
				if actual.has(child):
					if not _compatible(expected[child], actual[child]):
						return {}
					base[key][child] = actual[child]
		elif _compatible(expected, actual):
			base[key] = actual
		else:
			return {}
	if base.name.strip_edges().is_empty():
		base.name = "Pip"
	base.name = base.name.strip_edges().left(18)
	base.coins = clampi(int(base.coins), 0, 1000000)
	base.stars = clampi(int(base.stars), 0, 1000000)
	base.stage = clampi(int(base.stage), 0, STAGES.size() - 1)
	base.stage_since = clampf(float(base.stage_since), 0, now)
	base.last_tick = clampf(float(base.last_tick), 0, now)
	base.completed = clampi(int(base.completed), 0, 1000000)
	base.tidy_count = clampi(int(base.tidy_count), 0, 1000000)
	base.settings.goal = clampi(int(base.settings.goal), 3, 9)
	base.settings.level = clampi(int(base.settings.level), 0, 3)
	base.today.stars = clampi(int(base.today.stars), 0, 9)
	base.today.activities = clampi(int(base.today.activities), 0, 1000000)
	for need in NEEDS:
		base.needs[need] = clampf(float(base.needs[need]), 25.0, 100.0)
	for subject in base.skills:
		base.skills[subject] = clampi(int(base.skills[subject]), 1, 3)
		base.streaks[subject] = clampi(int(base.streaks[subject]), 0, 2)
	var item_ids := []
	for item in SHOP:
		item_ids.append(item.id)
	base.owned = _unique_allowed(base.owned, item_ids)
	base.equipped = _unique_allowed(base.equipped, base.owned)
	base.today.subjects = _unique_allowed(base.today.subjects, ["math", "english", "science", "tidy"])
	base.visited_days = base.visited_days.filter(func(v): return v is String).slice(-366)
	base.journal = base.journal.filter(func(v):
		return v is Dictionary and v.get("date") is String and v.get("subject") in ["math", "english", "science", "tidy"] and _number(v.get("stars")) and _number(v.get("coins"))
	).slice(0, 30)
	return base

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _compatible(a: Variant, b: Variant) -> bool:
	if a is int or a is float:
		return _number(b)
	return typeof(a) == typeof(b)

static func _unique_allowed(values: Array, allowed: Array) -> Array:
	var result := []
	for value in values:
		if value in allowed and value not in result:
			result.append(value)
	return result
