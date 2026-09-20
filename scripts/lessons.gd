class_name Lessons
extends RefCounted
## Original age-friendly prompts. Answers are shuffled independently of content.

const ENGLISH := [
	[
		["Which word starts with B?", "Bear", "Cat", "Sun", "book", "Bear begins with the letter B."],
		["Which word rhymes with cat?", "Hat", "Cup", "Dog", "book", "Cat and hat have the same ending sound."],
		["Finish the word: S _ N", "U", "A", "I", "flower", "S, U, N spells sun."],
		["Which is a colour word?", "Green", "Jump", "Book", "leaf", "Green is a colour, like a leaf."],
		["Which word means more than one book?", "Books", "Book", "Booky", "book", "Add an s: one book, two books."],
		["What is the opposite of big?", "Small", "Tall", "Wide", "mushroom", "Big and small are opposites."],
	],
	[
		["Which word rhymes with tree?", "Bee", "Toy", "Top", "leaf", "Tree and bee end with the same sound."],
		["Choose the missing word: Pip ___ a book.", "reads", "blue", "under", "book", "Pip reads a book. Reads is an action word."],
		["Which word is an action?", "Jump", "Leaf", "Green", "ball", "Jump is something you can do."],
		["What is the opposite of empty?", "Full", "Open", "Little", "bag", "An empty basket has nothing in it. Full is its opposite."],
		["Which sentence is a question?", "Where is Pip?", "Pip is here.", "Hello, Pip!", "book", "A question asks something and ends with a question mark."],
		["Finish the word: L E _ F", "A", "O", "U", "leaf", "L, E, A, F spells leaf."],
	],
	[
		["Which word belongs? Pip is ___ than a mouse.", "bigger", "biggest", "big", "book", "Use bigger to compare two sizes."],
		["Choose the missing word: Yesterday, Pip ___.", "played", "plays", "playing", "ball", "Played tells us it happened in the past."],
		["Which word means almost the same as happy?", "Glad", "Tired", "Quiet", "flower", "Glad and happy have similar meanings."],
		["Which spelling is correct?", "Friend", "Freind", "Frend", "heart", "Friend is spelled F, R, I, E, N, D."],
		["Which word describes a noun?", "Soft", "Run", "And", "cushion", "Soft describes something, like a soft cushion."],
		["What is the plural of child?", "Children", "Childs", "Childes", "book", "Child has a special plural: children."],
	],
]

const SCIENCE := [
	[
		["What helps a plant grow?", "Sunlight", "A scarf", "A book", "plant", "Plants use light to make their own food."],
		["Which animal has feathers?", "Bird", "Bear", "Frog", "leaf", "Birds have feathers. Feathers help keep them warm."],
		["Which part of a plant is usually under the soil?", "Roots", "Flower", "Leaf", "plant", "Roots take in water and help hold a plant in place."],
		["Which is a living thing?", "Tree", "Chair", "Cup", "leaf", "Trees are living things. They grow and need water."],
		["What do we use to hear?", "Ears", "Eyes", "Nose", "book", "Our ears help us hear sounds around us."],
		["What falls from rain clouds?", "Water", "Sand", "Leaves", "flower", "Rain is liquid water falling from clouds."],
	],
	[
		["What does a caterpillar become?", "Butterfly or moth", "Frog", "Bird", "flower", "Caterpillars grow into butterflies or moths."],
		["What happens to ice in a warm room?", "It melts", "It grows", "It turns to sand", "moon", "Ice is solid water. Warmth turns it into liquid water."],
		["Which helps move pollen between flowers?", "Bee", "Fish", "Worm", "flower", "Bees can carry pollen as they visit flowers."],
		["Which material is usually attracted to a magnet?", "Iron", "Wood", "Paper", "bag", "Magnets attract iron and some other metals."],
		["Which gives Earth most of its daylight?", "The Sun", "The Moon", "A lamp", "lamp", "The Sun is a star that gives Earth light and warmth."],
		["What does a tadpole grow into?", "Frog or toad", "Fish", "Duck", "leaf", "Tadpoles are young frogs or toads."],
	],
	[
		["Why do we have day and night?", "Earth spins", "The Sun switches off", "Clouds hide the Sun", "moon", "Earth spins. The side facing the Sun has daytime."],
		["What is water vapour?", "Water as a gas", "Tiny stones", "Frozen water", "flower", "Water can be a solid, liquid, or gas."],
		["Which part of a plant usually makes most of its food?", "Leaves", "Roots", "Seeds", "leaf", "Leaves use light, water, and carbon dioxide to make food."],
		["Which animal is a mammal?", "Whale", "Shark", "Trout", "book", "Whales breathe air and feed their babies milk."],
		["Why is compost useful?", "It adds nutrients to soil", "It stops all rain", "It turns soil into rock", "plant", "Compost forms as natural materials break down."],
		["What pulls a dropped apple toward Earth?", "Gravity", "Moonlight", "Sound", "apple", "Gravity pulls objects toward one another."],
	],
]

static func build(subject: String, level: int, rng: RandomNumberGenerator) -> Array:
	level = clampi(level, 1, 3)
	var result := []
	if subject == "math":
		var pairs := []
		for left in range(1, 6 if level == 1 else 11):
			for right in range(2 if level == 3 else 1, 5 if level in [1,3] else left+1):
				pairs.append([left, right])
		_shuffle(pairs, rng)
		for i in range(3):
			var a: int = pairs[i][0]
			var b: int = pairs[i][1]
			var question: String
			var answer: int
			var explanation: String
			if level == 1:
				answer = a + b
				question = "Pip has %d apples and finds %d more.\nHow many apples altogether?" % [a, b]
				explanation = "%d plus %d makes %d. Count them together!" % [a, b, answer]
			elif level == 2:
				answer = maxi(a, b) - mini(a, b)
				question = "There are %d carrots. Pip eats %d.\nHow many are left?" % [maxi(a,b), mini(a,b)]
				explanation = "%d take away %d leaves %d." % [maxi(a,b), mini(a,b), answer]
			else:
				answer = a * b
				question = "There are %d baskets with %d apples each.\nHow many apples altogether?" % [b, a]
				explanation = "%d groups of %d makes %d." % [b, a, answer]
			var answers := [str(answer), str(answer + rng.randi_range(1, 3)), str(maxi(0, answer - 1) if answer > 0 else answer + 4)]
			_shuffle(answers, rng)
			result.append({"prompt": question, "answer": str(answer), "choices": answers, "icon": "carrot" if level == 2 else "apple", "fact": explanation})
	else:
		var bank: Array = (ENGLISH if subject == "english" else SCIENCE)[level-1].duplicate(true)
		_shuffle(bank, rng)
		for row in bank.slice(0, 3):
			var answers: Array = row.slice(1, 4)
			_shuffle(answers, rng)
			result.append({"prompt": row[0], "answer": row[1], "choices": answers, "icon": row[4], "fact": row[5]})
	return result

static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size()-1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp: Variant = items[i]
		items[i] = items[j]
		items[j] = temp
