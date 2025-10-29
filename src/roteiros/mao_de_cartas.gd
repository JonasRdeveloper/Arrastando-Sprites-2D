extends Control
class_name HandOfCards

@export_category("Configurações da Mão")
@export var curve: Curve2D
@export var card_spacing: float = 80.0
@export var max_rotation: float = 15.0
@export var curve_height: float = 100.0
@export var animation_speed: float = 8.0
@export var card_scale: float = 1.0
@export var raise_height: float = 30.0  # Elevação quando mouse sobre a carta

var cards: Array[TextureRect] = []
var target_positions: Array[Vector2] = []
var target_rotations: Array[float] = []
var card_scales: Array[float] = []
var raised_card: int = -1  # Índice da carta elevada

func _ready() -> void:
	# Criar curva padrão se não foi atribuída
	if not curve:
		create_default_curve()
	
	# Conectar sinais de hover das cartas existentes
	call_deferred("connect_existing_cards")

func create_default_curve() -> void:
	curve = Curve2D.new()
	# Criar um arco suave
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0, -curve_height))
	curve.add_point(Vector2(0, 0))

func connect_existing_cards() -> void:
	# Conectar a cartas que já são filhos deste nó
	for child in get_children():
		if child is TextureRect and child.has_method("_on_mouse_entered"):
			if not child.is_connected("mouse_entered", Callable(self, "_on_card_mouse_entered")):
				child.connect("mouse_entered", Callable(self, "_on_card_mouse_entered"))
			if not child.is_connected("mouse_exited", Callable(self, "_on_card_mouse_exited")):
				child.connect("mouse_exited", Callable(self, "_on_card_mouse_exited"))
			cards.append(child)
	
	update_card_positions()

func add_card(card: TextureRect) -> void:
	if cards.has(card):
		return
	
	# Fazer reparenting suave
	var old_parent = card.get_parent()
	if old_parent and old_parent != self:
		old_parent.remove_child(card)
	
	add_child(card)
	cards.append(card)
	
	# Conectar sinais de hover
	if not card.is_connected("mouse_entered", Callable(self, "_on_card_mouse_entered")):
		card.connect("mouse_entered", Callable(self, "_on_card_mouse_entered"))
	if not card.is_connected("mouse_exited", Callable(self, "_on_card_mouse_exited")):
		card.connect("mouse_exited", Callable(self, "_on_card_mouse_exited"))
	
	update_card_positions()

func remove_card(card: TextureRect) -> void:
	if cards.has(card):
		cards.erase(card)
		# Não remover como filho, apenas da lista de controle
		update_card_positions()

func update_card_positions() -> void:
	target_positions.clear()
	target_rotations.clear()
	card_scales.clear()
	
	if cards.is_empty():
		return
	
	# Calcular posições baseadas na curva
	var total_width = (cards.size() - 1) * card_spacing
	var start_x = -total_width / 2
	
	for i in cards.size():
		var t = float(i) / max(1, cards.size() - 1)
		var curve_length = curve.get_baked_length()
		var curve_point = curve.sample_baked(t * curve_length)
		
		var x = start_x + i * card_spacing
		var y = curve_point.y
		rotation = lerp(-max_rotation, max_rotation, t)
		
		target_positions.append(Vector2(x, y))
		target_rotations.append(deg_to_rad(rotation))
		card_scales.append(card_scale)

func _process(delta: float) -> void:
	# Animar cartas para suas posições alvo
	for i in range(cards.size()):
		var card = cards[i]
		if i < target_positions.size():
			var target_pos = target_positions[i]
			var target_rot = target_rotations[i]
			var target_scale = Vector2.ONE * card_scales[i]
			
			# Aplicar elevação se esta carta está com mouse sobre
			if i == raised_card:
				target_pos.y -= raise_height
				target_scale = Vector2.ONE * (card_scale * 1.1)
			
			card.position = card.position.lerp(target_pos, delta * animation_speed)
			card.rotation = lerp_angle(card.rotation, target_rot, delta * animation_speed)
			card.scale = card.scale.lerp(target_scale, delta * animation_speed * 2)

# Método para integrar com seu sistema de arrastar/soltar
func _on_item_soltou(posicao_global: Vector2, item: TextureRect) -> void:
	var hand_rect = get_global_rect().grow(100.0)  # Área expandida para detectar soltura
	
	if hand_rect.has_point(posicao_global):
		# Soltou perto da mão - adicionar à mão
		if not cards.has(item):
			add_card(item)
	else:
		# Soltou longe - remover da mão
		if cards.has(item):
			remove_card(item)

# Hover effects
func _on_card_mouse_entered() -> void:
	for i in range(cards.size()):
		if cards[i].has_focus():
			raised_card = i
			break

func _on_card_mouse_exited() -> void:
	raised_card = -1

# Métodos utilitários
func get_card_index(card: TextureRect) -> int:
	return cards.find(card)

func get_card_count() -> int:
	return cards.size()

func clear_hand() -> void:
	for card in cards:
		card.queue_free()
	cards.clear()
	target_positions.clear()
	target_rotations.clear()

# Reorganizar cartas (útil para jogos onde a ordem importa)
func reorganize_cards(new_order: Array[TextureRect]) -> void:
	if new_order.size() != cards.size():
		push_warning("A nova ordem deve conter as mesmas cartas")
		return
	
	cards = new_order.duplicate()
	update_card_positions()

# Salvar/restaurar estado da mão
func save_hand_state() -> Dictionary:
	var state = {
		"card_count": cards.size(),
		"card_positions": [],
		"card_rotations": []
	}
	
	for i in range(cards.size()):
		state["card_positions"].append(cards[i].position)
		state["card_rotations"].append(cards[i].rotation)
	
	return state

func restore_hand_state(state: Dictionary) -> void:
	if state.has("card_count") and state["card_count"] == cards.size():
		for i in range(cards.size()):
			if i < state["card_positions"].size():
				cards[i].position = state["card_positions"][i]
				cards[i].rotation = state["card_rotations"][i]
