require 'spec_helper'

module PreGitConfig
  def configure(plugins_dir: [])
    subject.configure do |config|
      config.headline_on_success = "Success!"
      config.headline_on_failure = "Failure!"
      config.project_dir = File.dirname(__FILE__)
      config.plugins_dir = plugins_dir
      config.suppress_headline = true
      config.context = "pre-commit"
    end
  end
end

describe CaptainHoog::PreGit do
  include PreGitConfig
  let(:plugins_path) do
    [File.join(File.dirname(__FILE__),
              "..",
              "..",
              "fixtures",
              "plugins",
              "test_plugins",
              "passing")]
  end

  describe "class methods" do

    subject{ CaptainHoog::PreGit }

    it "provides #run" do
      expect(subject).to respond_to(:run)
    end

    it "provides #project_dir getter" do
      expect(subject).to respond_to(:project_dir)
    end

    it "provides #project_dir setter" do
      expect(subject).to respond_to(:project_dir=)
    end

    it "provides #plugins_dir getter" do
      expect(subject).to respond_to(:plugins_dir)
    end

    it "provides #plugins_dir setter" do
      expect(subject).to respond_to(:plugins_dir=)
    end

    it "provides #configure" do
      expect(subject).to respond_to(:configure)
    end

    it "provides #context getter" do 
      expect(subject).to respond_to(:context)
    end

    it "provides #context setter" do 
      expect(subject).to respond_to(:context=)
    end

    describe "#configure" do
      before do
        configure(plugins_dir: plugins_path)
      end

      it "let you define the success headline message" do
        expect(CaptainHoog::PreGit.headline_on_success).to eq "Success!"
      end

      it "let you define the failure headline message" do
        expect(CaptainHoog::PreGit.headline_on_failure).to eq "Failure!"
      end

      it "let you define the project_dir" do
        expect(CaptainHoog::PreGit.project_dir).to eq File.dirname(__FILE__)
      end

      it "let you define the plugins dir" do
        expect(CaptainHoog::PreGit.plugins_dir.last).to eq plugins_path.first
      end

    end

    describe "#run" do

      let(:plugins_list) do
        Class.new do
          def plugins
            %w(foo)
          end

          def has?(plugin)
            plugins.include?(plugin.plugin_name)
          end
        end.new
      end

      it "returns an instance of CaptainHoog::PreGit" do
        expect(CaptainHoog::PreGit.run(plugins_list: plugins_list)).to \
                                            be_instance_of(CaptainHoog::PreGit)
      end

      it 'affects only configured plugins' do
        allow(CaptainHoog).to receive(:treasury_path)
                              .and_return(plugins_path.first)
        configure
        pre_git = CaptainHoog::PreGit.run(plugins_list:plugins_list)
        expect(pre_git.instance_variable_get(:@results).size).to eq 1
      end

    end

  end

  describe "instance methods" do

    it "provides #plugins_eval" do
      expect(subject).to respond_to(:plugins_eval)
    end

  end

end
