require_relative './strategies'

module CaptainHoog
  module Test
    class Sandbox
      attr_reader :configuration,
                  :plugin

      module FakePlugin

        attr_reader :fake_plugin

        def fake(with_plugin: nil, config: {}, eval_plugin: :false)
          setup_env(config)
          self.instance_variable_set(:@raw_plugin, with_plugin)
          self.class.send(:define_method, :available_plugins, fake_code)
          self.plugins_eval if eval_plugin
        end

        module_function

        def fake_code
          proc do
            env = prepare_env
            @fake_plugin = CaptainHoog::Plugin.new(@raw_plugin, env)
            @fake_plugin.eval_plugin
            [@fake_plugin]
          end
        end

        def setup_env(configuration)
          configuration.keys.each do |key|
            self.send("#{key}_configuration", configuration)
          end
        end

        def env_configuration(configuration)
          suppress_headline = configuration[:env].fetch(:suppress_headline, false)
          self.class.suppress_headline = suppress_headline
        end

        def plugin_configuration(configuration)
          self.class.plugins_conf = CaptainHoog::Struct.new(configuration[:plugin])
        end

        def headline_on_success_configuration(configuration)
          headline = configuration[:env].fetch(:headline_on_success)
          self.class.headline_on_success = headline
        end

        def headline_on_failure_configuration(configuration)
          headline = configuration[:env].fetch(:headline_on_failure)
          self.class.headline_on_failure = headline
        end

        def method_missing(meth_name, *args, &block)
          super unless meth_name.include?('_configuration')
        end
      end

      def initialize(raw_plugin, config = {})
        @raw_plugin    = guess_plugin(raw_plugin)
        @configuration = config
        init_plugin
      end

      def run
        @plugin = @pre_git.fake_plugin
        mod = Module.new do
          def result
            eigenplugin = self.send(:eigenplugin)
            git         = eigenplugin.instance_variable_get(:@git)
            {
              test: git.instance_variable_get(:@test_result),
              message: git.instance_variable_get(:@message).call
            }
          end
        end
        @plugin.extend(mod)
      end

      private

      def init_plugin
        @pre_git = CaptainHoog::PreGit.new
        @pre_git.extend(CaptainHoog::Test::Sandbox::FakePlugin)
        @pre_git.fake(with_plugin: @raw_plugin, config: configuration)
        @pre_git.plugins_eval
      end

      def guess_plugin(plugin_code)
        prefix = 'CaptainHoog::Test::PluginStrategies'
        types  = %w(File String NullObject)
        strategies = types.inject([]) do |result, strategy|
          result << Module.const_get("#{prefix}::#{strategy}").new(plugin_code)
          result
        end
        strategies.detect(&:match?).to_s
      end
    end
  end
end
