# See the Pagy documentation: https://ddnexus.github.io/pagy/docs/extras/keyset
# frozen_string_literal: true

require_relative '../keyset'

class Pagy # :nodoc:
  # Add keyset pagination
  module KeysetExtra
    private

    # Return Pagy::Keyset object and paginated records
    def pagy_keyset(scope, **vars)
      pagy = Keyset.new(scope:, **pagy_keyset_get_vars(vars))
      [pagy, pagy.records]
    end

    # Sub-method called only by #pagy_keyset: here for easy customization of variables by overriding
    def pagy_keyset_get_vars(vars)
      pagy_set_items_from_params(vars) if defined?(ItemsExtra)
      vars[:page] ||= pagy_get_page(vars)
      vars
    end

    # Get the page from the params
    # Override the backend method
    # Overridable by the jsonapi extra
    def pagy_get_page(vars)
      params[vars[:page_param] || DEFAULT[:page_param]]
    end
  end
  Backend.prepend KeysetExtra
end
