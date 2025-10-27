extends Sprite2D

const MASCARA_DE_COLISAO_CARTA: int = 1

var arrastando := false
var offset_mouse := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var clicado := _check_se_foi_clicado()
			if clicado == self:
				arrastando = true
				offset_mouse = to_local(event.position)
		else:
			arrastando = false

	elif event is InputEventMouseMotion:
		# Verifica se o botão esquerdo ainda está pressionado e se estamos arrastando
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT and arrastando:
			var nova_posicao = event.position - offset_mouse

			var tamanho_tela := get_viewport_rect().size
			nova_posicao.x = clamp(nova_posicao.x, 0, tamanho_tela.x - get_rect().size.x)
			nova_posicao.y = clamp(nova_posicao.y, 0, tamanho_tela.y - get_rect().size.y)

			position = nova_posicao

func _check_se_foi_clicado() -> Node:
	var space_state := get_world_2d().direct_space_state
	var parametros := PhysicsPointQueryParameters2D.new()
	parametros.position = get_global_mouse_position()
	parametros.collide_with_areas = true
	parametros.collision_mask = MASCARA_DE_COLISAO_CARTA  # Ajuste conforme sua camada de colisão

	var resultado := space_state.intersect_point(parametros)
	if resultado.size() > 0:
		return resultado[0].collider.get_parent()
	return null
