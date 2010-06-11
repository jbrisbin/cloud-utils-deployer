require "logger"
require "rubygems"
require "mq"
require "cloud/logger"
require "cloud/deploy"

module Cloud
  module Deploy
    class Monitor

			attr_reader :md5sum, :artifact
      attr_accessor :config, :name

			def initialize(config, name)
				@config = config
				@name = name
				@exchange = @config['default']['exchange']
			end

      def deploy!
				defaults = @config['default']

				# Connect to RabbitMQ...
				host = defaults['host']
				port = defaults['port']
				user = defaults['user']
				pass = defaults['password']
				vhost = defaults['virtual_host']
				exchange = defaults['exchange']
				$log.info(@name) { "Connecting to MQ h: #{host}, p: #{port}, u: #{user}, pw: #{pass}, v: #{vhost}, x: #{exchange}" }

				AMQP.start(:host => host, :port => port, :user => user, :pass => pass, :vhost => vhost) do
	        MQ.queue(@name).bind(@exchange).subscribe(:ack => true) do |headers, body|
						@md5sum = headers.properties[:correlation_id]
						@artifact = body
					end
				end
      end

    end
  end
end