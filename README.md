
# Ableton Live API for Node.js (through Max for Live)

This module exposes the [Live Object Model](https://cycling74.com/docs/max6/dynamic/c74_docs.html#live_object_model)
so that it can be consumed directly from Node.js. It works by communicating with a Max for Live device (included in the repo)
through udp sockets.


### Requirements

* Ableton Live 9
* Max for Live (tested with version 7, might work with 6)

By default, the module binds on ports __9000__ and __9001__, so they need to be free.


### Install

`npm install max4node`


### Setup

The Max for Live device is located in `max_device/max4node.amxd`.  
Drop the device in a MIDI track (doesn't matter which one).


### Usage

```javascript
var Max4Node = require('max4node');

var max = new Max4Node();
max.bind();
```

##### Get values

Get Master Track volume.

```javascript
max.get({
  path: 'live_set master_track mixer_device volume',
  property: 'value'
})
.once('value', function(val) {
  console.log('Master track volume: ' + val);
});
```

##### Set values

Arm the first track.

```javascript
max.set({
  path: 'live_set tracks 0',
  property: 'arm',
  value: true
});
```

##### Call functions

Play a clip.

```javascript
max.call({
  path: 'live_set tracks 0 clip_slots 3 clip',
  method: 'fire'
});
```

##### Observe a value

Fire the callback with the updated position of the clip (if it's playing).

```javascript
max.observe({
  path: 'live_set 0 clip_slots 3 clip',
  property: 'playing_position'
})
.on('value', function(val) {
  console.log('Playing position: ' + val);
});
```

##### Count

Number of clips in the track.

```javascript
max.count({
  path: 'live_set tracks 0',
  property: 'clip_slots'
})
.once('value', function(count) {
  console.log(count + ' clips');
});
```

##### Promises

Promise based versions of `get` and `count` are available through `max.promise()`.

```javascript
max.promise().get({
  path: 'live_set master_track mixer_device volume',
  property: 'value'
})
.then(function(val) {
  console.log('Master track volume: ' + val);
});

max.promise().count({
  path: 'live_set tracks 0',
  property: 'clip_slots'
})
.then(function(count) {
  console.log(count + ' clips');
});
```

### Testing

Testing is done with fake sockets, so you don't need to open Ableton and Max.

`npm test`


### Big ups

I would have never been able to come up with the Max device without looking at the code of [Fingz](http://www.atmosphery.org/#!/labs/fingz), an awesome project that you should definitely check out.  
I learned a lot about Max from it, debugging in Max is as painful as listening to Justin Bieber, but it's the only
way we have to access the Ableton API in a reliable manner (control surfaces programming is a joke, and
not officially supported).


### License


> Copyright (c) 2015, Marco Sampellegrini <babbonatale@alpacaaa.net>


> Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

> THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
