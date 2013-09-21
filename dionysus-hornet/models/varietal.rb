class Varietal < ActiveRecord::Base
	belongs_to :grape
	belongs_to :winery
end