require 'test/unit'

require 'rubygems'
gem 'activerecord', '>= 1.15.4.7794'
require 'active_record'
require 'mocha'
require 'ruby-debug'

require "#{File.dirname(__FILE__)}/../lib/acts_as_dated_detail"

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
      t.column :super_hero_id, :integer
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

class ActsAsDatedDetailTest < Test::Unit::TestCase
  def setup
    setup_db
  end

  def teardown
    teardown_db
  end
  
  def default_test
  end
  
  private
  
  def create_superhero(times)
    first_time = times.shift
    now = Time.now
    Time.stubs(:now).returns(first_time)
    puts now - first_time
    superhero = SuperHero.create!(:strength => strength(first_time))
    times.each do |time|
      Time.stubs(:now).returns(time)
      superhero.update_attribute(:strength, strength(time))
    end
    Time.stubs(:now).returns(now)
    superhero
  end
  
  def strength(time)
    time.to_i
  end
end

class ParentTest < ActsAsDatedDetailTest
  # Creation
  
  def test_related_dated_detail_created_along_with_model
    superhero = SuperHero.create!
    assert_equal 1, superhero.dated_details.count
  end
  
  # Currently Effective Timestamp
  
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
  
  # Tracked Attribute Retrieval
  
  def test_tracked_attribute_for_oldest_timestamp_set_by_instance_method
    superhero = create_superhero([1.year.ago, 6.months.ago, 1.month.ago])
    superhero.on = 8.months.ago
    assert_equal strength(1.year.ago), superhero.strength
  end
  
  def test_tracked_attribute_for_middle_timestamp_set_by_instance_method
    superhero = create_superhero([1.year.ago, 6.months.ago, 1.month.ago])
    superhero.on = 5.months.ago
    assert_equal strength(6.months.ago), superhero.strength
  end
  
  def test_tracked_attribute_for_newest_timestamp_set_by_instance_method
    superhero = create_superhero([1.year.ago, 6.months.ago, 1.month.ago])
    superhero.on = 2.weeks.ago
    assert_equal strength(1.month.ago), superhero.strength
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
  
  # Updating Attributes
  
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

class DatedDetailTest < ActsAsDatedDetailTest
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
    assert !SuperHeroDatedDetail.tracked_attributes.include?('super_hero_id')
  end
  
  # Dated Detail Retrieval
  
  def test_dated_detail_for_oldest_timestamp_retrieved_via_named_scope
    superhero = create_superhero([1.year.ago, 6.months.ago, 1.month.ago])
    assert_equal strength(1.year.ago), superhero.dated_details.on(8.months.ago).first.strength
  end
  
  def test_tracked_attribute_for_middle_timestamp_retrieved_via_named_scope
    superhero = create_superhero([1.year.ago, 6.months.ago, 1.month.ago])
    assert_equal strength(6.months.ago), superhero.dated_details.on(5.months.ago).first.strength
  end
  
  def test_tracked_attribute_for_newest_timestamp_retrieved_via_named_scope
    superhero = create_superhero([1.year.ago, 6.months.ago, 1.month.ago])
    assert_equal strength(1.month.ago), superhero.dated_details.on(2.weeks.ago).first.strength
  end
end
