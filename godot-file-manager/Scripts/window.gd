extends Window

signal done(path:String)

func _on_close_requested() -> void:
	hide()

func _on_done(path: String) -> void:
	print(path)
