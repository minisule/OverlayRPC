#!/usr/bin/ruby
require 'optparse'
require 'socket'
require 'ipaddr'
include Socket::Constants

options = {:delay => nil, :length => nil, :time => nil}

parser = OptionParser.new do |opts|
	opts.banner = "Usage: sendLSP.rb [options]"
	opts.on('-d', '--delay delay', 'Specifies how often to send packets (seconds)') do |delay|
		options[:delay] = delay.to_i
	end
	
	opts.on('-l', '--length length', 'Specifies maximum packet length (bytes)') do |length|
		options[:length] = length.to_i
	end
	
	opts.on('-t', '--time time', 'Specifies the delay until first LSP is sent') do |time|
		options[:time] = time.to_i
	end

	opts.on('-h', '--help', 'Display Help') do
		puts opts
		exit
	end
end
parser.parse!

if options[:length] == nil 
	puts("Packet length unspecified. Defaulting to 40 bytes and
	10 seconds");
	options[:length] = 50
end
if options[:time] == nil
	puts("Delay time unspecified defaulting to 10 seconds")
	options[:delay] = 10
end
if options[:time] == nil 
	puts("Initial Link State Packet delay not specified, defaulting to 15 seconds")
	 options[:time] = 5
end

hostname = `hostname`
hostname = hostname.chomp!

ip_addresses = `ifconfig | grep 'inet addr' | awk -F : '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1`

neighbors = {}
sequence = {}
interfaces = ip_addresses.split("\n")[0]

def packetize(str, maxlen)
	arr = []
	n = ((str.length.to_f / maxlen)).ceil
	0.step(n-1,1) { |i|
		arr[i] = str[i*maxlen, (i+1)*maxlen]
	}
	return arr
end
maxlen = options[:length]
initial_sleep = options[:time]
delay = options[:delay]

sleep(initial_sleep)
while true 
	configFile = File.open(ARGV[0], 'r')
	while (line = configFile.gets())
		arr = line.split(",")
		if (interfaces.include?("#{arr[0]}"))
			neighbors["#{arr[1]}"] = arr[2].to_i
			sequence["#{arr[1]}"] = arr[3].to_i
		else
		end
	end
	configFile.close
	interfaces.each { |key|
		str << "#{key.chomp!}:0 "
	}
	neighbors.each { |key, value|
		str << "#{key}:#{value} "
	}

	str = str.chop
	interfaces.each { |key1|
		key = key.chomp!
		neighbors.each { |key2, value|
			lsp_string = "LSP #{key1} #{hostname} #{sequence[key2]} \"#{str}\"\\n"
			realmsg = packetize(lsp_string, maxlen)
			socket = Socket.new(AF_INET, SOCK_STREAM, 0)
			sockaddr = Socket.sockaddr_in(6666, "#{key}")
			socket.connect(sockaddr)
			realmsg.each { |x|
				socket.write(x)
			}
			socket.close
		}
	}
	sleep(delay)
end
 
		 
