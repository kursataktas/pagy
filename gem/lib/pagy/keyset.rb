# See Pagy API documentation: https://ddnexus.github.io/pagy/docs/api/keyset
# frozen_string_literal: true

require 'json'
require_relative 'b64'
require_relative 'init_vars'

class Pagy # :nodoc:
  # Implement wicked-fast, no-frills keyset pagination for big data
  class Keyset
    include InitVars

    attr_reader :page, :vars

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
        @scope  = @scope.select(*@order.keys.map(&:to_sym)) unless @scope.select_values.empty?
        @scope  = @scope.where((@vars[:where_query] || where_query), @cursor) if @cursor
        records = @scope.limit(@items + 1).to_a
        @more   = records.size > @items && !records.pop.nil?
        records
      end
    end

    # Setup the cursor to a symbolic typecasted hash of the order columns values
    def setup_cursor
      cursor = JSON.parse(B64.urlsafe_decode(@page))
      raise InternalError, 'Order and page cursor are not consistent' \
             unless cursor.keys == @order.keys

      @cursor = @scope.model.new(cursor).slice(cursor.keys)
    end

    # Setup the order from :reorder or the :scope
    def setup_order
      @order = @scope.order_values.each_with_object({}) do |node, order|
                 order[node.value.name] = node.direction
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
