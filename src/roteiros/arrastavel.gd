extends TextureRect

signal soltou(nova_posicao_global: Vector2, item: TextureRect)

@export_category("Configurações")
@export var permitir_arrasto: bool = true
@export var trancar_ao_pai: bool = false

var _arrastando: bool = false
var _deslocamento_arrasto: Vector2 = Vector2.ZERO
var _posicao_inicial: Vector2 = Vector2.ZERO
var _mouse_over: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_posicao_inicial = global_position
	call_deferred("move_to_front")
	# conecta sinais nativos para feedback (pode fazer no editor também)
	if not is_connected("mouse_entered", Callable(self, "_on_mouse_entered")):
		connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	if not is_connected("mouse_exited", Callable(self, "_on_mouse_exited")):
		connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	# opcional: adicionar ao grupo para referência externa
	if not is_in_group("draggable"):
		add_to_group("draggable")

func _gui_input(event: InputEvent) -> void:
	if not permitir_arrasto:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_arrastando = true
			_deslocamento_arrasto = get_global_mouse_position() - global_position
			move_to_front()
		else:
			if _arrastando:
				_arrastando = false
				_emitir_soltou()
				emit_signal("soltou", global_position, self)

	elif event is InputEventMouseMotion and _arrastando:
		var nova_pos := get_global_mouse_position() - _deslocamento_arrasto
		if trancar_ao_pai and get_parent() is Control:
			nova_pos = _limitar_ao_pai(nova_pos)
		global_position = nova_pos

func _emitir_soltou() -> void:
	#var interpolar: Tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)
	#interpolar.tween_property(self, 'scale', Vector2.ONE, .1)
	# comportamento padrão ao soltar: nada além do sinal
	# se quiser animar de volta quando for solto fora de alvo, faça aqui
	pass

func _limitar_ao_pai(posicao_global: Vector2) -> Vector2:
	var pai := get_parent() as Control
	if not pai:
		return posicao_global
	var pai_rect := pai.get_global_rect()
	var local_pos := posicao_global - pai_rect.position
	var tamanho_self: Vector2 = size
	local_pos.x = clamp(local_pos.x, 0.0, max(0.0, pai_rect.size.x - tamanho_self.x))
	local_pos.y = clamp(local_pos.y, 0.0, max(0.0, pai_rect.size.y - tamanho_self.y))
	return pai_rect.position + local_pos
## ho
# Feedback visual / estados de mouse
func _on_mouse_entered() -> void:
	_mouse_over = true
	scale = Vector2(1.05, 1.05)
	modulate = Color(0.732, 0.0, 0.009, 1.0)

func _on_mouse_exited() -> void:
	_mouse_over = false
	scale = Vector2(1.0, 1.0)
	modulate = Color(0.625, 0.758, 0.719, 1.0)
