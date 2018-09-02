require 'erb'
require 'json'
require_relative 'scripts/create_thumbnail.rb'

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
            parsed["thumbnails"] = {}
            
            if Dir.exist?("resources/projects/" + name + "/screenshots")

                %x( mkdir output/resources/projects/#{name}/screenshots/thumbnails )
                path = "resources/projects/" + name + "/screenshots"
                Dir.foreach(path) do |item|
                    
                    next if item == '.' or item == '..' or item[0] == "."
                    
                    screenshot_path = "/" + path + "/" + item
                    thumbnail_path = "/" + path + "/" + item
                    createThumbnail(path, item)
                    parsed["screenshots"] << screenshot_path
                    parsed["thumbnails"][screenshot_path] = thumbnail_path
                end
            end
            
        end
    end
    
    def get_binding
        return binding()
    end
end

puts "Generating site"

if not Dir.exist?("temp")
    %x( mkdir temp )
end

%x( rm -rf output/*)
%x( mkdir output/projects/ )
%x( cp -r resources/ output/resources )

data = PageData.new
binding = data.get_binding

Dir.foreach('templates/core') do |item|
    next if item == '.' or item == '..' or item[0,1] == '.'
    template = File.read("templates/core/" + item)
    output = ERB.new(template).result(binding)
    
    place = ""
    if item != "home.html"
        name = item.split(".")[0]
        if not Dir.exist?("output/#{name}")
            %x( mkdir output/#{name} )
        end
        place = name + "/"
    end
        
    File.write("output/#{place}index.html", output)
end

data.data["projects"].each do |index, project|
    data.project = data.data["projects"][index]
    template = File.read("templates/projects/" + project["template"])
    output = ERB.new(template).result(binding)
    %x( mkdir output/projects/#{index} )
    File.write("output/projects/" + index + "/index.html", output)
end

%x( cp style.css output/style.css )
%x( rm -rf temp )

puts "Finished generating site"
