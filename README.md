# GMActionQueue
GMActionQueue is a system for GMS2, where you add a function name (or an anonymous function) and it's arguments to a queue with an ID, and can call that Action using the ID at a later time.


### Basic setup
- Create a script in GameMaker
- Copy everything from GMActionQueue.gml
- Paste to script file
- Create an object
- Add to Step event:
```gml
GMActionQueue().action_listen();
```
- Add to Async - Networking event
```gml
GMActionQueue().action_await(async_load);
```
- Add Actions to queue
```gml
GMActionQueue().action("await input", function() { 	
	if mouse_check_button_pressed(mb_left) {
		GMActionQueue().action("clicked", show_debug_message, "Clicked!");
		GMActionQueue().action_call("clicked");
    	return true;
	}
	return false; 
});
```
- Call Action from queue
```gml
GMActionQueue().action_call("await input");
```
> Actions will be removed from the queue when completed.
- Enjoy!
