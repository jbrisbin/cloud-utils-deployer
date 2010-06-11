require "cloud/logger"
require "cloud/deploy"
require "net/http"
require "uri"
require "fileutils"
include Cloud::Deploy

module Cloud
  module Deploy

    class Artifact

      attr_reader :uri
      attr_accessor :name, :local_paths, :unzip, :force, :use_etags

      def initialize
        @use_etags = true
      end

      def uri=(remote_uri)
        @uri = URI.parse(remote_uri)
        @http = Net::HTTP.new(@uri.host, @uri.port)
      end

      def outdated?
        download
      end

      def deploy!
        load_md5sums do |md5sums|
          hash = md5sums[@name]
          if !@force and !hash.nil? and hash == @hash
            $log.info(@name) { "MD5 sums match. No need to deploy." }
          else
            @local_paths.each do |path|
              FileUtils.mkdir_p(path)
              if @unzip
                $log.info(@name) { "Unzipping #{@name} to #{path}" }
                if @uri.request_uri[-6..-1] == "tar.gz"
                  `tar -zxf #{@temp_file} -C #{path}`
                else
                  `unzip -d #{path} #{@temp_file}`
                end
              else
                $log.info(@name) { "Copying #{@name} to #{path}" }
                FileUtils.cp(@temp_file, path)
              end
            end
            md5sums[@name] = @hash
            save_md5sums(md5sums)
          end
          # Clean up temp file
          if !@temp_file.nil?
            FileUtils.rm(@temp_file)
          end
          # We did a deployment
          return true
        end
        # Default return
        return false
      end

      private
      def download
        outdated = false

        request = Net::HTTP::Get.new(@uri.request_uri)
        load_etags do |etags|
          etag = etags[@name]
          if !@force and !etag.nil?
            request.initialize_http_header({
                'If-None-Match' => etag
            })
          end

          response = @http.request(request)
          case response
            when Net::HTTPSuccess
              # Continue to download file...
              $log.info(@name) { "Downloading: #{@uri.to_s}..." }
              bytes = response.body
              require "md5"
              @hash = MD5.new.update(bytes).hexdigest
              # Write to temp file, ready to deploy
              @temp_file = "/tmp/#{@name}"
              File.open(@temp_file, "w") { |f| f.write(bytes) }
              # Update ETags
              etags[@name] = response['etag']

              outdated = true
            when Net::HTTPNotModified
              # No need to download it again
              $log.info(@name) { "ETag matched, not downloading: #{@uri.to_s}" }
            else
              $log.fatal(@name) { "Error HTTP status code received: #{response['code']}" }
          end

          if @use_etags
            save_etags(etags)
          end
        end

        return outdated
      end

    end

  end
end