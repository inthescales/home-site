require 'erb'
require 'json'

def createThumbnail(path, image)
    
    imagePath = path + "/" + image
    
    %x( magick #{imagePath} -resize '230' temp )
    %x( magick temp -crop '230x160+0+0' -gravity center temp )
    %x( mv temp output/#{path}/thumbnails/#{image} )
end

class PageData
    
    attr_accessor :blocks, :data, :project
    
    def initialize
        @blocks = {}
        @data = {}
        
        read_blocks
        read_data
    end
    
    def read_blocks
        
        Dir.foreach('blocks') do |item|
            next if item == '.' or item == '..'
            name = item.split(".")[0]
            contents = File.read("blocks/" + item)
            @blocks[name] = contents
        end
    end
    
    def read_data
        data["projects"] = {}
        Dir.foreach('data/projects') do |item|
            next if item == '.' or item == '..' or not File.directory?('data/projects/' + item)

            name = item            
            meta = File.read("data/projects/" + name + "/meta.json")
            parsed = JSON.parse(meta)
            @data["projects"][name] = parsed
            
            body = File.read('data/projects/' + name + '/body.html') 
            parsed["body"] = body
            
            parsed["screenshots"] = []
            if Dir.exist?("resources/projects/" + name + "/screenshots")
                %x( mkdir resources/projects/#{name}/screenshots/thumbnails )
                Dir.foreach("resources/projects/" + name + "/screenshots") do |item|
                    next if item == '.' or item == '..' or item[0] == "."
                    path = "resources/projects/" + name + "/screenshots"
                    createThumbnail(path, item)
                    parsed["screenshots"] << "/resources/projects/" + name + "/screenshots/" + item
                end
            end
            
        end
    end
    
    def get_binding
        return binding()
    end
end

data = PageData.new
binding = data.get_binding

%x( rm -r output/*)

Dir.foreach('templates/core') do |item|
    next if item == '.' or item == '..'
    template = File.read("templates/core/" + item)
    output = ERB.new(template).result(binding)
    File.write("output/" + item, output)
end

%x( mkdir output/projects/ )

data.data["projects"].each do |index, project|
    data.project = data.data["projects"][index]
    template = File.read("templates/projects/" + project["template"])
    output = ERB.new(template).result(binding)
    File.write("output/projects/" + index + ".html", output)
end

%x( cp style.css output/style.css )
%x( cp -r resources/ output/resources )
