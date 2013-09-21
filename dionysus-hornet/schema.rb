require 'mysql2'
gem 'mysql2'

ActiveRecord::Base.establish_connection ({
  :adapter => "mysql2",
  :host => "localhost",
  :username => "root",
  :password => "welcome1",
  :database => "dionysus"})

ActiveRecord::Schema.define(:version => 20130905115701) do  
  create_table "wines", force: true do |t|
    t.string "name"
    t.string "type"
    t.string "winery_id"
    t.text "pic_url"
    t.text "hornet_url"
  end

  create_table "regions", force: true do |t|
    t.string "name"    
    t.integer "parent_id"    
  end

  create_table "wineries", force: true do |t|
    t.string "name"    
    t.integer "region_id"
    t.string "address"
    t.text "description"
    t.text "hornet_url"
  end

  create_table "grapes", force: true do |t|
    t.string "name"
    t.text "description"
    t.text "pic_url"
  end

  create_table "varietals", force: true do |t|
    t.string "grape_id"
    t.text "winery_id"    
  end
end