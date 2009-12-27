require 'test/unit'

require 'rubygems'
gem 'activerecord', '>= 1.15.4.7794'
require 'active_record'
require 'mocha'
require 'ruby-debug'

require "#{File.dirname(__FILE__)}/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :super_heros do |t|
      # Might want to include untracked columns
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    create_table :super_hero_dated_details do |t|
      t.column :parent_id, :integer
      t.column :strength, :integer
    end
  end
end

# def create_superhero_with_dated_detail
#   @superhero = SuperHero.create(:strength => 1)
# end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

setup_db

class SuperHeroDatedDetail < ActiveRecord::Base
  acts_as_dated_detail
end

class SuperHero < ActiveRecord::Base
  acts_as_dated
end

teardown_db

class DatedDetailTest < Test::Unit::TestCase
  def setup
    setup_db
    # create_superhero_with_dated_detail
  end

  def teardown
    teardown_db
  end

  # def test_start_on
  #   
  # end
  # 
  # def test_end_on
  #   
  # end
  # 
  # def test_end_on_for_last_dated_detail
  #   
  # end
  # 
  # def test_previous
  #   
  # end
  # 
  # def test_previous_for_first_dated_detail
  #   
  # end
  # 
  # def test_next
  #   
  # end
  # 
  # def test_next_for_last_dated_detail
  #   
  # end
  
  def test_related_dated_detail_created_along_with_model
    superhero = SuperHero.create!
    assert_equal 1, SuperHero.count
    assert_equal 1, SuperHeroDatedDetail.count
    assert_equal superhero, SuperHeroDatedDetail.first.parent
  end
  
  def test_read_attribute
    # dated_detail = SuperHeroDatedDetail.first(:conditions => "superhero_id = #{@unchanged_superhero.id}")
    # assert_equal dated_detail.strength, @unchanged_superhero.strength
  end
  
  def test_write_attribute
    
  end
  
  def test_updating_attribute_creates_new_dated_detail
    
  end
  
  def test_updating_attribute_sets_end_date_for_previous_dated_detail
    
  end
end
