module ActiveRecord
  module Acts #:nodoc:
    module DatedDetail #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_dated_detail()
          class_eval <<-EOV
#            belongs_to :parent, :class_name => "#{self.name.sub(/DatedDetail$/, '')}"

            before_update :split!

            def self.tracked_attributes
              columns_hash.keys - ['id', 'parent_id', 'start_on', 'end_on', 'created_at', 'updated_at']
            end

            include ActiveRecord::Acts::DatedDetail::InstanceMethods
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
