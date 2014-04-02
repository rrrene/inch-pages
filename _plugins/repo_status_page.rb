require 'fileutils'

module Jekyll
  class RepoStatusPage < Page
    attr_reader :repo

    def initialize(site, base, dir, repo)
      @site = site
      @base = base
      @dir = dir
      @repo = repo

      @name = repo.name
      @template_name = 'repo.html'

      self.process(@template_name)
      self.read_yaml(@base, @template_name)
      self.data['title'] = repo.name
      self.data['repo'] = repo.to_liquid

      puts ' ' * 20 + "- #{@name}"
    end

    # Creates a badge image file for the given +repo+
    def create_badge(dest)
      %w(png svg).each do |ext|
        filename = File.join(dest, "github", "#{name}.#{ext}")
        Inch::Badge::Image.create(filename, repo.badge_numbers)
      end
    end

    # Obtain destination path.
    #
    # dest - The String path to the destination dir.
    #
    # Returns the destination file path String.
    def destination(dest)
      path = File.join(dest, @dir, @name)
      path = File.join(path, "index.html") if self.url =~ /\/$/
      path
    end

    def write(dest)
      super
      create_badge(dest)
    end
  end
end
