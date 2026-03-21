class_name Card
extends Resource

# 卡牌类型：功法，法术，武技
enum Type {TECHNIQUE, MAGIC, MARTIAL}

enum Target {SELF, SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}

@export_group("Card Attributes")
@export var id: String
@export var type: Type
@export var target: Target

func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY
