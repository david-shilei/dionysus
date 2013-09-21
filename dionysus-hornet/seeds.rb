load 'snooth_hornet.rb'
load 'numeric_duration.rb'

if ARGV.empty? || ARGV.length > 1
  p 'use -reset or -new'
  exit
end

case ARGV[0]
when '-reset'
  load 'schema.rb'
when '-new'    
  start = Time.now  
  SnoothHornet.connect_db
  # SnoothHornet.harvest_grapes
  # SnoothHornet.harvest_regions_and_wineries
  SnoothHornet.harvest_wines
  # winery = Winery.where(name: "Obikwa").first
  # SnoothHornet.process_winery(winery)  
  p "Took #{(Time.now - start).duration}"
end
