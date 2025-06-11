extends ColorRect



@onready var cont := $ScrollContainer/Container
@onready var Npath: TextEdit = $File/FilePath
@onready var pinned: VBoxContainer = $VBoxContainer/Pinned

var path : String = ""
var file := false

func _ready() -> void:
	path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	set_layout()
	for i in Pinned.pinned:
		add_pinned(i)

func add_pinned(arr:Array):
	print("Added ", arr[0])
	var nBut = Button.new()
	nBut.text = arr[0]
	pinned.add_child(nBut)
	nBut.pressed.connect(to_dir.bind(arr[1]))

func to_dir(new_path):
	path = new_path
	set_layout()

func open_folder(folder_name: String):
	if file:
		path = path.get_base_dir()
	path = path + "/" + folder_name
	set_layout()

func open_file(file_name: String):
	if file:
		path = path.get_base_dir()
	path = path + "/" + file_name
	Npath.text = path
	file = true

func set_layout():
	var folder_count = 0
	Npath.text = path
	for i in cont.get_children(): i.queue_free()
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var nBut := Button.new()
		cont.add_child(nBut)
		if dir.current_is_dir():
			nBut.text = "📁 " + file_name
			cont.move_child(nBut, folder_count)
			folder_count += 1
			nBut.pressed.connect(open_folder.bind(file_name))
		else:
			nBut.text = "📇 " + file_name
			nBut.pressed.connect(open_file.bind(file_name))
		file_name = dir.get_next()
			


func _on_up_folder_pressed() -> void:
	if file: path = path.get_base_dir()
	path = path.get_base_dir()
	set_layout()

func _on_open_pressed() -> void:
	get_parent().emit_signal("done", Npath.text)
	get_parent().hide()


func _on_cancel_pressed() -> void:
	get_parent().hide()

func _on_new_folder_pressed() -> void:
	$AddFolder.show()

func _on_create_folder_pressed() -> void:
	$AddFolder.hide()
	if file: path = path.get_base_dir()
	var dir = DirAccess.open(path)
	dir.make_dir_absolute(path + "/" + $AddFolder/FolderName.text)
	$AddFolder/FolderName.text = ""
	set_layout()


func _on_cancel_new_folder_pressed() -> void:
	$AddFolder.hide()
	$AddFolder/FolderName.text = ""
