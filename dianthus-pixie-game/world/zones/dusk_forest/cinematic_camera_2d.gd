extends Camera2D

@export var move_speed: float = 35.0
@export var acceleration: float = 3.0
@export var auto_quit_after_seconds: float = 0.0 # 0 = tidak auto quit

var moving_up := false
var velocity := Vector2.ZERO
var timer := 0.0

func _ready() -> void:
	make_current()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_UP:
				# Sekali tekan Up = mulai naik perlahan.
				# Tekan Up lagi = berhenti.
				moving_up = !moving_up

			KEY_SPACE:
				# Stop kamera.
				moving_up = false

			KEY_ESCAPE:
				get_tree().quit()

func _process(delta: float) -> void:
	if auto_quit_after_seconds > 0.0:
		timer += delta
		if timer >= auto_quit_after_seconds:
			get_tree().quit()

	var target_velocity := Vector2.ZERO

	if moving_up:
		target_velocity = Vector2.UP * move_speed
		# Vector2.UP berarti y negatif, jadi kamera naik ke atas map.

	velocity = velocity.lerp(
		target_velocity,
		clamp(acceleration * delta, 0.0, 1.0)
	)

	global_position += velocity * delta