

var isReady = false,
	actions = {},
	apis = {};


function get(action) {
	if (!isReady) return false;

	var json = Array.prototype.slice.call(arguments);
	json = json.slice(1);

	action = action.slice(1);
	var ret = actions[action](json);
}


function on() {
	isReady = true;
}



actions['get'] = function(obj) {
	var path = obj[0],
		property = obj[1],
		callback = obj[2];

	var api = getApi(path);
	outlet(0, '/_get_reply', callback, api.get(property));
};



actions['set'] = function(obj) {
	var path = obj[0],
		property = obj[1],
		value = obj[2];

	var api = getApi(path);
	api.set(property, value);
};


actions['call'] = function(obj) {
	var path = obj[0],
		method = obj[1];

	var api = getApi(path);
	api.call(method);
};


actions['observe'] = function(obj) {
	var path = obj[0],
		property = obj[1],
		callback = obj[2];

	var handler = handleCallbacks(callback);

	var api = new LiveAPI(handler, path);
	api.property = property;
};


actions['count'] = function(obj) {
	var path = obj[0],
		property = obj[1],
		callback = obj[2];

	var api = getApi(path);
	outlet(0, '/_get_reply', callback, api.getcount(property));
};


function getApi(path) {
	if (apis[path])
		return apis[path];

	apis[path] = new LiveAPI(path);
	return apis[path];
}


function handleCallbacks(callback) {
	return function(value) {
		outlet(0, '/_observer_reply', callback, value);
	}
}


function log() {
  for(var i=0,len=arguments.length; i<len; i++) {
    var message = arguments[i];
    if(message && message.toString) {
      var s = message.toString();
      if(s.indexOf("[object ") >= 0) {
        s = JSON.stringify(message);
      }
      post(s);
    }
    else if(message === null) {
      post("<null>");
    }
    else {
      post(message);
    }
  }
  post("\n");
}
