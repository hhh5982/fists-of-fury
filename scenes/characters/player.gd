class_name Player
extends Character

@onready var enemy_slots : Array = $EnemySlots.get_children()

# 连发相关配置（可根据手感调整）
@export var attack_fire_rate : float = 0.2  # 连发间隔（秒），值越小越快
var attack_cooldown : float = 0.0  # 冷却计时器

# 跳跃踢单次跳跃限制
var has_used_jumpkick := false

func _ready() -> void:
	super._ready()  # 调用父类Character的_ready初始化
	anim_attacks = ["punch", "punch_alt", "kick", "roundkick"]
	has_used_jumpkick = false

	
func _process(delta: float) -> void:
	super._process(delta)  # 继承父类的_process逻辑（移动、动画等）
	update_attack_cooldown(delta)  # 更新攻击冷却
	handle_attack_hold_fire()  # 处理按住攻击连发

func handle_input() -> void:
	# 移动输入（保留你的原逻辑）
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed

	# 跳跃输入（保留你的原逻辑）
	if can_jump() and Input.is_action_just_pressed("jump"):
		state = State.TAKEOFF
		has_used_jumpkick = false  # 跳跃时重置跳跃踢标记

	# 跳跃踢输入（保留你的原逻辑，增加单次跳跃限制）
	if can_jumpkick() and Input.is_action_just_pressed("attack") and not has_used_jumpkick:
		state = State.JUMPKICK
		has_used_jumpkick = true

func update_attack_cooldown(delta: float) -> void:
	# 冷却计时器递减（确保连发有间隔，避免帧级别的极速攻击）
	if attack_cooldown > 0:
		attack_cooldown -= delta

func handle_attack_hold_fire() -> void:
	# 条件：按住攻击键 + 可攻击状态 + 冷却结束 + 非跳跃踢状态
	if (Input.is_action_pressed("attack") 
		and can_attack() 
		and attack_cooldown <= 0 
		and state != State.JUMPKICK):
		if has_knife:
			state = State.THROW
		else :
			state = State.ATTACK
			# 连击逻辑（保留你的原逻辑：命中则递增索引，未命中则重置）
			if is_last_hit_successful:
				attack_combo_index = (attack_combo_index + 1) % anim_attacks.size()
				is_last_hit_successful = false  # 重置命中标记，等待下一次命中
			else:
				attack_combo_index = 0  # 未命中则从第一个攻击开始
			
			attack_cooldown = attack_fire_rate  # 重置冷却时间

func set_heading() -> void:
	# 保留你的原逻辑：基于移动方向更新朝向
	if velocity.x > 0:
		heading = Vector2.RIGHT
	elif velocity.x < 0:
		heading = Vector2.LEFT

# 重写父类的on_emit_damage，修复最后一击伤害传递错误
func on_emit_damage(receiver: DamageReceiver) -> void:
	var hit_type := DamageReceiver.HitType.NORMAL
	var direction := Vector2.LEFT if receiver.global_position.x < global_position.x else Vector2.RIGHT
	var current_damage = damage

	if state == State.JUMPKICK:
		hit_type = DamageReceiver.HitType.KNOCKDOWN
	# 最后一击判定（强力伤害）
	if attack_combo_index == anim_attacks.size() - 1:
		hit_type = DamageReceiver.HitType.POWER
		current_damage = damage_power

	receiver.damage_received.emit(current_damage, direction, hit_type)  # 传递计算后的伤害
	is_last_hit_successful = true  # 标记命中，允许下一次连击

# 重写落地回调，重置跳跃踢标记
func on_land_complete() -> void:
	super.on_land_complete()  # 调用父类的落地逻辑（切换为IDLE）
	has_used_jumpkick = false  # 落地后可再次使用跳跃踢

# 敌人插槽管理（保留你的原逻辑）
func reserve_slot(enemy: BasicEnemy) -> EnemySlot:
	var available_slots := enemy_slots.filter(
		func(slot): return slot.is_free()
	)
	if available_slots.size() == 0:
		return null
	available_slots.sort_custom(
		func(a: EnemySlot, b: EnemySlot):
			var dist_a := (enemy.global_position - a.global_position).length()
			var dist_b := (enemy.global_position - b.global_position).length()
			return dist_a < dist_b
	)
	available_slots[0].occupy(enemy)
	return available_slots[0]

func free_slot(enemy: BasicEnemy) -> void:
	var target_slots := enemy_slots.filter(
		func(slot: EnemySlot): return slot.occupant == enemy
	)
	if target_slots.size() == 1:
		target_slots[0].free_up()
