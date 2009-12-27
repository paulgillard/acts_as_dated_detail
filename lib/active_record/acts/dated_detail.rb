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
              @tracked_attributes ||= columns_hash.keys - ["id", "start_on", "end_on", "updated_at", "created_at", "#{self.to_s.underscore.sub(/dated_detail$/, 'id')}"]
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
