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
    create_table :parrots do |t|
      t.column :name, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    create_table :pirates do |t|
      t.column :name, :string
      t.column :catchphrase, :string
      t.column :ruthlessness, :integer
      t.column :birth_date, :datetime
      t.column :parrot_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    create_table :pirate_dated_details do |t|
      # Ensure any attributes added here are added to relevant tests (search for 'catchphrase')
      t.column :pirate_id, :integer
      t.column :start_on, :datetime
      t.column :end_on, :datetime
      t.column :catchphrase, :string
      t.column :ruthlessness, :integer
      t.column :birth_date, :datetime
      t.column :parrot_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

setup_db

class Parrot < ActiveRecord::Base
  has_one :pirate
  
  def ==(other)
    name == other.name
  end
end

class PirateDatedDetail < ActiveRecord::Base
  acts_as_dated_detail
end

class Pirate < ActiveRecord::Base
  belongs_to :parrot
  
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
  
  def create_parrot(time)
    parrot = Parrot.create!(:name => time.to_s)
  end
  
  def create_pirate(times = [Time.now])
    first_time = times.shift
    now = Time.now
    Time.stubs(:now).returns(first_time)
    pirate = Pirate.create!(:name => pirate_name(first_time), :catchphrase => catchphrase(first_time), :ruthlessness => ruthlessness(first_time), :birth_date => first_time, :parrot => create_parrot(first_time))
    times.each do |time|
      Time.stubs(:now).returns(time)
      pirate.update_attributes(:name => pirate_name(time), :catchphrase => catchphrase(time), :ruthlessness => ruthlessness(time), :birth_date => time, :parrot => create_parrot(time))
    end
    # A lot of tests rely on this method stubbing Time.now
    Time.stubs(:now).returns(now)
    pirate
  end
  
  def pirate_name(time)
    time.to_s
  end
  
  def catchphrase(time)
    time.to_s
  end
  
  def ruthlessness(time)
    time.to_i
  end
end

