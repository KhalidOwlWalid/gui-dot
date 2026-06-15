class_name Guidot_Log

enum Log_Level {
	DEBUG   = 0,
	WARNING = 1,
	INFO    = 2,
	ERROR   = 3,
}

static var global_log_level: Log_Level = Log_Level.INFO

static func gd_log(log_level: Log_Level, tag: String, args: Array) -> void:
	var msg_parts: Array = []
	for arg in args:
		msg_parts.append(str(arg))
	var final_msg: String = " ".join(msg_parts)
	
	var level_prefix: String = "[" + Log_Level.keys()[log_level] + "] "

	var rich_msg: String
	var comp_tag: String = "[{comp_tag}]: ".format({"comp_tag": tag})
	match log_level:
		Log_Level.DEBUG:
			rich_msg = "[color=#888888][DEBUG]" + comp_tag + final_msg  + "[/color]" # Gray
		Log_Level.WARNING:
			rich_msg = "[color=#FFAA00][WARNING]" + comp_tag + final_msg + "[/color]"  # Orange
		Log_Level.INFO:
			rich_msg = "[color=#00FF00][INFO]" + comp_tag + final_msg + "[/color]" # Green
		Log_Level.ERROR:
			rich_msg = "[color=#FF0000][ERROR]" + comp_tag + final_msg  + "[/color]" # Red

	if (log_level >= global_log_level):
		print_rich(rich_msg)
