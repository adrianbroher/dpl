require 'fog/rackspace'

module Dpl
  module Providers
    class CloudFiles < Provider
      summary 'CloudFiles deployment provider'

      description <<~str
        tbd
      str

      opt '--username USER',  'Rackspace username', required: true
      opt '--api_key KEY',    'Rackspace API key', required: true
      opt '--region REGION',  'Cloudfiles region', required: true, enum: %w(ord dfw syd iad hkg)
      opt '--container NAME', 'Name of the container that files will be uploaded to', required: true
      opt '--glob GLOB',      'Paths to upload', default: '**/*'
      opt '--dot_match',      'Upload hidden files starting a dot'

      MSGS = {
        missing_container: 'The specified container does not exist.'
      }

      def deploy
        paths.each do |path|
          container.files.create(key: path, body: File.open(path))
        end
      end

      def paths
        paths = Dir.glob(*glob)
        paths.reject { |path| File.directory?(path) }
      end

      def glob
        glob = [super]
        glob << File::FNM_DOTMATCH if dot_match?
        glob
      end

      def container
        @container ||= api.directories.get(super) || error(:missing_container)
      end

      def api
        @api ||= Fog::Storage.new(
          provider: 'Rackspace',
          rackspace_username: username,
          rackspace_api_key: api_key,
          rackspace_region: region
        )
      end
    end
  end
end
