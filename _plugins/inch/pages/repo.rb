module Inch
  module Pages
    class Repo < Struct.new(:name)
      class << self
        def all
          @all ||= ProjectConfig.all_repo_names.map { |name| new(name) }
        end
      end

      def badge_numbers
        grade_lists.map do |list|
          relevant_objects_graded(list.grade).size
        end
      end

      def description
        @description ||= gh_repo.description
      end

      def documentation_url
        if gem_name
          @documentation_url ||= Rubygems.documentation_url(gem_name)
        else
          GitHub.default_documentation_url(name)
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
          _objects = relevant_objects_graded(grade_list.grade)
          all_objects = liquify_objects(_objects)

          object_count = 5
          objects = all_objects[0...object_count]
          more_objects = all_objects[object_count..-1] || []

          key = grade_list.grade.to_s
          hash[key] = {}
          hash[key]["percent"] = list_percent(_objects)
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

      def codebase
        @codebase ||= Inch::Codebase.parse(local_path)
      end

      def file?(filename)
        File.exists?( File.join(localpath, filename) )
      end

      def gemspec
        Dir[File.join(local_path, "*.gemspec")].first
      end

      def gem_name
        if filename = gemspec
          File.basename filename, ".gemspec"
        end
      end

      def gh_repo
        gh_repo ||= GitHub.repo(name)
      end

      def git_url
        "#{url}.git"
      end

      def list
        @list ||= Inch::API::List.new(codebase, {})
      end

      def liquify_objects(objects)
        objects.map do |object|
          CodeObject.new(object).to_liquid
        end
      end

      def list_percent(objects)
        return 0 if object_count == 0
        p = (objects.size / object_count.to_f)
        (p * 100).to_i
      end

      def local_path
        Repomen.retrieve(git_url).path
      end

      def object_count
        @object_count ||= relevant_objects.size
      end

      # Returns only objects with non-negative priority
      def relevant_objects
        suggest.all_objects
      end

      def relevant_objects_graded(grade)
        relevant_objects.select do |object|
          object.grade == grade
        end
      end

      def repo_name
        name.split('/').last
      end

      def suggest
        @suggest ||= Inch::API::Suggest.new(codebase, {})
      end
    end
  end
end