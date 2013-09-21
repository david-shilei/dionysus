require 'nokogiri'
require 'mechanize'
require 'open-uri'
require 'active_record'
load 'models/region.rb'
load 'models/winery.rb'
load 'models/grape.rb'
load 'models/varietal.rb'
load 'models/wine.rb'

class SnoothHornet
    def self.connect_db        
        ActiveRecord::Base.establish_connection ({
            :adapter => "mysql2",
            :host => "localhost",
            :username => "root",
            :password => "welcome1",
            :database => "dionysus"})
        ActiveRecord::Base.connection.execute "SET collation_connection = 'utf8_general_ci' "
    end 

    def self.process_regions_on(region_page, parent)
        region_page.css(".directory.regions li a").each do |region_link|
            region_name = region_link.text.gsub(/ (.*)/, '')
            begin
                unless Region.exists?(name: region_name)
                    region = Region.new  
                    region.name = region_name
                    region.parent = parent if parent.present?
                    region.save  
                    p "Add region " + region.id.to_s + " " + region.name        
                    process_wineries_on(region_page, region)                
                    
                    sub_region_page = Nokogiri::HTML(open(region_link["href"]))
                    process_regions_on(sub_region_page, region)
                end          
            rescue
                p "Error when adding region #{region_name}"
            end           
        end    
    end

    def self.harvest_regions_and_wineries()        
        page = Nokogiri::HTML(open("http://www.snooth.com/winery/"))
        p page.title
        process_regions_on(page, nil)
    end

    def self.add_winery(name, region, url)        
        begin
            unless Winery.exists?(name: name)                            
                winery = Winery.new
                winery.name = name
                winery.region = region
                winery.hornet_url = url
                winery.save
                p "Add winery: #{name}"
            end
        rescue => detail
           p "Error when adding winery #{name} of region #{region.name}"
           p detail.backtrace.join('\n')
        end        
    end    

    def self.process_wineries_on(region_page, region)    
        [".directory.feature li a", ".directory.popular-wineries li a", ".directory.all-wineries li a"].each do |selector|
            region_page.css(selector).each do |winery_link|
                add_winery(winery_link.text, region, winery_link["href"])
            end
        end
    end

    def self.harvest_grapes        
        a = Mechanize.new
        ["A-B", "C-D", "E-G", "H-J", "K-M", "N-P", "Q-S", "T-V", "W-Z"].each do |range|
            a.get("http://www.snooth.com/varietal/" + range)                
            a.page.parser.css(".title").each do |grape_link|
                name = grape_link.text                
                if name.present? && !Grape.exists?(name: name)
                    a.get(grape_link["href"]) do |grape_page|
                        begin                                                
                            grape = Grape.new
                            grape.name = name
                            img = grape_page.parser.css(".group-img img")[0]
                            grape.pic_url = img["src"] if img.present?
                            desc_link = grape_page.at(".description_morelink a")
                            if desc_link.present?                            
                                a.click(desc_link)
                                desc_arr = a.page.parser.at(".group-description").search("p").map(&:text)
                                desc_arr.each do |desc|
                                    desc.gsub!("Back to top", '')
                                    desc.gsub!("(view original content)", '')
                                    desc.gsub!("\n", '')                                
                                end
                                desc_arr.each(&:strip!)
                                grape.description = desc_arr.join("\n")                            
                            end    
                            saved = grape.save
                            if saved
                                p "Grape: #{grape.name}"
                                p grape.description if grape.description.present?
                                p grape.pic_url if grape.pic_url.present?
                            end                                                        
                        rescue => detail
                            p "Error when adding grape #{name}"
                            p detail.backtrace.join('\n')
                        end
                    end    
                end                
            end
        end        
    end

    def self.process_winery(winery)
        p "opening winery at #{winery.hornet_url}"  
        page = Nokogiri::HTML(open(winery.hornet_url))        

        desc_p = page.at("#g_desccont p")
        if desc_p.present?
            winery.description = desc_p.text
            p winery.description unless winery.description.blank?
        end            

        address_span = page.at("#g_addresscont")
        if address_span.present?
            winery.address = address_span.text
            p winery.address unless winery.address.blank?
        end
        
        desc_p = page.at("#g_desccont p")
        if desc_p.present?
            winery.description = desc_p.text
            p winery.description unless winery.description.blank?
        end

        grapes = []
        page.css(".groups-grapes .title a").each do |grape_link|
            grape_name = grape_link.text
            grape = Grape.where(name: grape_name).first
            grapes << grape
        end       
        unless grapes.empty?
            winery.grapes = grapes
            p "Varietals: #{grapes.map(&:name).join(' ')}"
        end

        winery.save if winery.changed?    

        agent = Mechanize.new        
        self.process_wines_from(agent, winery.hornet_url)        
    end    

    def self.process_wine_on(page)        
        page.parser.css(".result-items .item").each do |wine_div|
            wine = Wine.new
            wine.name = wine_div.at(".wine-name").text.gsub("\n", '').strip
            wine_div.css(".wine-details .row").each do |detail_row|
                field = detail_row.at(".row-left").text
                value = detail_row.at(".row-right").text.gsub("\n", '').strip
                case field
                when "Winery:"
                    wine.winery = Winery.where(name: value).first
                when "Type:"
                    wine.type = value
                end     
            end
            # wine.pic_url = wine_div.at(".wine-image img")["src"]
            # wine.hornet_url = wine.name = wine_div.at(".wine-name a")["href"]
            
            p "Add wine: #{wine.name} #{wine.type} from #{wine.winery.name}"
            wine.save
        end
    end

    def self.process_wines_from(agent, url)            
        agent.get(url)       
        wines_link = agent.page.at("#wine-search-link")
        if wines_link
            agent.click(wines_link)                

            process_wine_on(agent.page)

            more_links = agent.page.parser.css(".search-results .pagination a").select{|link| !link['class'].include?("current-page")}        
            more_links.each do |link|
                agent.click(link)
                process_wine_on(agent.page)
            end
        end    
    end

    def self.harvest_wines
        agent = Mechanize.new        
        Winery.all.each do |winery|
            p "process wines from winery: #{winery.name} at #{winery.hornet_url}"
            process_wines_from(agent, winery.hornet_url)
        end
    end
end
