class Grape < ActiveRecord::Base
	has_many :varietals
	has_many :wineries, through: :varietals
end