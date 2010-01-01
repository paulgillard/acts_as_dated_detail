module ActiveRecord
  module Acts #:nodoc:
    module DatedDetail #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_dated_detail()
          class_eval <<-EOV
            belongs_to :#{self.name.underscore.sub(/_dated_detail$/, '')}

            before_update :split!

            named_scope :on, lambda { |time| { :conditions => "\#{start_on_or_before_condition(time)} AND \#{end_on_or_after_condition(time)}" } }

            def self.tracked_attributes
              columns_hash.keys - ['id', "#{self.name.underscore.sub(/dated_detail$/, 'id')}", 'start_on', 'end_on', 'created_at', 'updated_at']
            end

            include ActiveRecord::Acts::DatedDetail::InstanceMethods

            private

            # Find all records starting on or before given time
            def self.start_on_or_before_condition(time)
              "(start_on <= '\#{time.to_s :db}')"
            end

            # Find all records ending on or after given time
            def self.end_on_or_after_condition(time)
              "(end_on IS NULL OR end_on >= '\#{time.to_s :db}')"
            end
          EOV
        end
      end

      module InstanceMethods
        def initialize(*args)
          super
          self.start_on = Time.now
        end
        
        def split!
          if changed?
            self.start_on = Time.now
            original = self.class.find(id).clone
            original.end_on = start_on - 1
            original.save!
          end
        end
      end
    end
  end
end
