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
          tracked_attribute_writer_methods = ''
          acts_as_dated_detail_class.tracked_attributes.each do |attribute|
            tracked_attribute_reader_methods << %(
              def #{attribute}
                dated_detail.send('#{attribute}')
              end
            )
            tracked_attribute_writer_methods << %(
              def #{attribute}=(value)
                write_attribute('#{attribute}', value)
                dated_detail.send('#{attribute}=', value)
              end
            )
          end
          
          class_eval <<-EOV
            after_save :save_dated_detail

            has_many :dated_details, :class_name => "#{acts_as_dated_detail_class.to_s}"

            #{tracked_attribute_reader_methods}
            #{tracked_attribute_writer_methods}

            include ActiveRecord::Acts::Dated::InstanceMethods
            
            alias_method_chain :reload, :dated_detail
            
#            def self.columns
#              tracked_columns_hash = #{acts_as_dated_detail_class.to_s}.columns_hash.slice(*#{acts_as_dated_detail_class.to_s}.tracked_attributes)
#              @columns ||= tracked_columns_hash.inject(super.columns) do |columns, (key, value)|
#                columns << value
#              end
#              @columns
#            end
          EOV
        end
      end
      
      module InstanceMethods
        
        
        def on
          @time ||= Time.now
        end
        
        def on=(time)
          @time = time
          @fixed_time = true
          @dated_detail = nil
        end
        
        def dated_detail
          @dated_detail ||= dated_details.on(on).first || dated_details.build
        end
        
        def current?
          !@fixed_time
        end
        
        def current!
          @fixed_time = false
          @dated_detail = nil
          @time = nil
        end
        
        def reload_with_dated_detail
          reload_without_dated_detail
          if current?
            @dated_detail = nil
            @time = nil
          end
        end
        
        private
        
        def save_dated_detail
          dated_detail.save!
          @time = dated_detail.start_on
        end
      end
    end
  end
end
