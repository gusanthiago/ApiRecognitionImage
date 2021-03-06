require 'google/cloud/vision'
require 'open-uri'

class ImageController < ApplicationController

	def create
		response = {
			success: 1,
			urlOrigin: request[:urlImage].to_s.delete(' '), 
			pathFile: '',
			vision: []
		}
		if response[:urlOrigin].to_s.empty?
			response[:success] = 0
			render :json => response
		else
			response[:pathFile] = request_save(response[:urlOrigin])
			render :json => filterProperties(response)
		end 
	end

	def request_save(image_data)
		size = image_data.length	
		extension = image_data[size-4...size]
		folderImage = 'images_request/' + rand_hash() + extension
		folderSave = 'public/' + folderImage
		loop do
			break if File.exists?(folderSave) != true
			folderImage = '/images_request/' + rand_hash() + extension	
		end
		begin
			open(folderSave, 'wb') do |file|
			  file << open(image_data).read
			end
		rescue OpenURI::HTTPError => ex
			folderImage = ''
			puts 'ERROR REQUEST '+ex
		end
		folderImage
	end

	def rand_hash()
		Random.new_seed.to_s + (0...8).map { (65 + rand(26)).chr }.join
	end

	def filterProperties(response)
		cloud_vision = {
			web: [],
			labels: []
			# text: "" # TODO text in cloud vision
		}
		vision = Google::Cloud::Vision.new project: ENV.fetch('GOOGLE_CLOUD_PROJECT')
		image = vision.image "public/" + response[:pathFile]
		
		image.web.entities.each do |entity|
			cloud_vision[:web] << {description: entity.description, score: entity.score}
		end
		image.labels.each do |label|
			cloud_vision[:labels] << {description: label.description, score: label.score}
		end
		# cloud_vision[:text] = image.document.text # TODO text in cloud vision
		
		response[:vision] = cloud_vision
		response
	end

end
