extends Control

@onready var text_log = $"text log"
@onready var progress_bar = $ProgressBar
@onready var check_button = $Label/CheckButton

const conversion_data = {
	"format=3" : "format-2",
	"format-2 " : "format=2",
	"CharacterBody2D" : "KinematicBody2D",
	"VisibleOnScreenNotifier2D" : "VisibilityNotifier2D",
	"PointLight2D" : "Light2D",
	"use_hdr" : "hdr",
	"Sprite2D" : "Sprite",
	"change_scene_to_file" : "change_scene",
	"Texture2D" : "Texture",
	"&" : "",
	"@" : "",
	"extends KinematicBody2D" : "extends KinematicBody2D\nvar velocity = Vector2(0,0)",
	"move_and_slide()" : "velocity = move_and_slide(velocity)",
	'get_tree().change_scene("res://UI/LoadingScreen/LoadingScreen.tscn")' : "get_tree().change_scene(Globals.scenename)",
	"FastNoiseLite" : "OpenSimplexNoise",
	"NoiseTexture" : "OpenSimplexNoise",
	"TileSetAtlasSource" : "TileSet",
	"instantiate" : "instance",
	"PackedInt32Array" : "PoolIntArray"
}

var import_path = "C:/Users/deck/Desktop/DowngradedFiles/import"
const export_path = "C:/Users/deck/Desktop/DowngradedFiles/export"

var check_dirs = []

var converted_file

var transfer_other_files = false

func _ready():
	check_button.button_pressed = transfer_other_files
	log_text(scan_tscn_files(import_path))
	if transfer_other_files:
		log_text("Transfering other files enabled!")
	else:
		log_text(" Transfering other files disabled!")

func log_text(text = ""):
	text = str(text)
	text_log.text = text + "\n" + text_log.text
	print(text)

var files := []

func scan_tscn_files(directory_path: String) -> Array:
	var dir := DirAccess.open(directory_path)

	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		for file in dir.get_files():
			if !file.ends_with(".import") and !file.ends_with(".exe") and !file.ends_with(".godot"):
				if transfer_other_files:
					files.append(directory_path + "/" + file)
				elif file.ends_with(".tscn") or file.ends_with(".gd") or file.ends_with("tres"):
					files.append(directory_path + "/" + file)
		for path in dir.get_directories():
			#recursive, hell yeah!
			if !path.begins_with("."):
				scan_tscn_files(directory_path + "/" + path)
	return files



func _on_button_pressed():
	text_log.clear()
	progress_bar.max_value = files.size()
	progress_bar.value = 0
	for fuck in files:
		converted_file = null
		progress_bar.value += 1
		if fuck.ends_with(".tscn") or fuck.ends_with(".tres"):
			if !FileAccess.file_exists(fuck):
				log_text(fuck + " Does not exist!")
				return
			var file_data = FileAccess.open(fuck, FileAccess.READ)
			var file_text = file_data.get_as_text()
			converted_file = file_text
			if converted_file.contains("type="):
				var lines = converted_file.split("\n")  # Split text into lines
				var frames = []
				for line in lines:
					#if "ext_resource" in line:  # Check if the line contains "type="
					var regex_result : String = remove_type_with_regex(line)
					converted_file = converted_file.replace(line,regex_result)
					
				lines = converted_file.split("\n")
				for id_line in lines:
					if "id=" in id_line:
						id_placements.append(get_id_from_line(id_line))
						converted_file = converted_file.replace(str(id_placements[id_placements.size() - 1]), str(id_placements.size()))
					if fuck.ends_with(".tres"):
						
						if 'ExtResource' in lines: 
							frames.append(lines.replace('"texture": ', ""))
							#log_text(line.replace('"texture": ', ""))
							converted_file = converted_file.replace('""frames": [{\n"', '"frames": ' + str(frames))
							#log_text(frames)
			if fuck.ends_with(".tres"):
				converted_file = converted_file.replace('"texture": ', ', ')
				converted_file = converted_file.replace('"duration": 1.0,\n', '')
				converted_file = converted_file.replace(')\n}, {', ')')
				converted_file = converted_file.replace('"frames": [{\n,', '"frames": [')
				converted_file = converted_file.replace('}],', '],')
			for i in conversion_data:
				converted_file = converted_file.replace(i, conversion_data[i])
			#log_text(converted_file)
			#if !fuck.ends_with(".exe"):
				#var file_data = FileAccess.open(fuck, FileAccess.READ)
				#converted_file = file_data
		elif fuck.ends_with(".gd"):
			var file_data = FileAccess.open(fuck, FileAccess.READ)
			var file_text = file_data.get_as_text()
			converted_file = file_text
			for i in conversion_data:
				converted_file = converted_file.replace(i, conversion_data[i])
		
			
			
		var dir = export_path
		var new_export_path = fuck.replace(import_path, export_path)
		var temp_export_path = new_export_path.replace(fuck.get_file(), "") #fuck.get_file()
		if dir and not DirAccess.dir_exists_absolute(temp_export_path):
			var result = DirAccess.make_dir_recursive_absolute(temp_export_path)
			if result == OK:
				log_text("Directory created: " + temp_export_path)
			else:
				log_text("Failed to create directory: " + temp_export_path)
		
		
		var file := FileAccess.open(new_export_path, FileAccess.WRITE)
		if file:
			if converted_file is String:
				file.store_string(converted_file)
			else:
				log_text("if this is a png, it will be copied, otherwise hope it was a string ;) " + new_export_path)
				copy_file(fuck, new_export_path)
			file.close()
			log_text("File saved successfully: "+ new_export_path)
		else:
			log_text("Failed to create file: " + new_export_path)
		await get_tree().process_frame
		if progress_bar.value == progress_bar.max_value:
			log_text("Finished conversion! and remeber to set the gravity variable to 980! or else you'll be on the moon!\n*Note: Remember, there WILL be stuff still broken!")
			#add sfx for when it's finished.
			pass

func remove_type_with_regex(text: String) -> String:
	var regex = RegEx.new()
	if text.contains("uid="):
		regex.compile("uid=\"[^\"]*\"\\s*")
		return regex.sub(text, "", true)  # Replace all matches with an empty string
	else:
		return text  # Replace all matches with an empty string

var id_placements = []

func get_id_from_line(line: String) -> String:
	var parts = line.split("id=")  # Split at "id="
	if parts.size() > 1:
		return parts[1].strip_edges().replace("]", "")  # Remove extra spaces/brackets
	return ""  # Return empty if no ID found

func copy_file(src: String, dest: String) -> bool:
	var file = FileAccess.open(src, FileAccess.READ)

	if file:
		var content = file.get_buffer(file.get_length())  # Read entire file
		file.close()

		var new_file = FileAccess.open(dest, FileAccess.WRITE)
		if new_file:
			new_file.store_buffer(content)  # Write to new location
			new_file.close()
			print("File copied successfully to: " + dest)
			return true
		else:
			print("Failed to create new file.")
	else:
		print("Source file not found.")

	return false



func _on_check_button_toggled(toggled_on):
	transfer_other_files = toggled_on
	_ready()

var tile_map : TileMap

#65536, 0, 0 
#y = 1
#x = 0
#65537, 0, 0 
#y = 1
#x = 1
