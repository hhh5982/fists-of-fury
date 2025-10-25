class_name BasicEnemy
extends Character

@export var player : Player


#准备时间设置-近战
@export var duration_prep_melee_attack : int
#获取游戏时间点
var time_since_prep_melee_attack := Time.get_ticks_msec()
#攻击间隔设置-近战攻击
@export var duration_between_melee_attacks : int
#获取最后攻击游戏时间点
var time_since_last_melee_attack := Time.get_ticks_msec()

#准备时间设置-远程
@export var duration_prep_range_attack : int
#获取游戏时间点
var time_since_prep_range_attack := Time.get_ticks_msec()
#攻击间隔设置-远程瞄准
@export var duration_between_range_attacks : int
#获取最后攻击游戏时间点
var time_since_last_range_attack := Time.get_ticks_msec()




var player_slot : EnemySlot = null
func _ready() -> void:
	super._ready()
	anim_attacks = ["punch", "punch_alt"]
func handle_input() -> void:
	if player != null and can_move():
		if can_respawn_knives :
			goto_range_position()
		else:
			goto_melee_position()


func goto_melee_position():
		if player_slot == null:
			player_slot = player.reserve_slot(self)
		
		if player_slot != null:
			var direction := (player_slot.global_position - global_position).normalized()
			if is_player_within_range() and can_attack():
				velocity = Vector2.ZERO
				if can_attack():
					state=State.PREP_ATTACK
			else:
				velocity = direction * speed
func goto_range_position():
	#获取相机位置
	var camera := get_viewport().get_camera_2d()
	#获取屏幕大小
	var screen_width := get_viewport_rect().size.x
	#屏幕左边距离=相机位置-屏幕大小的1/2
	var screen_left_edge := camera.position.x - screen_width / 2
	#屏幕右边距离=相机位置+屏幕大小的1/2
	var screen_right_edge := camera.position.x + screen_width / 2
	#设置一个常量，用于控制敌人距离屏幕边缘距离
	const EDGE_SCREEN_BUFFER := 0
	#敌人在左边和右边屏幕边缘位置
	var left_destination := Vector2(screen_left_edge + EDGE_SCREEN_BUFFER, player.position.y)
	var right_destination := Vector2(screen_right_edge - EDGE_SCREEN_BUFFER, player.position.y)
	#设置一个变量，用于获取去屏幕左边还是右边
	var closest_destination := Vector2.ZERO
	#如果左边屏幕近则去左边，否则右边
	if (left_destination - position).length() < (right_destination - position).length():
		closest_destination = left_destination
	else:
		closest_destination = right_destination
	#弱国距离屏幕边缘小于1像素，则速度为0，否则移动刀最近的屏幕边缘
	if (closest_destination - position).length() < 1:
		velocity = Vector2.ZERO
	else:
		velocity = (closest_destination - position).normalized() * speed
	#如果可以投掷且有飞刀且
	if can_throw() and has_knife and projectile_aim.is_colliding():
		state = State.THROW
		#记录飞刀消失时间和飞刀最后一次远程攻击时间
		time_since_knife_dismiss = Time.get_ticks_msec()
		time_since_last_range_attack = Time.get_ticks_msec()
func can_throw() -> bool:
	if Time.get_ticks_msec() - time_since_last_range_attack < duration_between_range_attacks:
		return false
	return super.can_attack()

func is_player_within_range() -> bool:
	return (player_slot.global_position - global_position).length()<1

func can_attack() -> bool:
	if Time.get_ticks_msec()-time_since_prep_melee_attack <duration_between_melee_attacks:
		return false
	return super.can_attack()
func handle_prep_attack() -> void:
	if state == State.PREP_ATTACK and (Time.get_ticks_msec() - time_since_prep_melee_attack > duration_prep_melee_attack):
		state = State.ATTACK
		time_since_prep_melee_attack = Time.get_ticks_msec()
		anim_attacks.shuffle()#打乱动画顺序

func set_heading() -> void:
	if player == null:
		return
	heading = Vector2.LEFT if position.x > player.position.x else Vector2.RIGHT

func on_receive_damage(amount: int, direction: Vector2, hit_type: DamageReceiver.HitType) -> void:
	super.on_receive_damage(amount, direction, hit_type)
	if current_health == 0:
		player.free_slot(self)
