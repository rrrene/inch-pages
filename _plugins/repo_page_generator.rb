require_relative 'repo_status_page'

module Jekyll
  class RepoPageGenerator < Generator
    safe true

    def generate(site)
      puts
      Inch::Pages::Repo.all.each do |repo|
        site.pages << RepoStatusPage.new(site, site.source, "github", repo)
      end
    end
  end
end
