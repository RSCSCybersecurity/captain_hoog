module CaptainHoog
  module Cli
    autoload :Git, 'captain_hoog/cli/git'
    autoload :Pull, 'captain_hoog/cli/pull'
    class Hoog < Thor
      include Thor::Actions
      include Git
      include Pull

      def self.exit_on_failure?
        true
      end

      def self.source_root
        File.join(File.dirname(__FILE__), "templates")
      end

      def self.hookin_repo
        "git@github.com:RSCSCybersecurity/hookins.git"
      end

      class_option :type, type: :string, default: 'pre-commit'
      class_option :project_dir, type: :string, default: Dir.getwd
      class_option :plugins_dir, type: :string, default: Dir.getwd

      map %w[--version -v] => :__print_version

      option :skip_hookins, type: :boolean, default: false 
      option :silence, type: :boolean, default: false
      desc "install","Installs the hook into your Git repository"
      def install(*_args)
        check_if_git_present
        check_if_option_present("plugins_dir")
        init_environment(home_dir: Dir.home,
                        silence: options[:silence],
                        skip_hookins: options[:skip_hookins])
        install_hook({ as: options[:type],
                       context: {
                         root_dir: Dir.getwd,
                         plugins_dir: options[:plugins_dir],
                         project_dir: options[:project_dir]
                       }
                    })
        puts "Installed hook as #{options[:type]} hook".green
      end

      desc "remove", "Removes a hook from your Git repository"
      def remove(*_args)
        check_if_git_present
        remove_hook(as: options[:type])
        puts "The #{options[:type]} hook is removed.".green
      end

      option :from, type: :string, required: true
      option :to, type: :string, required: true
      desc "move", "Moves a hook from type to another"
      def move(*_args)
        check_if_git_present
        if options[:from] == options[:to]
          puts "--from and --to arguments are the same".red
          raise Thor::Error
        else
          move_hook(options)
          puts "The #{options[:from]} hook is moved to #{options[:to]} hook.".green
        end
      end

      desc "version, -v", "Prints out the version"
      def __print_version
        puts CaptainHoog::VERSION
      end

      option :home, type: :string
      desc "init", "Initializes the Captain Hoog Environment"
      def init
        home_dir = options[:home]
        init_environment(home_dir: home_dir)
      end

      desc 'treasury', 'Manages the treasury and holds the hoogs'
      subcommand 'treasury', Treasury

      private

      def install_hook(config)
        opts        = config[:context]
        opts[:type] = config[:as]
        copy_config_file(opts)
        template("install.erb",File.join(hooks_dir, config[:as]), opts)
        FileUtils.chmod(0755,File.join(hooks_dir, config[:as]))
      end

      def remove_hook(config)
        FileUtils.rm_rf(File.join(hooks_dir, config[:as]))
      end

      def move_hook(config)
        from = File.join(hooks_dir, config[:from])
        to   = File.join(hooks_dir, config[:to])
        FileUtils.mv(from, to)
      end

      def check_if_option_present(type)
        unless options.has_key?(type)
          puts "No value provided for required options '--#{type}'".red
          raise Thor::Error
        end
      end

      def copy_config_file(opts={})
        template('hoogfile.erb', git_dir.join('hoogfile.yml'), opts)
      end

      def init_environment(home_dir: Dir.home, 
                           silence: false,
                           skip_hookins: false)
        environment_dir = File.join(home_dir, '.hoog')
        treasury_dir = File.join(environment_dir, 'treasury')
        if File.exist?(treasury_dir)
          puts "Treasury already exists. Skipping.".yellow unless silence
        else
          puts "Initializing treasury".green unless silence
          FileUtils.mkdir_p(treasury_dir)
        end
        pull_and_clone(self.class.hookin_repo, treasury_dir) unless skip_hookins
      end
    end
  end
end
