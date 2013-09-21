class Winery < ActiveRecord::Base
	has_many :wine
	has_many :varietals
	has_many :grapes, through: :varietals	
	belongs_to :region
end