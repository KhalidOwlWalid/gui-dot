class_name Guidot_Error
extends RefCounted

var error_type: Error
var error_info: String
var message: String
var source_node: String
var source_func: String
var source_full: String

static func generate_error(error_type: Error, msg: String, src_node: String = "", src_func: String = "") -> Guidot_Error:
	var gd_error: Guidot_Error = Guidot_Error.new()
	gd_error.error_type = error_type
	gd_error.error_info = error_string(error_type) + " [Error No: " + str(error_type) + "]"
	gd_error.message = msg
	gd_error.source_node = src_node
	gd_error.source_func = src_func
	gd_error.source_full = "Node: " + src_node + ", Function: " + src_func
	return gd_error

static func ok() -> Guidot_Error:
	var gd_error: Guidot_Error = Guidot_Error.new()
	gd_error.error_type = Error.OK
	gd_error.message = ""
	return gd_error
