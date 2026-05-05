class_name CharacterDialogue
extends RefCounted

const _LINES: Dictionary = {
	"sword": {
		"enter": "「来了。」",
		"finisher": "「一剑。」",
		"heavy_damage": "「还撑得住。」",
		"victory": "「饿了。」",
	},
	"law": {
		"enter": "「道法在此。」",
		"finisher": "「顺。」",
		"heavy_damage": "「还差一点……」",
		"victory": "「算对了。」",
	},
	"body": {
		"enter": "「使得。」",
		"finisher": "「来。」",
		"heavy_damage": "「不疼。」",
		"victory": "「使得。」",
	},
}

static func get_line(character: String, trigger: String) -> String:
	return _LINES.get(character, {}).get(trigger, "")
