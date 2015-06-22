require 'em-websocket'

EM.run do

  puts "I'm running too!"

  EM::WebSocket.run(host: '0.0.0.0', port: 8080) do |ws|

    puts "Event Machine running..."

    ws.onopen do |handshake|
      puts "WebSocket has opened!\n #{{
        :path => handshake.path,
        :query => handshake.query,
        :origin => handshake.origin,
      }}"

      ws.send "No Luke. I am your father."
    end

    ws.onclose do
      puts "Connection closed."
    end

    ws.onmessage do |message|
      puts "Receiving transmission.."
      puts message
      ws.send "Pong: #{message}"
    end

    ws.onerror do |e|
      puts "Error: #{e.message}"
    end

  end
end
