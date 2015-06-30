require 'em-websocket'
require 'multi_json'

EM.run do

    # Servers that close should not imediately be "deleted",
    # so a client may push a song to a server whos browser accidentally closed
    # and will reopen.

    # A better question now is how to handle servers that DO expire,
    # cleaning up the unused hashes and whatnot.


  def load_json(string)
    begin
      message = MultiJson.load(string, symbolize_keys: true)
    rescue MultiJson::ParseError => exception
      message = {error: exception.cause, data:exception.data}
    end
    message
  end

  def add_socket(message,socket)

    # Must do server side error handling if a fony hostname gets sent in here.

    # This is stupid that I must call this function on EVERY message send
    # Is there not a way to add a socket to the appropriate hash location
    # using only the handshake, AKA only when it is opened?

    host = message[:host]

    if message[:server] && !@sockets[host]
      @sockets[host] = {server: socket}
    elsif !@sockets[host][:server]
      @sockets[host][:server] = socket
    elsif !message[:server]
      client_id = message[:clientID]
      !@sockets[host][client_id] ? @sockets[host][client_id] = socket : nil
    end

  end

  puts "Event Machine running..."

  @sockets = {}

#   Hash.new {|value, key| value[key.to_s] if Symbol === key }

  # hmm.. How to set this up for the heroku server
  EM::WebSocket.run(host: '0.0.0.0', port: 8080) do |ws|

    ws.onopen do |handshake|
      puts "WebSocket has opened!"
    end

    ws.onmessage do |data|
      message = load_json(data)
      host = message[:host]
      puts "----- #{message}"
      add_socket(message,ws)
      p @sockets[host].keys
      if !message[:server]
        @sockets[host][:server].send data
      elsif message[:server]
        @sockets[host].each_pair do |key,socket|
          socket.send data if key != :server
        end
      end
    end

    ws.onclose do
      puts "Connection closed."
      catch :socket_removed do
        @sockets.each_value do |hash|
          puts "Iterating Through hash!"
          hash.each_pair do |key,socket|
            puts key
            if socket == ws
              hash.delete(key)
              throw :socket_removed
            end
          end
        end
      end
      @sockets.each_key do |key|
        puts "#{key}:"
        p @sockets[key].keys
      end
    end

    ws.onerror do |e|
      puts "Error: #{e.message}"
    end

  end
end
