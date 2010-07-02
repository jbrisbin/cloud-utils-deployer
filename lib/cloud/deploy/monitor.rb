#
# Copyright (c) 2010 by J. Brisbin <jon@jbrisbin.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing
# permissions and limitations under the License.
#
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
	        MQ.queue(@name, :durable => true, :auto_delete => false).bind(@exchange, :type => "topic", :durable => true).subscribe(:ack => true) do |headers, body|
						@md5sum = headers.properties[:correlation_id]
						$log.debug('monitor') { "MD5 sum: #{@md5sum}" }
						@artifact = body
					end
				end
      end

    end
  end
end