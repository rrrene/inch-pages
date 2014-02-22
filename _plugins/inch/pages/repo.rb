module Inch
  module Pages
    class Repo < Struct.new(:name)
      class << self
        def all
          @all ||= ProjectConfig.all_repo_names.map { |name| new(name) }
        end
      end

      def badge_numbers
        grade_lists.map { |list| list.objects.size }
      end

      def description
        @description ||= gh_repo.description
      end

      def documentation_url
        if gem_name
          @documentation_url ||= Rubygems.documentation_url(gem_name)
        end
      end

      def grade_lists
        list.grade_lists
      end

      def url
        "https://github.com/#{name}"
      end

      def to_liquid
        hash = {}
        attrs = %w(name description documentation_url url).each do |key|
          hash[key] = send(key)
        end
        grade_lists.each do |grade_list|
          key = grade_list.grade.to_s
          object_count = 5
          all_objects = liquify_objects(grade_list.objects)
          objects = all_objects[0...object_count]
          more_objects = all_objects[object_count..-1] || []

          hash[key] = {}
          hash[key]["percent"] = list_percent(grade_list.objects)
          hash[key]["objects"] = objects
          hash[key]["more_objects"] = more_objects
          hash[key]["more_count"] = more_objects.size
        end
        # there might be rounding errors, let's find them
        residual = 100 - hash["A"]["percent"] - hash["B"]["percent"] - hash["C"]["percent"] - hash["U"]["percent"]
        %w(A B C U).detect do |key|
          if hash[key]["percent"] > 0
            hash[key]["percent"] += residual
            true
          end
        end
        hash
      end

      private

      def file?(filename)
        File.exists?( File.join(localpath, filename) )
      end

      def gem_name
        repo_name if File.exists?("#{repo_name}.gemspec")
      end

      def gh_repo
        gh_repo ||= GitHub.repo(name)
      end

      def git_url
        "#{url}.git"
      end

      def list
        @list ||= begin
          codebase = Inch::Codebase.parse(local_path)
          Inch::API::List.new(codebase, {})
        end
      end

      def liquify_objects(objects)
        objects.map do |object|
          CodeObject.new(object).to_liquid
        end
      end

      def list_percent(objects)
        p = (objects.size / list.objects.size.to_f)
        (p* 100).to_i
      end

      def local_path
        Repomen.retrieve(git_url).path
      end

      def repo_name
        name.split('/').last
      end
    end
  end
end