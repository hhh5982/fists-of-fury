class_name BasicEnemy
extends Character

@export var player : Player
@export var duration_between_hits: int
@export var duration_prep_hits : int

var time_since_last_hits := Time.get_ticks_msec()
var time_since_prep_hits := Time.get_ticks_msec()

var player_slot : EnemySlot = null

func handle_input() -> void:
	if player != null and can_move():
		if player_slot == null:
			player_slot = player.reserve_slot(self)
		
		if player_slot != null:
			var direction := (player_slot.global_position - global_position).normalized()
			if is_player_within_range() and can_attack():
				velocity = Vector2.ZERO
			else:
				velocity = direction * speed
func is_player_within_range() -> bool:
	return (player_slot.global_position - global_position).length()<1

func can_attack() -> bool:
	if Time.get_ticks_msec()-time_since_last_hits <duration_between_hits:
		return false
	return super.can_attack()
func handle_prep_attack() -> void:
	if state == State.PREP_ATTACK and (Time.get_ticks_msec() - time_since_prep_hits > duration_prep_hits):
		state = State.ATTACK
		time_since_last_hits = Time.get_ticks_msec()
		anim_attacks.shuffle()#打乱动画顺序

func set_heading() -> void:
	if player == null:
		return
	heading = Vector2.LEFT if position.x > player.position.x else Vector2.RIGHT

func on_receive_damage(amount: int, direction: Vector2, hit_type: DamageReceiver.HitType) -> void:
	super.on_receive_damage(amount, direction, hit_type)
	if current_health == 0:
		player.free_slot(self)
