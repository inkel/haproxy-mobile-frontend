libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

#require 'haproxy/stats'
require 'haproxy/socket'
require 'haproxy/csv_parser'
require 'uri'

module HAProxy

  def self.connect(uri)
    HAProxy::StatsReader.new(uri)
  end

  class StatsReader

    def initialize(uri)
      @@uri = URI.parse(uri)
      
      if @@uri.is_a?(URI::Generic) and File.socket?(@@uri.path)
        @@stats = HAProxy::Socket.new(@@uri.path)
      else
        raise NotImplementedError, "Currently only sockets are implemented"
      end
    end

    def info
      raise NotImplementedError, "Only sockets support commands" unless @@stats.is_a?(HAProxy::Socket)

      returning({}) do |info|
        @@stats.send_cmd "show info" do |line|
          key, value = line.split(': ')
          info[key.downcase.gsub('-', '_').to_sym] = value
        end
      end
    end

    def errors
      raise NotImplementedError, "Only sockets support commands" unless @@stats.is_a?(HAProxy::Socket)

      returning("") do |errors|
        @@stats.send_cmd "show errors" do |line|
          errors << line
        end
      end
    end

    def sessions
      raise NotImplementedError, "Only sockets support commands" unless @@stats.is_a?(HAProxy::Socket)

      returning([]) do |sess|
        @@stats.send_cmd "show sess" do |line|
          sess << line
        end
      end
    end

    def stat
      if @@stats.is_a?(HAProxy::Socket)
        returning([]) do |stats|
          @@stats.send_cmd "show stat" do |line|
            stats << CSVParser.parse(line) unless line.start_with?('#')
          end
        end
      else
        raise NotImplementedError
      end
    end

    def frontends
      all.find_all { |proxy| proxy[:svname] == "FRONTEND" }
    end

    def backends
      all.find_all { |proxy| proxy[:svname] == "BACKEND" }
    end

    def servers
      all.find_all { |proxy| proxy[:svname] != "BACKEND" && proxy[:svname] != "FRONTEND" }
    end

    def all
      if @@stats.is_a?(HAProxy::Socket)
        returning([]) do |proxies|
          @@stats.send_cmd "show stat" do |line|
            unless line.start_with?('#')
              proxies << CSVParser.parse(line)
            end
          end
        end
      else
        raise NotImplementedError
      end
    end

    def proxy_data(type, name)
      all.find { |proxy| proxy[:pxname] == name && (%w{ FRONTEND BACKEND }.include?(type.upcase) || proxy[:pxname] == proxy[:svname]) }
    end

    private

    # Borrowed from Rails 3
    def returning(value)
      yield(value)
      value
    end

  end

end
