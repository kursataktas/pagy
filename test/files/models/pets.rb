# frozen_string_literal: true

require 'active_record'

# Models
class Pet < ActiveRecord::Base
end

db_path ="#{__dir__}/../db/keyset.sqlite3"

# Activerecord initializer
# No logs in test
# ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: db_path)

# :nocov:
unless File.exist?(db_path)

  ActiveRecord::Schema.define do
    create_table :pets, force: true do |t|
      t.string :name
      t.string :animal
      t.datetime :birthdate
    end
  end

  PETS = <<~PETS
    Luna  | dog    | 2018-03-10
    Coco  | cat    | 2019-05-15
    Dodo  | dog    | 2020-06-25
    Wiki  | bird   | 2018-03-12
    Baby  | rabbit | 2020-01-13
    Neki  | horse  | 2021-07-20
    Tino  | donkey | 2019-06-18
    Plot  | cat    | 2022-09-21
    Riki  | cat    | 2018-09-14
    Susi  | horse  | 2018-10-26
    Coco  | pig    | 2020-08-29
    Momo  | bird   | 2023-08-25
    Lili  | cat    | 2021-07-22
    Beli  | pig    | 2020-07-26
    Rocky | bird   | 2022-08-19
    Vyvy  | dog    | 2018-05-16
    Susi  | horse  | 2024-01-25
    Ella  | cat    | 2020-02-20
    Rocky | dog    | 2019-09-19
    Juni  | rabbit | 2020-08-24
    Coco  | bird   | 2021-03-17
    Susi  | dog    | 2021-07-28
    Luna  | horse  | 2023-05-14
    Gigi  | pig    | 2022-05-19
    Coco  | cat    | 2020-02-20
    Nino  | donkey | 2019-06-17
    Luna  | cat    | 2022-02-09
    Popi  | dog    | 2020-09-26
    Lili  | pig    | 2022-06-18
    Mina  | horse  | 2021-04-21
    Susi  | rabbit | 2023-05-18
    Toni  | donkey | 2018-06-22
    Rocky | horse  | 2019-09-28
    Lili  | cat    | 2019-03-18
    Roby  | cat    | 2022-06-19
    Anto  | horse  | 2022-08-18
    Susi  | pig    | 2021-04-21
    Boly  | bird   | 2020-03-29
    Sky   | cat    | 2023-07-19
    Lili  | dog    | 2020-01-28
    Fami  | snake  | 2023-04-27
    Lopi  | pig    | 2019-06-19
    Rocky | snake  | 2022-03-13
    Denis | dog    | 2022-06-19
    Maca  | cat    | 2022-06-19
    Luna  | dog    | 2022-08-15
    Jeme  | horse  | 2019-08-08
    Sary  | bird   | 2023-04-29
    Rocky | bird   | 2023-05-14
    Coco  | dog    | 2023-05-27
  PETS

  # DB seed
  pets = []
  PETS.each_line(chomp: true) do |pet|
    name, animal, birthdate = pet.split('|').map(&:strip)
    pets << { name:, animal:, birthdate: }
  end
  Pet.insert_all(pets)
end
