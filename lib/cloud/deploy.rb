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