class ParentTest < ActsAsDatedDetailTest
  # Creation
  
  def test_related_dated_detail_created_along_with_model
    pirate = create_pirate
    assert_equal 1, pirate.dated_details.count
  end
  
  # Currently Effective Timestamp
  
  def test_default_value_of_currently_effective_timestamp
    now = Time.now
    pirate = create_pirate([now])
    assert_equal now, pirate.on
  end
  
  def test_setting_value_of_currently_effective_timestamp
    pirate = create_pirate
    one_month_ago = Time.now - 1.month
    pirate.on = one_month_ago
    assert_equal one_month_ago, pirate.on
  end
  
  # Determining if instance is tracking latest history
  
  def test_tracks_latest_history_by_default
    pirate = create_pirate
    assert pirate.current?
  end
  
  def test_does_not_track_latest_history_when_currently_effective_timestamp_set
    [1.day.ago, Time.now].each do |time|
      pirate = create_pirate
      pirate.on = time
      assert !pirate.current?
    end
  end
  
  def test_does_not_track_latest_history_when_currently_effective_timestamp_reset_to_now
    pirate = create_pirate
    pirate.on = 1.day.ago
    pirate.on = Time.now
    assert !pirate.current?
  end
  
  # Forcing instance to track latest history again
  
  def test_tracks_latest_history_again
    pirate = create_pirate([1.year.ago, 6.months.ago, 1.month.ago])
    pirate.on = 6.months.ago
    pirate.current!
    assert pirate.current?
    assert_equal catchphrase(1.month.ago), pirate.catchphrase
  end
  
  # Tracked Attribute Retrieval
  
  def test_tracked_attribute_for_oldest_timestamp_set_by_instance_method
    pirate = create_pirate([1.year.ago, 6.months.ago, 1.month.ago])
    pirate.on = 8.months.ago
    assert_equal catchphrase(1.year.ago), pirate.catchphrase
  end
  
  def test_tracked_attribute_for_middle_timestamp_set_by_instance_method
    pirate = create_pirate([1.year.ago, 6.months.ago, 1.month.ago])
    pirate.on = 5.months.ago
    assert_equal catchphrase(6.months.ago), pirate.catchphrase
  end
  
  def test_tracked_attribute_for_newest_timestamp_set_by_instance_method
    pirate = create_pirate([1.year.ago, 6.months.ago, 1.month.ago])
    pirate.on = 2.weeks.ago
    assert_equal catchphrase(1.month.ago), pirate.catchphrase
  end
  
  # Reloading
  
  def test_reloading_when_tracking_latest_history
    pirate = create_pirate([1.hour.ago])
    same_pirate = Pirate.find(pirate.id)
    new_ruthlessness = 999 #same_pirate.ruthlessness + 1
    same_pirate.update_attribute(:ruthlessness, new_ruthlessness)
    flunk 'Pirate must be tracking latest history' unless pirate.current?
    pirate.reload
    assert_equal new_ruthlessness, pirate.ruthlessness
  end
  
  def test_reloading_when_not_tracking_latest_history
    pirate = create_pirate([6.months.ago, 1.hour.ago])
    pirate.on = 5.months.ago
    ruthlessness = pirate.ruthlessness
    same_pirate = Pirate.find(pirate.id)
    same_pirate.update_attribute(:ruthlessness, same_pirate.ruthlessness + 1)
    flunk 'Pirate must not be tracking latest history' if pirate.current?
    pirate.reload
    assert_equal ruthlessness, pirate.ruthlessness
  end
  
  def test_reloading_returns_self
    # #reload is aliased. Test that it returns correctly
    pirate = create_pirate
    assert_equal pirate, pirate.reload
  end
  
  # Tracked Attribute Methods
  
  def test_read_tracked_attributes
    # Ensure value from dated_detail is returned
    pirate = create_pirate
    dated_detail = pirate.dated_detail
    pirate.stubs(:dated_detail).returns(dated_detail)
    PirateDatedDetail.tracked_attributes.each do |attribute|
      value = 10
      PirateDatedDetail.any_instance.stubs(attribute).returns("Error")
      dated_detail.stubs(attribute).returns(value)
      assert_equal value, pirate.send(attribute)
    end
  end
  
  def test_write_tracked_attributes
    pirate = create_pirate
    PirateDatedDetail.tracked_attributes.each do |attribute|
      value = 10
      pirate.send("#{attribute}=", value)
      assert_equal value, pirate.attributes[attribute]
      assert_equal value, pirate.dated_detail.send(attribute)
    end
  end
  
  # Updating Attributes
  
  def test_updating_tracked_attribute_updates_currently_effective_timestamp
    pirate = create_pirate([1.year.ago])
    pirate.update_attribute(:catchphrase, 'Yar!')
    assert_equal Time.now, pirate.on
  end
  
  def test_updating_tracked_integer_attribute
    pirate = create_pirate([1.year.ago])
    pirate.update_attribute(:ruthlessness, 10)
    assert_equal 2, pirate.dated_details.count
  end
  
  def test_updating_tracked_string_attribute
    pirate = create_pirate([1.year.ago])
    pirate.update_attribute(:catchphrase, 'Yar!')
    assert_equal 2, pirate.dated_details.count
  end
  
  def test_updating_tracked_datetime_attribute
    pirate = create_pirate([1.year.ago])
    pirate.update_attributes(:birth_date => pirate.birth_date + 1.day)
    assert_equal 2, pirate.dated_details.count
  end
  
  def test_updating_tracked_multiparameter_attribute
    pirate = create_pirate([1.year.ago])
    new_birth_date = pirate.birth_date + 1.day
    pirate.update_attributes('birth_date(1i)' => "#{new_birth_date.year}", 'birth_date(2i)' => "#{new_birth_date.month}", 'birth_date(3i)' => "#{new_birth_date.day}")
    assert_equal 2, pirate.dated_details.count
  end
  
  def test_updating_untracked_attribute
    pirate = create_pirate([1.year.ago])
    pirate.update_attribute(:name, 'Long John Silver')
    assert_equal 1, pirate.dated_details.count
  end
