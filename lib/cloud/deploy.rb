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
require "cloud/logger"

module Cloud
	module Deploy
		
		ETAG_FILE = '/var/lib/cloud/deploy.etags'
		MD5SUM_FILE = '/var/lib/cloud/deploy.md5sums'
		
		def load_etags
      etags = {}
      if @use_etags
        begin
          File.open(ETAG_FILE, 'r') do |f|
            etags = Marshal.load(f)
          end
        rescue => err
          $log.fatal('etags') { err }
        end
      end
      yield etags
    end

    def save_etags(etags)
      File.open(ETAG_FILE, 'w') do |f|
        f.write(Marshal.dump(etags))
      end
    end

    def load_md5sums
      md5sums = {}
      begin
        File.open(MD5SUM_FILE, 'r') do |f|
          md5sums = Marshal.load(f)
        end
      rescue => err
        $log.fatal('md5sums') { err }
      end
      yield md5sums
    end

    def save_md5sums(md5sums)
      File.open(MD5SUM_FILE, 'w') do |f|
        f.write(Marshal.dump(md5sums))
      end
    end
    
	end
end