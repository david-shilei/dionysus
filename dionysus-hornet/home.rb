require 'sinatra'
require 'active_record'
require 'mysql2'
gem 'mysql2'
load 'beverage.rb'
load 'region.rb'
load 'winery.rb'



get '/hi' do
ActiveRecord::Base.establish_connection ({
	  :adapter => "mysql2",
	  :host => "localhost",
	  :username => "root",
	  :password => "welcome1",
	  :database => "dionysus"})

	"Wineries: #{Winery.all.size}    Regions: #{Region.all.size}"
end