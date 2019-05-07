require 'chef'
require 'chef/cookbook_uploader'
require 'chef/cookbook_site_streaming_uploader'
require 'chef/knife/cookbook_metadata'

module Dpl
  module Providers
    class ChefSupermarket < Provider
      summary 'Chef Supermarket deployment provider'

      description <<~str
        tbd
      str

      opt '--user_id ID',            'Chef Supermarket user name', required: true
      opt '--client_key KEY',        'Client API key file name', required: true
      opt '--cookbook_name NAME',    'Cookbook name', default: :repo_name
      opt '--cookbook_category CAT', 'Cookbook category in Supermarket', required: true, see: 'https://docs.getchef.com/knife_cookbook_site.html#id12'

      URL = "https://supermarket.chef.io/api/v1/cookbooks"

      MSGS = {
        validate:       'Validating cookbook %{name}',
        upload:         'Uploading cookbook %{name} to %{url}',
        missing_key:    '%{client_key} does not exist',
        unknown_error:  'Unknown error while sharing cookbook: %s',
        version_exists: 'The same version of this cookbook already exists on the Opscode Cookbook Site.'
      }

      def setup
        Chef::Config[:client_key] = client_key
      end

      def check_auth
        error :missing_key unless File.exist?(client_key)
      end

      def deploy
        info :validate
        uploader.validate_cookbooks
        info :upload
        upload
      end

      def finish
        FileUtils.rm_rf dir
      end

      private

        def upload
          res = Chef::CookbookSiteStreamingUploader.post(URL, user_id, client_key, params)
          handle_error(res.body) if res.code.to_i != 201
        end

        def params
          { cookbook: json(category: cookbook_category), tarball:  tarball }
        end

        def tarball
          shell "tar -czf #{name}.tgz #{name}", chdir: dir
          File.open("#{dir}/#{name}.tgz")
        end

        def name
          cookbook_name || app
        end

        def cookbook
          @cookbook ||= loader[name]
        end

        def uploader
          Chef::CookbookUploader.new(cookbook)
        end

        def loader
          Chef::CookbookLoader.new('..')
        end

        def dir
          @dir ||= Chef::CookbookSiteStreamingUploader.create_build_dir(cookbook)
        end

        def url
          URL
        end

        def handle_error(res)
          res = JSON.parse(res)
          unknown_error(res) unless res['error_messages']
          version_exists if res['error_messages'][0].include?('Version already exists')
          error "#{res['error_messages'][0]}"
        end

        def unknown_error(msg)
          error :unknown_error, msg
        end

        def version_exists
          error :version_exists
        end

        def json(obj)
          JSON.dump(obj)
        end
    end
  end
end
