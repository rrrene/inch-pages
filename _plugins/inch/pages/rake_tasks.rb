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
        @inch_pages_dir = File.join(base, "..", "inch-pages.github.io")
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
        env = ENV['REPO'] ? "REPO=#{ENV['REPO']} " : ""
        sh("#{env}jekyll build")
        copy_site
        success "Built site."
      end

      def release_site
        guard_clean(@inch_pages_dir)
        git_pull(@inch_pages_dir)
        build_site
        git_add_all(@inch_pages_dir)
        git_commit_all(commit_msg, @inch_pages_dir)
        git_push(@inch_pages_dir)
      end

      protected

      def commit_msg
        uid = Time.now.strftime("%Y-%m-%d %H:%M")
        "Publish inch-pages #{uid}"
      end

      def copy_site(target = @inch_pages_dir)
        glob = File.join(base, "_site", "*")
        Dir[glob].each do |f|
          FileUtils.cp_r f, target
        end
      end

      def git_pull(dir)
        cmd = "git pull"
        out, code = sh_with_code(cmd, dir)
        fail "Couldn't git pull. `#{cmd}' failed with the following output:\n\n#{out}\n" unless code == 0
      end

      def git_push(dir)
        perform_git_push(dir)
        success "Pushed to GitHub."
      end

      def perform_git_push(dir, options = '')
        cmd = "git push #{options}"
        out, code = sh_with_code(cmd, dir)
        fail "Couldn't git push. `#{cmd}' failed with the following output:\n\n#{out}\n" unless code == 0
      end

      def git_add_all(dir)
        cmd = "git add ."
        out, code = sh_with_code(cmd, dir)
        fail "Couldn't git add. `#{cmd}' failed with the following output:\n\n#{out}\n" unless code == 0
      end

      def git_commit_all(msg, dir)
        cmd = "git commit -m \"#{msg}\""
        out, code = sh_with_code(cmd, dir)
        if code != 0
          if out =~ /nothing to commit/
            abort "nothing new to publish."
          else
            fail "Couldn't git commit. `#{cmd}' failed with the following output:\n\n#{out}\n"
          end
        end
      end

      def guard_clean(dir = base)
        clean?(dir) && committed?(dir) or fail("There are files in #{dir} that need to be committed first.")
      end

      def clean?(dir)
        sh_with_code("git diff --exit-code", dir)[1] == 0
      end

      def committed?(dir)
        sh_with_code("git diff-index --quiet --cached HEAD", dir)[1] == 0
      end

      def sh(cmd, dir = nil, &block)
        out, code = sh_with_code(cmd, dir, &block)
        code == 0 ? out : fail(out.empty? ? "Running `#{cmd}' failed. Run this command directly for more detailed output." : out)
      end

      def sh_with_code(cmd, dir = nil, &block)
        dir ||= base
        cmd << " 2>&1"
        outbuf = ''
        chdir(dir) do
          outbuf = `#{cmd}`
          if $? == 0
            block.call(outbuf) if block
          end
        end
        [outbuf, $?]
      end

      def abort(msg)
        warn "\u2717 #{msg}".color(:yellow)
        exit 2
      end

      def fail(msg)
        warn "\u2717 #{msg}".color(:red)
        exit 1
      end

      def success(msg)
        puts "\u2713 #{msg}".color(:green)
      end

      def chdir(dir, &block)
        old_dir = Dir.pwd
        Dir.chdir dir
        yield
        Dir.chdir old_dir
      end
    end
  end
end