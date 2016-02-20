require 'em-websocket'
require 'multi_json'

EM.run do

    # Servers that close should not imediately be "deleted",
    # so a client may push a song to a server whos browser accidentally closed
    # and will reopen.

  def load_json(string)
    begin
      message = MultiJson.load(string, symbolize_keys: true)
    rescue MultiJson::ParseError => exception
      message = {error: exception.cause, data:exception.data}
    end
    message
  end

  # This is stupid that I must call this function on EVERY message send
  # Is there not a way to add a socket to the appropriate hash location
  # using only the handshake, AKA only when it is opened?

  def add_socket(message,socket)
    # Must do server side error handling if a phony hostname gets sent in here.
    host = message[:host]
    if !@sockets[host]
      @sockets[host] = {}
    end
    if message[:server] && !@sockets[host][:server]
      @sockets[host][:server] = socket
    elsif !message[:server] && !@sockets[host][message[:clientID]]
      @sockets[host][message[:clientID]] = socket
    end
  end

  puts "Event Machine running..."

  @sockets = {}

  # Keeps connections open for heroku

  EventMachine::PeriodicTimer.new(15) do
    if @sockets.empty?
      puts "Going to sleep soon..."
    else
      @sockets.each_value do |host|
        host.each_value {|s| s.pong(body = '')}
      end
    end
  end

  EM::WebSocket.run(host: '0.0.0.0', port: ENV['PORT'] || 8080) do |ws|

    ws.onopen do |handshake|
      puts "WebSocket has opened!"
    end

    ws.onmessage do |data|
      message = load_json(data)
      host = message[:host]
      puts "----- Incoming #{message[:server] ? 'Server' : 'Client'} Transmission -----"
      puts message
      add_socket(message,ws)
      if !message[:server]
        @sockets[host][:server].send MultiJson.dump(message) if @sockets[host][:server]
      elsif message[:server]
        @sockets[host].each_pair do |key,socket|
          socket.send data if key != :server
        end
      end
    end

    # Too many ends.

    ws.onclose do
      puts "Connection closed."
      catch :socket_removed do
        @sockets.each_pair do |hostkey,hash|
          hash.each_pair do |key,socket|
            if socket == ws
              puts "Socket removed: #{hostkey}: #{key}"
              hash.delete(key)
              if hash.empty?
                puts "----- DELETED SOCKET HASH -----"
                @sockets.delete(hostkey)
              end
              throw :socket_removed
            end
          end
        end
      end
    end

    ws.onerror do |e|
      puts "Error: #{e.message}"
    end

  end
end
