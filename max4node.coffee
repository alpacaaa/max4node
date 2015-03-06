

# Copyright (c) 2015, Marco Sampellegrini <babbonatale@alpacaaa.net>
#
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
# is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
# INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
# FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
# ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.



osc = require 'osc-min'
udp = require 'dgram'

{ EventEmitter } = require 'events'
Promise = require 'bluebird'


class Max4Node

  constructor: ->
    @read  = null # input socket
    @write = null # output socket
    @ports = {}
    @emitters = {}

  bind: (ports = {}) ->
    ports.send ||= 9000
    ports.receive ||= 9001
    @ports = ports

    @read  = @create_input_socket ports.receive
    @write = udp.createSocket 'udp4'


  create_input_socket: (port) ->
    socket = udp.createSocket 'udp4'
    socket.bind port

    socket.on 'message', (msg, rinfo) =>
      obj = @parse_message msg

      if obj.is_get_reply or obj.is_observer_reply
        try
          @emitters[obj.callback].emit 'value', obj.value
        catch err

      if obj.is_get_reply
        delete @emitters[obj.callback]

    socket


  parse_message: (msg) ->
    obj  = osc.fromBuffer msg
    args = obj.args.map (item) -> item.value

    switch obj.address
      when '/_get_reply'
        obj.is_get_reply = true
        obj.callback = args[0]
        obj.value = args[1]

      when '/_observer_reply'
        obj.is_observer_reply = true
        obj.callback = args[0]
        obj.value = args[2]

    obj


  send_message: (address, args) ->
    buf = osc.toBuffer
      address: '/' + address,
      args: args

    @write.send buf, 0, buf.length, @ports.send, 'localhost'


  observer_emitter: (msg, action = 'observe') ->
    emitter  = new EventEmitter()
    callback = @callbackHash()
    @emitters[callback] = emitter

    args = [msg.path, msg.property, callback]
    @send_message action, args
    emitter

  callbackHash: ->
    (new Date()).getTime().toString() + Math.random().toString()


  get: (msg) ->
    @observer_emitter msg, 'get'

  set: (msg) ->
    args = [msg.path, msg.property, msg.value]
    @send_message 'set', args

  call: (msg) ->
    args = [msg.path, msg.method]
    @send_message 'call', args

  observe: (msg) ->
    @observer_emitter msg, 'observe'

  count: (msg) ->
    @observer_emitter msg, 'count'

  promise: ->
    return @promisedFn if @promisedFn
    @promisedFn =
      get: promiseMessage.bind(@, 'get')
      count: promiseMessage.bind(@, 'count')



promiseMessage = (method, msg) ->
  new Promise (resolve, reject) =>
    emitter = @[method] msg
    emitter.on 'value', resolve

module.exports = Max4Node
