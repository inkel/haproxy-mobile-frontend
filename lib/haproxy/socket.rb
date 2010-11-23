require 'socket'

module HAProxy
  class Socket

    def initialize(path)
      @path = path
    end

    def send_cmd(cmd, &block)
      socket = UNIXSocket.new(@path)
      socket.puts(cmd)
      socket.each do |line|
        yield(line.strip)
      end
    end

  end
end
