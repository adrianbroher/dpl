module Support
  module Fixtures
    DIR = 'spec2/fixtures/'

    class << self
      def [](key)
        fixtures[key] || raise("No fixture found for #{key}")
      end

      def fixtures
        @fixtures ||= load
      end

      def load
        Dir["#{DIR}**/*.json"].map do |path|
          [path.sub(DIR, '').sub('.json', ''), ::File.read(path)]
        end.to_h
      end
    end

    def fixture(namespace, key)
      Fixtures["#{namespace}/#{key}"]
    end
  end
end
