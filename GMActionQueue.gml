/**
* GMActionQueue sends a function name (or an anonymous function) and it's arguments to a queue with an ID, and can call that Action using the ID at a later time.
*
* Each queue ID can have as many Actions as it needs, and whenever an Action is completed, it will be removed from the queue.
*
* @returns {struct.GMActionQueue}
*/
function GMActionQueue() {
  
	static __action = undefined;
  
	if __action != undefined {
		return __action;	
	}
  
	static __action_list = {};
	static __action_enable = false;
	static __action_id  = "";
  
	#region Action Network
  
	static __port = 6510;
	static __action_server = network_create_server(network_socket_tcp, __port, 1);
	while (__action_server < 0 && __port < 65535) {
		__port++
		__action_server = network_create_server(network_socket_tcp, __port, 1);
	}
	static __action_socket = network_create_socket(network_socket_tcp);
	static __action_connect = network_connect(__action_socket, "127.0.0.1", __port);
  
	#endregion
  
	/**
	* Add function to the Action queue. If the function returns -1, the Action will recall it until it returns anything else.
	* @param {string | real} _action_id Queue ID. (Non-strings will be converted to strings).
	* @param {function} _func Function name or anonymous function.
	* @param {any} ... Argument(s) for the function to read.
	*/
	static action			= function(_action_id, _func) {
  
		var _action_string = string(_action_id);
  
		if !is_array(__action_list[$ _action_string]) {
			__action_list[$ _action_string] = [];
		}
  
		var _args = [];
    
		for (var i = 2; i < argument_count; ++i) {
			_args[i - 2] = argument[i];
		}
  
		array_push(__action_list[$ _action_string], {
			func : _func,
			args : variable_clone(_args)
		});
	}
	/**
	* Call Action from the queue using an ID.
	* @param {string | real} _action_id Queue ID. (Non-strings will be converted to strings).
	*/
	
	static action_call		= function(_action_id) {
		
		if !struct_exists(__action_list, _action_id) { exit; }
		
		__action_enable = false;
		__action_id  = "";
    
		var _action_buffer = buffer_create(1, buffer_grow, 1);
		var _buffer_seek   = buffer_seek(_action_buffer, buffer_seek_start, 0);
		var _buffer_write  = buffer_write(_action_buffer, buffer_text, string(_action_id));
		var _packet_result = network_send_packet(__action_socket, _action_buffer, buffer_tell(_action_buffer));
    
		buffer_delete(_action_buffer);
    
		if _packet_result < 0 {
			show_debug_message("Action call denied. Data not sent.");
		}
	}
	
	/**
	* Wait for Action to be sent to Async - Networking and processed.
	* @param {id.dsmap} _load Async load.
	*/
	static action_await		= function(_load = async_load) {
		
		if ds_map_find_value(_load, "type") == network_type_disconnect and ds_map_find_value(_load, "port") == __port {
			action_reconnect();
			exit;
		}
  
		var _buffer = ds_map_find_value(_load, "buffer");
		if _buffer != undefined and ds_map_find_value(_load, "port") == __port {
			var _buffer_seek = buffer_seek(_buffer, buffer_seek_start, 0);
			var _buffer_read = buffer_read(_buffer, buffer_text);
			action_receive(_buffer_read);
			buffer_delete(_buffer);
		}
	}
	
	/**
	* Listen for any Action to be executed. Removes Action from queue and returns it's ID after execution, else returns -1.
	//* @returns {any}
	*/
	static action_listen	= function() {
		
		if __action_enable {
			var _return_id = __action_id;
			action_execute(__action_id);
			return _return_id;
		}
		return -1;
	}
	
	/// @ignore
	static action_receive	= function(_action_id) {
		
		__action_enable = true;
		__action_id = _action_id;
	}
	
	/// @ignore
	static action_execute	= function(_action_id) {
  
		var _action_string = string(_action_id);
    
		var _action_get = __action_list[$ _action_string][0];
    
		if _action_id == undefined {
			exit;
		}
  
		var _action_result = script_execute_ext(_action_get.func, _action_get.args);

		if _action_result == -1 { exit; }
    
		array_shift(__action_list[$ _action_string]);
    
		if array_length(__action_list[$ _action_string]) == 0 and struct_exists(__action_list, _action_string) {
			struct_remove(__action_list, _action_string);
		}
    
		__action_enable = false;
		__action_id  = "";
  
	}
	
	/// @ignore
	static action_reconnect = function() {
		
		__port = 6510;
		while (__action_server < 0 && __port < 65535) {
			__port++
			__action_server = network_create_server(network_socket_tcp, __port, 1);
		}
		__action_socket = network_create_socket(network_socket_tcp);
		__action_connect = network_connect(__action_socket, "127.0.0.1", __port);
	}
  
	__action = static_get(GMActionQueue);
  
}

GMActionQueue();
