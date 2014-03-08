module Inch
  module Pages
    class CodeObject < Struct.new(:object)
      def to_liquid
        {
          "fullname" => object.fullname,
          "trunc_name" => truncate(object.fullname),
          "grade" => object.grade.to_s,
          "priority" => priority_sym(object.priority).to_s,
        }
      end

      private

      def priority_sym(priority)
        ::Inch::Evaluation::PriorityRange.all.each do |range|
          if range.include?(priority)
            return range.to_sym
          end
        end
      end

      def truncate(name, max = 55, delimiter = '::', separator = " <em>&hellip;</em> ")
        return name if name.size <= max
        parts = name.split(delimiter)
        _start = [parts.shift]
        _end = [parts.pop]

        current_string = _start.join(delimiter) + delimiter + separator +
                          delimiter + _end.join(delimiter)

        result_string = current_string
        while current_string.size <= max
          result_string = current_string.to_s
          _start << parts.shift
          current_string = _start.join(delimiter) + delimiter + separator +
                          delimiter + _end.join(delimiter)
        end
        if result_string.size > max && result_string =~ /#/
          result_string = result_string.gsub(/(\S+)#/, '#')
        end
        result_string
      end
    end
  end
end