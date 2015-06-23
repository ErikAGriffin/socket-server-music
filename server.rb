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
      # It seems the handshake does know of the cookies.
      # p handshake
      puts "----" * 10
      # Somehow if this method is here, the onmessage
      # outside the onopen does not get called.
      ws.onmessage do |message|
        client = load_json(message)
        p client
      end
    end

    ws.onmessage do |data|
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
