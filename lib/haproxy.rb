#! /usr/bin/ruby

class HAProxy
  TYPES = [ :frontend, :backend, :server ]
  
  attr_reader :frontends, :backends, :servers

  def initialize(path=nil)
    @frontends = {}
    @backends = {}
    @servers = {}
    parse_csv unless path.nil?
  end

  def parse(csv)
    columns = []

    csv.each do |line|
      line.strip!
      unless line.start_with? "#"
        data = line.split(',')
        pxname = data.shift

        stats = { :pxname => pxname }

        data.each_with_index do |value, i|
          stats[columns[i + 1]] = value
        end

        case stats[:svname]
          when "FRONTEND" then @frontends
          when "BACKEND" then @backends
          else @servers
        end[pxname] = stats
      else
        line.gsub(/[^a-z,]/, '').split(',').each do |name|
          columns << name.to_sym unless !name
        end
      end
    end
  end

  def sessions(type, pxname)
    data = data_for(type, pxname)

    {
      :current => data[:scur],
      :max => data[:smax],
      :total => data[:stot],
      :rate => {
        :last_second => data[:rate],
        :limit => data[:ratelim],
        :max => data[:ratemax]
      }
    }
  end

  def data_for(type, pxname)
    data = case type
    when :frontend then @frontends
    when :backend then @backends
    when :server then @servers
    else raise ArgumentException "Invalid type"
    end[pxname]

    raise ArgumentException unless !data.nil?

    data
  end
end

if __FILE__ == $0
  h = HAProxy.new

  h.parse(File.open("../haproxy.csv"))

  # puts <<EOF
  # Frontends:	#{h.frontends.size}
  # Backends:	#{h.backends.size}
  # Servers:	#{h.servers.size}
  # EOF

  h.backends.each do |pxname, data|
    puts pxname, data.class
  end

  # puts h.servers['destentor'].inspect
  # puts
  # puts h.sessions(:server, "destentor").inspect
end
