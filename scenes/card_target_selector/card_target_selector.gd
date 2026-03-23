extends Node2D

const ARROW_PARTS = 50
const ARROW_TAIL_TEX = preload("res://assets/icons/SwordSectIcons/Arc_Sword_Out.png")
const ARROW_HEAD_TEX = preload("res://assets/icons/SwordSectIcons/Arc_Arrow.png")

@onready var area_2d: Area2D = $Area2D
@onready var arrow_container: Node2D = $CanvasLayer/ArrowContainer

var current_card: CardUI
var targeting := false

func _ready() -> void:
	Events.card_aim_started.connect(_on_card_aim_started)
	Events.card_aim_ended.connect(_on_card_aim_ended)
	_create_arrow_parts()

func _create_arrow_parts():
	for i in range(ARROW_PARTS):
		var sprite = Sprite2D.new()
		if i == ARROW_PARTS - 1:
			sprite.texture = ARROW_HEAD_TEX
		else:
			sprite.texture = ARROW_TAIL_TEX
		sprite.offset = Vector2(0, 300)
		arrow_container.add_child(sprite)
	arrow_container.visible = false

func _process(_delta: float) -> void:
	if not targeting:
		return
	area_2d.position = get_local_mouse_position()
	_update_arrow()

func _update_arrow():
	var start = current_card.global_position
	start.x += current_card.size.x / 2
	var target = get_local_mouse_position()

	# 贝塞尔控制点
	var ctrl = _get_control_points(start, target)

	# 采样曲线上的点
	var points = []
	for i in range(ARROW_PARTS):
		var t = i / float(ARROW_PARTS - 1)
		var point = _bezier_point(start, ctrl[0], ctrl[1], target, t)
		points.append(point)

	# 设置每个精灵
	for i in range(ARROW_PARTS):
		var sprite = arrow_container.get_child(i)
		sprite.position = points[i]

		# 计算方向
		var dir: Vector2
		if i == 0:
			dir = (points[1] - points[0]).normalized()
		else:
			dir = (points[i] - points[i-1]).normalized()
		sprite.rotation = dir.angle() + PI / 2   # 如果纹理朝上需加90°

		# 缩放渐变：起点0.3 -> 末端0.6
		var scale_factor = 0.05 + (i / float(ARROW_PARTS - 1)) * 0.15
		sprite.scale = Vector2(scale_factor, scale_factor)

	arrow_container.visible = true

func _get_control_points(start: Vector2, target: Vector2) -> Array:
	# 弧线向上拱起，高度与距离成比例
	var mid = (start + target) / 2
	var dist = start.distance_to(target)
	var curve_height = dist * 0.35  # 弧线高度系数

	# 控制点从中点向上偏移
	var ctrl_offset = Vector2(0, -curve_height)
	var c1 = start + (mid - start) * 0.5 + ctrl_offset
	var c2 = mid + (target - mid) * 0.5 + ctrl_offset
	return [c1, c2]

func _bezier_point(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u = 1 - t
	return u*u*u * p0 + 3*u*u*t * p1 + 3*u*t*t * p2 + t*t*t * p3

func _on_card_aim_started(card: CardUI) -> void:
	if not card.card.is_single_targeted():
		return
	targeting = true
	area_2d.monitoring = true
	area_2d.monitorable = true
	current_card = card

func _on_card_aim_ended(card: CardUI) -> void:
	targeting = false
	arrow_container.visible = false
	area_2d.position = Vector2.ZERO
	area_2d.monitoring = false
	area_2d.monitorable = false
	current_card = null

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not current_card or not targeting:
		return
	if not current_card.targets.has(area):
		current_card.targets.append(area)

func _on_area_2d_area_exited(area: Area2D) -> void:
	if not current_card or not targeting:
		return
	current_card.targets.erase(area)
