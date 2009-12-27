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
              columns_hash.keys - ['id', 'parent_id', 'created_at', 'updated_at']
            end

            belongs_to :parent, :class_name => "#{self.name.sub(/DatedDetail$/, '')}"

            include ActiveRecord::Acts::DatedDetail::InstanceMethods
          EOV
        end
      end

      module InstanceMethods
      end
    end
  end
end
