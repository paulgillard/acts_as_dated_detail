module ActiveRecord
  module Acts #:nodoc:
    module DatedDetail #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_dated_detail()
          class_eval <<-EOV
            def self.tracked_attributes
              columns_hash.keys - ['id', 'parent_id', 'start_on', 'end_on', 'created_at', 'updated_at']
            end

            belongs_to :parent, :class_name => "#{self.name.sub(/DatedDetail$/, '')}"

            include ActiveRecord::Acts::DatedDetail::InstanceMethods
          EOV
        end
      end

      module InstanceMethods
        def initialize(attributes)
          super
          self.start_on = Time.now
        end
      end
    end
  end
end
