module Inch
  module Pages
    ROOT = File.join(File.dirname(__FILE__), "..", "..", "..")

    Repomen.config.work_dir = File.join(ROOT, "_repos")

    class ProjectConfig
      class << self
        # Returns all repo names from _projects.yml
        # (unless DEVMODE or REPO is set in ENV)
        def all_repo_names
          all = load_yamls("_projects.yml", "_popular.yml").flatten
          if devmode = ENV['REPO'] || ENV['DEVMODE']
            repo_names_for_dev_mode all, devmode
          else
            all
          end
        end

        def load_yaml(relative_path)
          YAML.load( File.read File.join(ROOT, relative_path) )
        end

        def load_yamls(*relative_paths)
          relative_paths.map { |path| load_yaml(path) }
        end

        # Returns an array of repo names
        #   if +devmode+ is a repo name, it returns it
        #   otherwise if returns the first two repos in the +list+
        def repo_names_for_dev_mode(list, devmode)
          if devmode =~ /\//
            [devmode]
          else
            if devmode.to_i == 0
              []
            else
              list[0..1]
            end
          end
        end
      end
    end

    class AccessToken
      class << self
        # Returns an access token for the given +service+
        def [](service)
          all[service.to_s]
        end

        # @return [Hash] all access tokens
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

        def default_documentation_url(repo_name)
          "http://rubydoc.info/github/#{repo_name}/master/frames"
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
