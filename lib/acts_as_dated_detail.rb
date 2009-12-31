$:.unshift "#{File.dirname(__FILE__)}"
require 'active_record/acts/dated'
require 'active_record/acts/dated_detail'
ActiveRecord::Base.class_eval { include ActiveRecord::Acts::DatedDetail }
ActiveRecord::Base.class_eval { include ActiveRecord::Acts::Dated }
