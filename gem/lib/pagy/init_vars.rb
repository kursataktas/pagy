# frozen_string_literal: true

class Pagy # :nodoc:
  # Module used also by keyset
  module InitVars
    protected

    # Apply defaults, cleanup blanks and set @vars
    def normalize_vars(vars)
      @vars = DEFAULT.merge(vars.delete_if { |k, v| DEFAULT.key?(k) && (v.nil? || v == '') })
    end

    # Setup and validates the passed vars: var must be present and value.to_i must be >= to min
    def setup_vars(name_min)
      name_min.each do |name, min|
        raise VariableError.new(self, name, ">= #{min}", @vars[name]) \
              unless @vars[name]&.respond_to?(:to_i) && instance_variable_set(:"@#{name}", @vars[name].to_i) >= min
      end
    end

    # Setup @items (overridden by the gearbox extra)
    def setup_items_var
      setup_vars(items: 1)
    end
  end
end
