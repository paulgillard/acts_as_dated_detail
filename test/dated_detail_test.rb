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
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
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

class ParentTest < Test::Unit::TestCase
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

class DatedDetailTest < Test::Unit::TestCase
  def setup
    setup_db
    # create_superhero_with_dated_detail
  end

  def teardown
    teardown_db
  end
  
  # Tracked Attributes
  
  def test_tracked_attributes_includes_relevant_columns
    assert SuperHeroDatedDetail.tracked_attributes.include?('strength')
  end
  
  def test_tracked_attributes_excludes_id
    assert !SuperHeroDatedDetail.tracked_attributes.include?('id')
  end
  
  def test_tracked_attributes_excludes_start_on
    assert !SuperHeroDatedDetail.tracked_attributes.include?('start_on')
  end
  
  def test_tracked_attributes_excludes_end_on
    assert !SuperHeroDatedDetail.tracked_attributes.include?('end_on')
  end
  
  def test_tracked_attributes_excludes_updated_at
    assert !SuperHeroDatedDetail.tracked_attributes.include?('updated_at')
  end
  
  def test_tracked_attributes_excludes_created_at
    assert !SuperHeroDatedDetail.tracked_attributes.include?('created_at')
  end
  
  def test_tracked_attributes_excludes_parent_id
    assert !SuperHeroDatedDetail.tracked_attributes.include?('parent_id')
  end
end
