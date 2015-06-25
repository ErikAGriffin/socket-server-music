require 'em-websocket'

EventMachine.run do

  puts "EventMachine running.."


  EventMachine::WebSocket.start(host: "0.0.0.0", port:8080) do |ws|


    if !@channel
      @channel = EM::Channel.new
      puts 'Whoops, channel created!'
    end


    ws.onopen do

      sid = @channel.subscribe do |msg|
        ws.send msg
      end

      ws.onmessage do |msg|
        @channel.push "[#{sid}]hmm.. #{msg}"
      end


      ws.onclose do
        puts "Unsubscribing #{sid}"
        @channel.unsubscribe sid
      end

    end

  end




end
