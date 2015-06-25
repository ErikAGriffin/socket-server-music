require 'em-websocket'
require 'multi_json'

def load_json(string)
  begin
    message = MultiJson.load(string, symbolize_keys: true)
  rescue MultiJson::ParseError => exception
    message = {error: exception.cause, data:exception.data}
  end
  message
end

EM.run do

  puts "Event Machine running..."

  @users = {}

  # hmm.. How to set this up for the heroku server
  EM::WebSocket.run(host: '0.0.0.0', port: 8080) do |ws|

    ws.onopen do |handshake|
      puts "WebSocket has opened!"

      # Why here over outside ?
      ws.onmessage do |message|
        client = load_json(message)
        p client
      end
    end


    # This is not called if it is defined inside onopen.
    ws.onmessage do |data|
      puts "Miraculously I've been called"
      # message = load_json(data)
      puts data
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
