class Region < ActiveRecord::Base
	belongs_to :parent, :class_name => 'Region'
	has_many :wineries
end
