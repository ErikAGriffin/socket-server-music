require 'em-websocket'
require 'multi_json'

EM.run do

  def load_json(string)
    begin
      message = MultiJson.load(string, symbolize_keys: true)
    rescue MultiJson::ParseError => exception
      message = {error: exception.cause, data:exception.data}
    end
    message
  end

  def add_socket(message,socket)
    host = message[:host]
    # I am not particularly happy with this setup.
    return if @servers.include?(socket) || (@clients[host] && @clients[host].include?(socket))
    puts "----*" * 6
    puts "I'm adding a socket #{message[:server] ? 'server' : 'client'}!"
    if message[:server]
      @servers[host] = socket
      @clients[host] = []
    elsif !message[:server]
      @clients[host] << socket
    end
  end

  puts "Event Machine running..."

  @servers = {}
  @clients = {}
  # FINALLY an idea for different architecture.
  # May have a single @sockets hash
  # {HOSTNAME: {server:<serversocket>,clientID:<socket>, clientID:<socket>}

#   Hash.new {|value, key| value[key.to_s] if Symbol === key }

  # hmm.. How to set this up for the heroku server
  EM::WebSocket.run(host: '0.0.0.0', port: 8080) do |ws|

    ws.onopen do |handshake|
      puts "WebSocket has opened!"
    end

    # This is not called if it is defined inside onopen.
    ws.onmessage do |data|
      message = load_json(data)
      p message
      # Need server side protection, connecting to server that does not exist.
      # Clients that leave can have their sockets deleted from array and reopened
      # (What happens if you try to acces a closed socket in the Array?)
      # However servers that close should not imediately be "deleted",
      # so a client may push a song to a server whos browser accidentally closed
      # and will reopen.
      add_socket(message,ws)
      puts @servers
      puts @clients
    end

    ws.onclose do
      puts "Connection closed."
      # @sockets.delete(ws)
    end

    ws.onerror do |e|
      puts "Error: #{e.message}"
    end

  end
end
