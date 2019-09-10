require 'cl'

module Dpl
  class Cli < Cl
    def self.new(ctx = nil, name = 'dpl')
      ctx ||= Dpl::Ctx::Bash.new
      super
    end

    def run(args)
      super
    rescue UnknownCmd => e
      unknown_provider(e)
    rescue UnknownOption => e
      unknown_option(e)
    rescue Cl::Error, Error => e
      error(e)
    end

    def runner(args)
      args = untaint(args)
      args = with_cmd_opts(args, :provider, :strategy)
      args = with_strategy_default(args, :strategy) # should be a generic dispatch feature in Cl
      super
    end

    # Tainting is being used for automatically obfuscating values for secure
    # options, so we want to untaint all incoming args here.
    def untaint(args)
      args.map(&:dup).each(&:untaint)
    end

    def with_cmd_opts(args, *cmds)
      cmds.inject(args) do |args, cmd|
        with_cmd_opt(args, cmd)
      end
    end

    def with_cmd_opt(args, cmd)
      return args unless arg = args.detect { |arg| arg.start_with?("--#{cmd}") }
      args.delete(arg)
      args = [arg.split('=').last, *args] if arg.include?('=')
      args
    end

    STRATEGIES = {
      'heroku' => 'api',
      'pages'  => 'git'
    }

    def with_strategy_default(args, cmd)
      return args unless default = STRATEGIES[args.first]
      args.insert(1, default) if args[1].nil? || args[1].to_s.start_with?('--')
      args
    end

    def error(e)
      msg = "\e[31m#{e.message}\e[0m"
      msg = [msg, *e.backtrace].join("\n") if backtrace?(e)
      abort msg
    end

    def backtrace?(e)
      e.respond_to?(:backtrace?) && e.backtrace?
    end

    def unknown_provider(e)
      msg = "\e[31m#{e.message}\e[0m"
      msg << "\nDid you mean: #{e.suggestions.join(', ')}?" if e.suggestions.any?
      abort msg
    end

    def unknown_option(e)
      msg = "\e[31m#{e.message}\e[0m"
      msg << "\nDid you mean: #{e.suggestions.join(', ')}?" if e.suggestions.any?
      abort msg
    end

    def suggestions(name)
      return [] unless defined?(DidYouMean)
      DidYouMean::SpellChecker.new(dictionary: providers).correct(name)
    end
  end
end
