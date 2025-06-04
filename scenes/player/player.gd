extends CharacterBody2D

##################################################
# 이동 가능 발판 연산 스크립트 미리 불러오기
const MOVE_INDICATOR_SCRIPT = preload("res://systems/move_indicator.gd")
# 이동 가능 발판 그리기 씬 미리 불러오기
const TILE_INDICATOR_1_SCENE: PackedScene = \
preload("res://scenes/tile_indicator/tile_indicator_1.tscn")
# 공격 가능 발판 그리기 씬 미리 불러오기
const TILE_INDICATOR_2_SCENE: PackedScene = \
preload("res://scenes/tile_indicator/tile_indicator_2.tscn")
const TILE_SIZE: float = 64.0	# 타일 한 개 크기
const MOVE_DURATION: float = 0.25

var ray_cast_up_node: RayCast2D
var ray_cast_down_node: RayCast2D
var ray_cast_left_node: RayCast2D
var ray_cast_right_node: RayCast2D
var indicator_node: Node2D	# 발판 이동을 방지하기 위한 별도의 등록 노드
var animated_sprite_node: AnimatedSprite2D

var is_input_locked: bool = false
var move_tween: Tween

##################################################
func _ready() -> void:
	ray_cast_up_node = $RayCasts/RayCast2DUp
	ray_cast_down_node = $RayCasts/RayCast2DDown
	ray_cast_left_node = $RayCasts/RayCast2DLeft
	ray_cast_right_node = $RayCasts/RayCast2DRight
	animated_sprite_node = $AnimatedSprite2D
	indicator_node = get_node("/root/Main/Indicator")	# 노드 설정
	show_reachable_n_attackable_tiles()	# 이동 가능 발판과 공격 가능 발판 그리기

##################################################
func _physics_process(delta: float) -> void:
	if is_input_locked:
		return
	
	var direction: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	elif Input.is_action_pressed("ui_down"):
		direction.y += 1
	elif Input.is_action_pressed("ui_left"):
		direction.x -= 1
	elif Input.is_action_pressed("ui_right"):
		direction.x += 1

	if direction.y == -1:
		if ray_cast_up_node.is_colliding():
			return
	elif direction.y == 1:
		if ray_cast_down_node.is_colliding():
			return
	elif direction.x == -1:
		if ray_cast_left_node.is_colliding():
			return
	elif direction.x == 1:
		if ray_cast_right_node.is_colliding():
			return
	
	if direction.x > 0:
		animated_sprite_node.flip_h = false
	elif direction.x < 0:
		animated_sprite_node.flip_h = true

	if not direction == Vector2.ZERO:
		start_move_animation(direction)

##################################################
func start_move_animation(direction_value: Vector2) -> void:
	is_input_locked = true
	
	animated_sprite_node.play("walk")
	
	if move_tween:
		move_tween.kill()
	
	move_tween = create_tween()
	
	var target_position: Vector2 = global_position + direction_value * TILE_SIZE
	move_tween.tween_property(self, "global_position", target_position, MOVE_DURATION)
	move_tween.tween_callback(Callable(self, "_on_move_animation_finished"))

##################################################
func _on_move_animation_finished() -> void:
	is_input_locked = false
	animated_sprite_node.play("idle")
	show_reachable_n_attackable_tiles()	# 이동 가능 발판과 공격 가능 발판 그리기

##################################################
# 이동 가능 발판과 공격 가능 발판 그리기 함수
func show_reachable_n_attackable_tiles() -> void:
	# 새로운 발판을 그리기 위해 indicator_node를 비워줌
	for child in indicator_node.get_children():
		child.queue_free()
	
	# 이동 가능 발판과 공격 가능 발판을 연산하여 저장
	var move_indicator_instance = MOVE_INDICATOR_SCRIPT.new()
	add_child(move_indicator_instance)
	var reachable_tiles = move_indicator_instance.get_reachable_tiles(global_position, false)
	var attackable_tiles = move_indicator_instance.get_reachable_tiles(global_position, true)
	move_indicator_instance.queue_free()
	
	# 이동 가능 발판 그리기
	for tile in reachable_tiles:
		var indicator_instance = TILE_INDICATOR_1_SCENE.instantiate()
		indicator_node.add_child(indicator_instance)
		indicator_instance.global_position = tile
	
	# 공격 가능 발판 그리기
	for tile in attackable_tiles:
		var indicator_instance = TILE_INDICATOR_2_SCENE.instantiate()
		indicator_node.add_child(indicator_instance)
		indicator_instance.global_position = tile
