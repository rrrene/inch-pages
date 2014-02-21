require 'inch'

module Inch
  module Pages
    # this is heavily borrowed from Bundler's Gemhelper
    class RakeTasks
      include Rake::DSL if defined? Rake::DSL

      class << self
        # set when install'd.
        attr_accessor :instance

        def install(opts = {})
          new(opts[:dir]).install
        end
      end

      attr_reader :base

      def initialize(base = nil)
        @base = (base ||= Dir.pwd)
      end

      def install
        desc "Build the site."
        task 'build' do
          build_site
        end

        desc "Build and push to GitHub"
        task 'release' do
          release_site
        end

        RakeTasks.instance = self
      end

      def build_site
        sh("jekyll build")
        success "Built site."
      end

      def release_site
        guard_clean
        build_site
        git_push
      end

      protected

      def git_push
        perform_git_push
        success "Pushed to GitHub."
      end

      def perform_git_push(options = '')
        cmd = "git push #{options}"
        out, code = sh_with_code(cmd)
        raise "Couldn't git push. `#{cmd}' failed with the following output:\n\n#{out}\n" unless code == 0
      end

      def guard_clean
        clean? && committed? or raise("There are files that need to be committed first.")
      end

      def clean?
        sh_with_code("git diff --exit-code")[1] == 0
      end

      def committed?
        sh_with_code("git diff-index --quiet --cached HEAD")[1] == 0
      end

      def sh(cmd, &block)
        out, code = sh_with_code(cmd, &block)
        code == 0 ? out : raise(out.empty? ? "Running `#{cmd}' failed. Run this command directly for more detailed output." : out)
      end

      def sh_with_code(cmd, &block)
        cmd << " 2>&1"
        outbuf = ''
        old_dir = Dir.pwd
        Dir.chdir base

        outbuf = `#{cmd}`
        if $? == 0
          block.call(outbuf) if block
        end

        Dir.chdir old_dir
        [outbuf, $?]
      end

      def success(msg)
        puts "\u2713 #{msg}".color(:green)
      end
    end
  end
end