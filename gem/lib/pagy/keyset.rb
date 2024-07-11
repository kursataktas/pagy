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

    def initialize(set, page: nil, **vars)
      @set  = set
      @page = page
      normalize_vars(vars)
      setup_items_var
      setup_keyset
      setup_cursor if @page
    end

    # The next page
    def next
      records
      return unless @more

      @next ||= begin
        cursor = @records.last.slice(*@keyset.keys)
        B64.urlsafe_encode(cursor.to_json)
      end
    end

    # The array of records for the current page
    def records
      @records ||= begin
        @set    = @set.select(*@keyset.keys.map(&:to_sym)) unless @set.select_values.empty?
        @set    = @set.where((@vars[:where_query] || where_query), @cursor) if @cursor
        records = @set.limit(@items + 1).to_a
        @more   = records.size > @items && !records.pop.nil?
        records
      end
    end

    private

    # Setup the cursor to a symbolic typecasted hash of the order columns values
    def setup_cursor
      cursor = JSON.parse(B64.urlsafe_decode(@page))
      raise InternalError, 'page and keyset are not consistent' \
             unless cursor.keys == @keyset.keys

      @cursor = @set.model.new(cursor).slice(cursor.keys)
    end

    # Setup the keyset from the set
    def setup_keyset
      @keyset = @set.order_values.each_with_object({}) do |node, keyset|
                  keyset[node.value.name] = node.direction
                end
      raise InternalError, 'the set must be ordered' if @keyset.empty?
    end

    # Prepare the where query
    def where_query
      operator   = { asc: '>', desc: '<' }
      directions = @keyset.values
      if @vars[:row_comparison] && (directions.all?(:asc) || directions.all?(:desc))
        # Row comparison works for same directions keysets
        # Use b-tree index for performance
        columns      = @keyset.keys
        placeholders = columns.map { |k| ":#{k}" }.join(', ')
        "( #{columns.join(', ')} ) #{operator[directions.first]} ( #{placeholders} )"
      else
        # Generic comparison works for keysets ordered in mixed or same directions
        keyset = @keyset.to_a
        where  = []
        until keyset.empty?
          last_col, last_dir = keyset.pop
          query = +'( '
          query << (keyset.map { |column, _d| "#{column} = :#{column}" } \
                    << "#{last_col} #{operator[last_dir]} :#{last_col}").join(' AND ')
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
