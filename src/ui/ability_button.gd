class_name AbilityButton
extends Control
## One of the chaos player's big round buttons: the creature's picture, a grey
## wedge that shrinks while it recharges, a ring that runs down while it's out,
## and a diamond showing which controller buttons summon it.

const RADIUS := 74.0

var ability: ChaosAbility
var cooldown: Cooldown
var controller: ChaosController

var _portrait: Portrait
var _time := 0.0
var _bounce := 0.0
var _shake := 0.0


func _init(chaos_ability: ChaosAbility, chaos: ChaosController) -> void:
	ability = chaos_ability
	controller = chaos
	cooldown = chaos.cooldown_of(chaos_ability)
	custom_minimum_size = Vector2(RADIUS * 2.0 + 24.0, RADIUS * 2.0 + 74.0)


func _ready() -> void:
	_portrait = Portrait.new(ability.portrait)
	add_child(_portrait)
	cooldown.became_ready.connect(_on_ready_again)
	Events.chaos_summoned.connect(_on_summoned)


func _process(delta: float) -> void:
	_time += delta
	_bounce = move_toward(_bounce, 0.0, delta * 1.6)
	_shake = move_toward(_shake, 0.0, delta * 3.0)
	if _summon_blocked() and controller.slot.device.any_just_pressed(ability.buttons):
		_shake = 1.0
	queue_redraw()


func _draw() -> void:
	var ready := cooldown.is_ready() and not controller.is_busy()
	var center := Vector2(size.x * 0.5 + sin(_shake * 40.0) * 8.0 * _shake, RADIUS + 8.0)
	var r := RADIUS * (1.0 + (0.04 * sin(_time * 4.0) if ready else 0.0) + 0.18 * sin(_bounce * PI))
	var rim := ability.color if ready else ability.color.lerp(Color(0.5, 0.5, 0.55), 0.6)

	draw_circle(center + Vector2(0, 7), r, UiKit.SHADOW, true, -1.0, true)
	draw_circle(center, r, rim, true, -1.0, true)
	draw_circle(center, r - 10.0, UiKit.CREAM, true, -1.0, true)
	var face := r * 0.95
	draw_texture_rect(_portrait.get_texture(), Rect2(center - Vector2(face, face), Vector2(face, face) * 2.0), false,
		Color.WHITE if ready or cooldown.state == Cooldown.State.ACTIVE else Color(1, 1, 1, 0.55))
	match cooldown.state:
		Cooldown.State.COOLING:
			UiKit.draw_pie(self, center, r - 10.0, cooldown.remaining(), Color(0.25, 0.25, 0.35, 0.55))
		Cooldown.State.ACTIVE:
			draw_arc(center, r - 5.0, -PI * 0.5, -PI * 0.5 + TAU * cooldown.remaining(), 64, UiKit.CREAM, 9.0, true)
	draw_arc(center, r, 0.0, TAU, 64, UiKit.INK, 6.0, true)
	if ready:
		for i in 3:
			var angle := _time * 1.5 + i * TAU / 3.0
			UiKit.draw_star(self, center + Vector2(cos(angle), sin(angle)) * (r + 4.0), 11.0, UiKit.SUN)
	UiKit.draw_button_diamond(self, Vector2(size.x * 0.5, RADIUS * 2.0 + 44.0), 17.0, ability.buttons, ability.color)


func _summon_blocked() -> bool:
	return not cooldown.is_ready() or controller.is_busy()


func _on_ready_again() -> void:
	_bounce = 1.0


func _on_summoned(summoned: ChaosAbility) -> void:
	if summoned == ability:
		_bounce = 1.0
