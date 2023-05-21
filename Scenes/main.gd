extends Node2D

const DummyNetworkAdaptor = preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd")

#@onready var main_menu = $CanvasLayer/MainMenu
@onready var connection_panel = $CanvasLayer/ConnectionPanel
@onready var host_field = $CanvasLayer/ConnectionPanel/OuterDiv/InnerDiv/GridContainer/HostField
@onready var port_field = $CanvasLayer/ConnectionPanel/OuterDiv/InnerDiv/GridContainer/PortField
@onready var message_label = $CanvasLayer/MessageLabel
@onready var sync_lost_label = $CanvasLayer/SyncLostLabel
#@onready var reset_button = $CanvasLayer/ResetButton
#@onready var johnny = $Johnny
@onready var mp = get_tree().get_multiplayer()

const LOG_FILE_DIRECTORY = 'user://detailed_logs'

var logging_enabled := true

func _ready() -> void:
	mp.connect("peer_connected", _on_network_peer_connected)
	mp.connect("peer_disconnected",_on_network_peer_disconnected)
	mp.connect("server_disconnected", _on_server_disconnected)
	SyncManager.connect("sync_started", _on_SyncManager_sync_started)
	SyncManager.connect("sync_stopped", _on_SyncManager_sync_stopped)
	SyncManager.connect("sync_lost", _on_SyncManager_sync_lost)
	SyncManager.connect("sync_regained", _on_SyncManager_sync_regained)
	SyncManager.connect("sync_error", _on_SyncManager_sync_error)

func _on_server_button_pressed() -> void:
#	johnny.randomize()
	var peer = ENetMultiplayerPeer.new()
	print("Creating server on " + port_field.text)
	peer.create_server(int(port_field.text), 1)
	mp.set_multiplayer_peer(peer)
#	main_menu.visible = false
	connection_panel.visible = false
	message_label.text = "Listening..."

func _on_client_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	print("Creating client on " + port_field.text)
	peer.create_client(host_field.text, int(port_field.text))
	mp.set_multiplayer_peer(peer)
#	main_menu.visible = false
	connection_panel.visible = false
	message_label.text = "Connecting..."

func _on_network_peer_connected(peer_id: int):
	message_label.text = "Connected!"
	SyncManager.add_peer(peer_id)
#
#	$ServerPlayer.set_network_master(1)
#	if mp.is_server():
#		$ClientPlayer.set_network_master(peer_id)
#	else:
#		$ClientPlayer.set_network_master(get_tree().get_network_unique_id())
#
	if mp.is_server():
		message_label.text = "Starting..."
#		rpc("setup_match", {mother_seed = johnny.get_seed()})
#
#		# Give a little time to get ping data.
		await get_tree().create_timer(2.0).timeout
		SyncManager.start()
#
#@rpc("any_peer")
#func setup_match(info: Dictionary) -> void:
#	johnny.set_seed(info['mother_seed'])
#	$ClientPlayer.rng.set_seed(johnny.randi())
#	$ServerPlayer.rng.set_seed(johnny.randi())

func _on_network_peer_disconnected(peer_id: int):
	message_label.text = "Disconnected"
	SyncManager.remove_peer(peer_id)

func _on_server_disconnected() -> void:
	_on_network_peer_disconnected(1)

func _on_reset_button_pressed() -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer = mp.multiplayer_peer
	if peer:
		peer.close()
	get_tree().reload_current_scene()

func _on_SyncManager_sync_started() -> void:
	message_label.text = "Started!"

#	if logging_enabled: #and not SyncReplay.active:
#		var dir = DirAccess.open(LOG_FILE_DIRECTORY)
#		if dir == null:
#			dir.make_dir(LOG_FILE_DIRECTORY)
#
#		var datetime = Time.get_datetime_dict_from_system(true)
#		var log_file_name = "%04d%02d%02d-%02d%02d%02d-peer-%d.log" % [
#			datetime['year'],
#			datetime['month'],
#			datetime['day'],
#			datetime['hour'],
#			datetime['minute'],
#			datetime['second'],
#			SyncManager.network_adaptor.get_network_unique_id(),
#		]
#
#		SyncManager.start_logging(LOG_FILE_DIRECTORY + '/' + log_file_name)

func _on_SyncManager_sync_stopped() -> void:
	pass
#	if logging_enabled:
#		SyncManager.stop_logging()

func _on_SyncManager_sync_lost() -> void:
	sync_lost_label.visible = true

func _on_SyncManager_sync_regained() -> void:
	sync_lost_label.visible = false

func _on_SyncManager_sync_error(msg: String) -> void:
	message_label.text = "Fatal sync error: " + msg
	sync_lost_label.visible = false

	var peer = mp.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()

#func setup_match_for_replay(my_peer_id: int, peer_ids: Array, match_info: Dictionary) -> void:
#	main_menu.visible = false
#	connection_panel.visible = false
#	reset_button.visible = false
#
#func _on_OnlineButton_pressed() -> void:
#	connection_panel.popup_centered()
#	SyncManager.reset_network_adaptor()
#
#func _on_LocalButton_pressed() -> void:
#	$ClientPlayer.input_prefix = "player2_"
#	main_menu.visible = false
#	SyncManager.network_adaptor = DummyNetworkAdaptor.new()
#	SyncManager.start()
#
#
#func _on_client_button_pressed():
#	pass # Replace with function body.
