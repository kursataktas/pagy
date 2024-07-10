# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../files/models'
require_relative '../../gem/lib/pagy/b64'

require 'pagy/keyset'

describe 'Pagy::Keyset' do
  describe '#initialize' do
    it 'raises ArgumentError without arguments' do
      err = assert_raises(ArgumentError) { Pagy::Keyset.new }
      assert_match(/wrong number of arguments/, err.message)
    end
    it 'raises ArgumentError without arguments' do
      err = assert_raises(Pagy::InternalError) { Pagy::Keyset.new(Pet.all) }
      assert_match(/The :scope must be ordered/, err.message)
    end
    it 'is an instance of Pagy::Keyset' do
      _(Pagy::Keyset.new(Pet.order(:id))).must_be_instance_of Pagy::Keyset
    end
    it 'raises Pagy::InternalError for inconsistent page/cursor' do
      page_animal_id = Pagy::B64.urlsafe_encode({animal: 'dog', id: 23}.to_json)
      err = assert_raises(Pagy::InternalError) do
        Pagy::Keyset.new(Pet.order(:id), items: 10, page: page_animal_id)
      end
      assert_match(/Order and page cursor are not consistent/, err.message)
    end
  end
  describe '#setup_order' do
    it 'extracts the scope order' do
      pagy = Pagy::Keyset.new(Pet.order(:id))
      _(pagy.instance_variable_get(:@order)).must_equal({id: :asc})
      pagy = Pagy::Keyset.new(Pet.order(id: :desc))
      _(pagy.instance_variable_get(:@order)).must_equal({id: :desc})
      pagy = Pagy::Keyset.new(Pet.order(:id, animal: :desc))
      _(pagy.instance_variable_get(:@order)).must_equal({id: :asc, animal: :desc})
    end
  end
  describe 'handles the page/cursor' do
    it 'handles the page/cursor for the first page' do
      pagy = Pagy::Keyset.new(Pet.order(:id), items: 10)
      _(pagy.cursor).must_be_nil
      _(pagy.next).must_equal "eyJpZCI6MTB9"
    end
    it 'handles the page/cursor for the second page' do
      pagy = Pagy::Keyset.new(Pet.order(:id), items: 10, page: "eyJpZCI6MTB9")
      _(pagy.cursor).must_equal({id: 10})
      _(pagy.records.first.id).must_equal 11
      _(pagy.next).must_equal "eyJpZCI6MjB9"
    end
    it 'handles the page/cursor for the last page' do
      pagy = Pagy::Keyset.new(Pet.order(:id), items: 10, page: "eyJpZCI6NDB9")
      _(pagy.next).must_be_nil
    end
  end
  describe 'other requirements' do
    it 'adds the required columns to the selected values' do
      scope = Pet.order(:animal, :name, :id).select(:name)
      pagy  = Pagy::Keyset.new(scope, items: 10)
      pagy.records
      _(pagy.instance_variable_get(:@scope).select_values.sort).must_equal %i[animal name id].sort
    end
    it 'use the :row_comparison' do
      pagy = Pagy::Keyset.new(Pet.order(:animal, :name, :id),
                              page: "eyJhbmltYWwiOiJjYXQiLCJuYW1lIjoiRWxsYSIsImlkIjoxOH0",
                              items: 10,
                              row_comparison: true)
      records = pagy.records
      _(records.size).must_equal 10
      _(records.first.id).must_equal 13
    end
  end
end
