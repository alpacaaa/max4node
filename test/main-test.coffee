
assert = require 'assert'


osc = require 'osc-min'
udp = require 'dgram'
Max4Node = require '../max4node'


createTestSocket = (port) ->
  socket = udp.createSocket "udp4"
  socket.bind port
  socket


checkArrays = (arr1, arr2) ->
  assert.equal arr1.toString(), arr2.toString()

normalizeArgs = (obj) ->
  obj.args.map (item) -> item.value







describe 'Max4Node API', ->

  sendSocket = null
  receiveSocket = null

  sendPort = 12000
  receivePort = 12001

  max = null


  value = 'should be equal'
  path  = 'live_set master_track mixer_device volume'


  before ->
    sendSocket = udp.createSocket 'udp4'
    receiveSocket = createTestSocket sendPort


    max = new Max4Node()
    max.bind
      send: sendPort
      receive: receivePort


  afterEach ->
    receiveSocket.removeAllListeners 'message'


  describe 'Setup', ->

    it 'is configured correctly', ->
      assert.equal sendPort, max.ports.send
      assert.equal receivePort, max.read.address().port


  describe 'Communication with Ableton', ->

    it 'should get values', (done) ->
      getTest 'get', done



    it 'should set values', (done) ->

      receiveSocket.on 'message', (msg) ->
        obj  = osc.fromBuffer msg
        args = normalizeArgs obj

        assert.equal '/set', obj.address
        checkArrays [path, 'value', value], args
        done()

      max.set
        path: path
        property: 'value'
        value: value



    it 'should fire actions', (done) ->

      receiveSocket.on 'message', (msg) ->
        obj  = osc.fromBuffer msg
        args = normalizeArgs obj

        assert.equal '/call', obj.address
        checkArrays [path, value], args
        done()


      max.call
        path: path
        method: value



    it 'should observe properties', (done) ->

      expected = [0.25, 0.5, 0.85]
      good = 0

      receiveSocket.on 'message', (msg) ->
        obj  = osc.fromBuffer msg
        args = normalizeArgs obj

        assert.equal '/observe', obj.address
        assert.equal 3, args.length
        assert.ok args[2]

        expected.forEach (item, index) ->
          setTimeout (->
            buf = osc.toBuffer
              address: '/_observer_reply',
              args: [args[2], 'for some reason, it returns the property', item]

            sendSocket.send buf, 0, buf.length, receivePort, 'localhost'
          ), index * 200


      max.observe
        path: path
        property: value
      .on 'value', (check) ->
        ret = expected.filter (item) ->
          item.toFixed(2) == parseFloat(check).toFixed(2)

        unless ret.length
          assert.fail check, expected, 'Wrong value received'

        done() if ++good == expected.length



    it 'should count stuff', (done) ->
      getTest 'count', done




  getTest = (method, done) ->

    receiveSocket.on 'message', (msg) ->
      obj  = osc.fromBuffer msg
      args = normalizeArgs obj

      assert.equal '/' + method, obj.address
      checkArrays [path, 'value'], args.slice(0, 2)
      assert.ok args[2]

      buf = osc.toBuffer
        address: '/_get_reply',
        args: [args[2], value]

      sendSocket.send buf, 0, buf.length, receivePort, 'localhost'


    max[method]
      path: path
      property: 'value'
    .once 'value', (check) ->
      assert.equal value, check
      done()
