# See Pagy API documentation: https://ddnexus.github.io/pagy/docs/api/keyset
# frozen_string_literal: true

require 'json'
require 'active_support/hash_with_indifferent_access'
require_relative 'b64'
require_relative 'init_vars'

class Pagy # :nodoc:
  # Implement wicked-fast, no-frills keyset pagination for big data
  #
  # The Pagy Keyset pagination does not waste resources and code complexity
  # checking your scope nor your table config at every request.
  #
  # That means that you have to be sure that your scope is right,
  # and that your tables have the right indices (for performance).
  # You do it once during development, not pagy at each request. ;)
  #
  # Scope
  # - You have to pass an ordered scope or pass a :reorder hash
  #   - The concatenation of the order columns must be unique:
  #     add the primary key as the last order column as a tie-breaker
  #     if the concatenation of the order columns might not be unique
  #
  # Constraints
  # As for any keyset pagination:
  #   - You don't know the page count
  #   - The pages have no number
  #   - You cannot jump to an arbitrary page
  #   - You can only get the next page
  #   - And you know that you reached the end of the collection when pagy.next.nil?
  # As for the Pagy Offset pagination:
  #   - You paginate only forward. For backward... just reverse the order
  #     in your scope and paginate forward in the reversed order.

  # Requires activerecord or sequel (WIP)
  # This should work also with the items, headers, json_api extras (WIP)
  class Keyset
    include InitVars

    attr_reader :page, :items, :cursor, :vars

    def initialize(scope, page: nil, **vars)
      @scope = scope
      @page  = page
      normalize_vars(vars)
      setup_items_var
      setup_order
      setup_cursor if @page
    end

    def next
      records
      return unless @more

      @next ||= begin
        cursor = @records.last.slice(*@order.keys)
        B64.urlsafe_encode(cursor.to_json)
      end
    end

    # Query the DB for the page of records
    def records
      @records ||= begin
        @scope  = @scope.select(*@order.keys) unless @scope.select_values.empty?
        @scope  = @scope.where((@vars[:where_query] || where_query), @cursor) if @cursor
        records = @scope.limit(@items + 1).to_a
        @more   = records.size > @items && !records.pop.nil?
        records
      end
    end

    # Setup the cursor to a symbolic typecasted hash of the order columns values
    def setup_cursor
      cursor = JSON.parse(B64.urlsafe_decode(@page)).symbolize_keys
      raise InternalError, 'Order and page cursor are not consistent' \
             unless cursor.keys == @order.keys

      @cursor = @scope.model.new(cursor).slice(cursor.keys).symbolize_keys
    end

    # Setup the order from :reorder or the :scope
    def setup_order
      @order = @scope.order_values.each_with_object({}) do |node, order|
                 order[node.value.name.to_sym] = node.direction
               end
      raise InternalError, 'The :scope must be ordered' if @order.nil? || @order.empty?
    end

    # Prepare the where query
    def where_query
      comp   = { asc: '>', desc: '<' }
      values = @order.values
      if @vars[:row_comparison] && (values.all?(:asc) || values.all?(:desc))
        # Row comparison working for the same order columns direction
        # Use b-tree index for performance
        columns      = @order.keys
        placeholders = columns.map { |k| ":#{k}" }.join(', ')
        "( #{columns.join(', ')} ) #{comp[values.first]} ( #{placeholders} )"
      else
        # Generic comparison for any order column direction
        order = @order.to_a
        where = []
        until order.empty?
          last_col, last_dir = order.pop
          query = +'( '
          query << (order.map { |column, _d| "#{column} = :#{column}" } \
                    << "#{last_col} #{comp[last_dir]} :#{last_col}").join(' AND ')
          query << ' )'
          where << query
        end
        where.join(' OR ')
      end
    end
  end
end

require_relative 'backend'
require_relative 'exceptions'
