require 'nokogiri'
require 'mechanize'
require 'open-uri'
require 'active_record'
require 'mysql2'
gem 'mysql2'
load 'models/grape.rb'
load 'models/winery.rb'

ActiveRecord::Base.establish_connection ({
  :adapter => "mysql2",
  :host => "localhost",
  :username => "root",
  :password => "welcome1",
  :database => "dionysus"})

p Winery.all.size
