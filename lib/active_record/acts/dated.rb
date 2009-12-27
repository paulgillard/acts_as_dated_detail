module ActiveRecord
  module Acts #:nodoc:
    module Dated #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_dated(options = {})
          acts_as_dated_detail_class = "#{self.name}DatedDetail".constantize
          
          tracked_attribute_reader_methods = ''
          # tracked_attribute_writer_methods = ''
          acts_as_dated_detail_class.tracked_attributes.each do |attribute|
            tracked_attribute_reader_methods << %(
              def #{attribute}
                dated_detail.send('#{attribute}')
              end
            )
          #   tracked_attribute_writer_methods << %(
          #     def #{attribute}=(value)
          #       detail.send('#{attribute}=', value)
          #     end
          #   )
          end
          
          class_eval <<-EOV
            after_save :create_dated_detail

            has_many :dated_details, :class_name => "#{acts_as_dated_detail_class.to_s}", :foreign_key => 'parent_id'

            #{tracked_attribute_reader_methods}

            include ActiveRecord::Acts::Dated::InstanceMethods
          EOV
        end
      end
      
      module InstanceMethods
        def dated_detail
          dated_details.first
        end
        
        private
        
        def create_dated_detail
          dated_details.create!
        end
      end
    end
  end
end
