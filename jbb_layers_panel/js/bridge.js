
	
	
/////////////// JS-RUBY BRIDGE /////////////

	
var callback_busy = false;
var callback_queue = [];
function skpCallback(callback) {
	//console.log('skpCallback', callback);
	callback_queue.push(callback);
	skpPumpCallback();
}

function skpPumpCallback() {
	//console.log('> skpPumpCallback');
	if (!callback_busy && callback_queue.length > 0) {
		var callback = callback_queue.shift();
		skpPushCallback(callback);
	}
}

function skpPushCallback(callback) {
	//console.log('>> skpPushCallback', callback);
	callback_busy = true;
	window.location = callback;
}

// Called from Ruby.
function skpCallbackReceived() {
	//console.log('> skpCallbackReceived');
	callback_busy = false;
	skpPumpCallback();
}