end

class DatedDetailTest < ActsAsDatedDetailTest
  def setup
    setup_db
    # create_pirate_with_dated_detail
  end

  def teardown
    teardown_db
  end
  
  # Associations
  
  def test_belongs_to_parent
    assert_equal create_pirate, PirateDatedDetail.first.pirate
  end
  
  # Creation
  
  def test_initial_start_on_value
    pirate = create_pirate
    assert_equal Time.now.to_i, PirateDatedDetail.first.start_on.to_i
  end
  
  def test_initial_end_on_value
    pirate = create_pirate
    assert_nil PirateDatedDetail.first.end_on
  end
  
  # Updating
  
  def test_updating
    pirate = create_pirate([Time.now - 1.year])
    
    dated_detail = pirate.dated_detail
    original_dated_detail = dated_detail.class.find(dated_detail.id) # Cloning would keep millisecond parts of time which would make later comparisons harder
    
    dated_detail.update_attribute(:ruthlessness, 10)
    
    assert_equal Time.now.to_i, dated_detail.start_on.to_i
    assert_nil dated_detail.end_on
    
    previous_dated_detail = PirateDatedDetail.find_by_start_on(original_dated_detail.start_on)
    assert_equal dated_detail.start_on.to_i - 1, previous_dated_detail.end_on.to_i
    assert_equal original_dated_detail.attributes.except('end_on', 'id'), previous_dated_detail.attributes.except('end_on', 'id')
  end
  
  # Tracked Attributes
  
  def test_tracked_attributes_includes_relevant_columns
    assert PirateDatedDetail.tracked_attributes.include?('catchphrase')
    assert PirateDatedDetail.tracked_attributes.include?('ruthlessness')
    assert PirateDatedDetail.tracked_attributes.include?('birth_date')
    assert PirateDatedDetail.tracked_attributes.include?('parrot_id')
  end
  
  def test_tracked_attributes_excludes_id
    assert !PirateDatedDetail.tracked_attributes.include?('id')
  end
  
  def test_tracked_attributes_excludes_start_on
    assert !PirateDatedDetail.tracked_attributes.include?('start_on')
  end
  
  def test_tracked_attributes_excludes_end_on
    assert !PirateDatedDetail.tracked_attributes.include?('end_on')
  end
  
  def test_tracked_attributes_excludes_updated_at
    assert !PirateDatedDetail.tracked_attributes.include?('updated_at')
  end
  
  def test_tracked_attributes_excludes_created_at
    assert !PirateDatedDetail.tracked_attributes.include?('created_at')
  end
  
  def test_tracked_attributes_excludes_parent_id
    assert !PirateDatedDetail.tracked_attributes.include?('pirate_id')
  end
  
  # Dated Detail Retrieval
  
  def test_dated_detail_for_oldest_timestamp_retrieved_via_named_scope
    pirate = create_pirate([1.year.ago, 6.months.ago, 1.month.ago])
    assert_equal catchphrase(1.year.ago), pirate.dated_details.on(8.months.ago).first.catchphrase
  end
  
  def test_tracked_attribute_for_middle_timestamp_retrieved_via_named_scope
    pirate = create_pirate([1.year.ago, 6.months.ago, 1.month.ago])
    assert_equal catchphrase(6.months.ago), pirate.dated_details.on(5.months.ago).first.catchphrase
  end
  
  def test_tracked_attribute_for_newest_timestamp_retrieved_via_named_scope
    pirate = create_pirate([1.year.ago, 6.months.ago, 1.month.ago])
    assert_equal catchphrase(1.month.ago), pirate.dated_details.on(2.weeks.ago).first.catchphrase
  end
end
