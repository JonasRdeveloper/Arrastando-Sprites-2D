extends ReferenceRect

@export var tempo_encaixe: float = 0.18
@export var desabilitar_depois_de_encaixar: bool = true
@export var metodo_detectar: String = "any_overlap" # "any_overlap", "center_inside", "min_overlap_ratio"
@export var min_overlap_ratio: float = 0.2 # usado quando metodo_detectar == "min_overlap_ratio"

func _ready() -> void:
	for node in get_tree().get_nodes_in_group("draggable"):
		if node.has_signal("soltou"):
			_safe_connect(node, "soltou", "_on_item_soltou")

func _safe_connect(obj: Object, signal_name: String, method_name: String) -> void:
	if not obj.is_connected(signal_name, Callable(self, method_name)):
		obj.connect(signal_name, Callable(self, method_name))

func _on_item_soltou(_posicao_global: Vector2, item: TextureRect) -> void:
	var my_rect := get_global_rect()
	var item_rect := item.get_global_rect()

	var encaixar: bool = false
	match metodo_detectar:
		"any_overlap":
			encaixar = my_rect.intersects(item_rect)
		"center_inside":
			var item_center := item_rect.position + item_rect.size * 0.5
			encaixar = my_rect.has_point(item_center)
		"min_overlap_ratio":
			var inter := _rect_intersection(my_rect, item_rect)
			if inter.size.x > 0 and inter.size.y > 0:
				var overlap_area := inter.size.x * inter.size.y
				var item_area := item_rect.size.x * item_rect.size.y
				encaixar = (overlap_area / max(1.0, item_area)) >= min_overlap_ratio
			else:
				encaixar = false
		_:
			# fallback para any_overlap
			encaixar = my_rect.intersects(item_rect)

	if not encaixar:
		return

	var alvo := _calcular_centro_para_item(item)
	get_tree().create_tween().tween_property(item, "global_position", alvo, tempo_encaixe).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _rect_intersection(a: Rect2, b: Rect2) -> Rect2:
	var x1 = max(a.position.x, b.position.x)
	var y1 = max(a.position.y, b.position.y)
	var x2 = min(a.position.x + a.size.x, b.position.x + b.size.x)
	var y2 = min(a.position.y + a.size.y, b.position.y + b.size.y)
	if x2 <= x1 or y2 <= y1:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	return Rect2(Vector2(x1, y1), Vector2(x2 - x1, y2 - y1))

func _calcular_centro_para_item(item: TextureRect) -> Vector2:
	var my_rect := get_global_rect()
	var centro := my_rect.position + my_rect.size * 0.5
	var item_size: Vector2 = item.size
	return centro - item_size * 0.5
