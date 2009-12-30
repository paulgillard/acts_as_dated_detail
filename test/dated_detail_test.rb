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
      t.column :name, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    create_table :super_hero_dated_details do |t|
      # Ensure any attributes added here are added to relevant tests (search for 'strength')
      t.column :parent_id, :integer
      t.column :start_on, :datetime
      t.column :end_on, :datetime
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
  
  # Creation
  
  def test_related_dated_detail_created_along_with_model
    superhero = SuperHero.create!
    assert_equal 1, superhero.dated_details.count
  end
  
  # Currently effective timestamp
  
  def test_default_value_of_currently_effective_timestamp
    now = Time.now
    Time.stubs(:now).returns(now)
    superhero = SuperHero.create!
    assert_equal Time.now, superhero.on
  end
  
  def test_setting_value_of_currently_effective_timestamp
    now = Time.now
    Time.stubs(:now).returns(now)
    superhero = SuperHero.create!
    one_month_ago = Time.now - 1.month
    superhero.on = one_month_ago
    assert_equal one_month_ago, superhero.on
  end
  
  # Dated Detail
  
  # TODO: We'll correct this to fetch dated detail as of current timestamp at a future date
  def test_dated_detail
    superhero = SuperHero.create!
    assert_equal superhero.dated_details.first, superhero.dated_detail
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
  
  # Tracked Attribute Methods
  
  def test_read_tracked_attributes
    # Ensure value from dated_detail is returned
    superhero = SuperHero.create!
    dated_detail = superhero.dated_detail
    superhero.stubs(:dated_detail).returns(dated_detail)
    SuperHeroDatedDetail.tracked_attributes.each do |attribute|
      value = 10
      SuperHeroDatedDetail.any_instance.stubs(attribute).returns("Error")
      dated_detail.stubs(attribute).returns(value)
      assert_equal value, superhero.send(attribute)
    end
  end
  
  def test_write_tracked_attributes
    superhero = SuperHero.create!
    SuperHeroDatedDetail.tracked_attributes.each do |attribute|
      value = 10
      superhero.send("#{attribute}=", value)
      assert_equal value, superhero.dated_detail.send(attribute)
    end
  end
  
  # Updating Tracked Attributes
  
  def test_updating_tracked_attribute
    now = Time.now
    Time.stubs(:now).returns(now - 1.year)
    superhero = SuperHero.create!
    Time.stubs(:now).returns(now)
    superhero.update_attribute(:strength, 10)
    assert_equal 2, superhero.dated_details.count
  end
  
  def test_updating_untracked_attribute
    now = Time.now
    Time.stubs(:now).returns(now - 1.year)
    superhero = SuperHero.create!
    Time.stubs(:now).returns(now)
    superhero.update_attribute(:name, 'Batman')
    assert_equal 1, superhero.dated_details.count
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
  
  # Creation
  
  def test_initial_start_on_value
    superhero = SuperHero.create!
    assert_equal Time.now.to_i, SuperHeroDatedDetail.first.start_on.to_i
  end
  
  def test_initial_end_on_value
    superhero = SuperHero.create!
    assert_nil SuperHeroDatedDetail.first.end_on
  end
  
  # Updating
  
  def test_updating
    now = Time.now
    Time.stubs(:now).returns(now - 1.year)
    superhero = SuperHero.create!
    Time.stubs(:now).returns(now)
    
    dated_detail = superhero.dated_detail
    original_dated_detail = dated_detail.class.find(dated_detail.id) # Cloning would keep millisecond parts of time which would make later comparisons harder
    
    dated_detail.update_attribute(:strength, 10)
    
    assert_equal now.to_i, dated_detail.start_on.to_i
    assert_nil dated_detail.end_on
    
    previous_dated_detail = SuperHeroDatedDetail.find_by_start_on(original_dated_detail.start_on)
    assert_equal dated_detail.start_on.to_i - 1, previous_dated_detail.end_on.to_i
    assert_equal original_dated_detail.attributes.except('end_on', 'id'), previous_dated_detail.attributes.except('end_on', 'id')
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
