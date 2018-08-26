def createThumbnail(path, image)
    
    temp_path = "temp/temp"
    image_path = path + "/" + image
    output_path = "output/" + path + "/thumbnails/" + image
    
    %x( magick #{image_path} -resize '230' #{temp_path} )
    %x( magick #{temp_path} -crop '230x160+0+0' -gravity center #{temp_path} )
    %x( mv #{temp_path} #{output_path} )
end
