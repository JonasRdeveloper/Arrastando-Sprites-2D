# No script principal do seu jogo (ex: Main.gd)
extends Control

@onready var hand: HandOfCards = $Mao_de_cartas

func _ready():
	# Adicionar algumas cartas iniciais
	for i in range(5):
		var new_card = preload("res://src/cenas/arrastavel.tscn").instantiate()
		hand.add_card(new_card)

	# Conectar o sinal de soltura de todas as cartas à mão
	for card in get_tree().get_nodes_in_group("draggable"):
		if card.has_signal("soltou"):
			card.connect("soltou", hand._on_item_soltou)

# Exemplo de comprar uma carta
func comprar_carta():
	var new_card = preload("res://src/cenas/arrastavel.tscn").instantiate()
	hand.add_card(new_card)
