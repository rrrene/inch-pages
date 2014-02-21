module Inch
  module Pages
    ROOT = File.join(File.dirname(__FILE__), "..", "..", "..")

    Repomen.config.work_dir = File.join(ROOT, "_repos")

    class ProjectConfig
      class << self
        def all_repo_names
          YAML.load( File.read File.join(ROOT, "_projects.yml") )
        end
      end
    end

    class AccessToken
      class << self
        def [](key)
          all[key.to_s]
        end

        def all
          @all ||= YAML.load( File.read File.join(ROOT, ".access_tokens") )
        end
      end
    end

    class GitHub
      class << self
        def client
          @client ||= Octokit::Client.new :access_token => AccessToken[:github]
        end

        def repo(repo_name)
          client.repository(repo_name)
        end
      end
    end

    class Rubygems
      class << self
        def gem(gem_name)
          Gems.info(gem_name)
        end

        def documentation_url(gem_name)
          hash = gem(gem_name)
          url = hash["documentation_uri"]
          if url && !url.empty?
            url
          else
            default_documentation_url(hash)
          end
        end

        def default_documentation_url(hash)
          name, version = hash["name"], hash["version"]
          "http://rubydoc.info/gems/#{name}/#{version}/frames"
        end
      end
    end
  end
end
