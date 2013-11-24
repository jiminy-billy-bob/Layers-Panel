
module JBB_LayersPanel

	
	
	def self.jsonToHash(string)
		hashString = eval( string.inspect.gsub(':','=>') ) #Convert Json string to hash string
		hash = eval(hashString) #Convert hash string to proper hash object
		return hash
	end#def
	
	
	### LAYER SERIALIZE ### ------------------------------------------------------
	
	def self.incLayerDictID
		@model.start_operation("Layers Panel", true, false, true)
		@layerDictID = @layerDictID + 1
		@model.set_attribute("jbb_layerspanel", "layerDictID", @layerDictID) #Store incremented layerDictID in model attribute dict
		# puts "incLayerDictID"
		@model.commit_operation
	end#def
	
	def self.initializeLayerDictID
		if @layerDictID == nil
			@model.start_operation("Initialize Layers Panel", true, false, true)
			if @model.get_attribute("jbb_layerspanel", "layerDictID") != nil #Get layerDictID from model if exists
				@layerDictID = @model.get_attribute("jbb_layerspanel", "layerDictID")
			else #Else, create it
				@layers[0].set_attribute("jbb_layerspanel", "ID", 0) #Give Layer0 ID 0
				@layerDictID = 0
			end#if
			self.incLayerDictID
			@model.commit_operation 
			# puts "Current layerDictID : " + @layerDictID.to_s
		end#if
	end#def
	
	def self.IdLayer(layer) #Give a unique custom id to a layer
		# begin
			if layer.get_attribute("jbb_layerspanel", "ID") != nil 
				#puts layer.name + " already IDed " + layer.get_attribute("jbb_layerspanel", "ID").to_s
			else
				@model.start_operation("ID layer", true, false, true)
				layer.set_attribute("jbb_layerspanel", "ID", @layerDictID)
				# puts "layerDictID " + @layerDictID.to_s
				self.incLayerDictID
				@model.commit_operation 
			end#if
		# rescue
		# end
	end#def
	
	
	### LAYER DELETE METHOD ### ------------------------------------------------------
	#Simple modification of TIG's snippet delete-layer.rb
	#Basically, move or delete layer content, then creates an entry for every layer except one to delete, then purge layers, then delete entries
	
	def self.deleteLayer(layer, delete_geometry=false, currentLayer=false)
		@model.start_operation("Delete layer", true)
		@allowSerialize = false
		ents=@model.entities; defs=@model.definitions
		if delete_geometry
			allents=[]
			@model.entities.each{|e|allents<<e if e.valid? and e.respond_to?(:layer)and e.layer==layer}
			@model.definitions.each{|d|d.entities.each{|e|allents<<e if e.valid? and e.respond_to?(:layer)and e.layer==layer}}
			allents.each{|e|e.erase! if e.valid?}
		elsif currentLayer ### move geom to current layer etc
			@model.entities.each{|e|e.layer=@model.active_layer if e.respond_to?(:layer)and e.layer==layer}
			@model.definitions.each{|d|d.entities.each{|e|e.layer=@model.active_layer if e.respond_to?(:layer)and e.layer==layer}}
		else ### move geom to Layer0 etc
			@model.entities.each{|e|e.layer=nil if e.respond_to?(:layer)and e.layer==layer}
			@model.definitions.each{|d|d.entities.each{|e|e.layer=nil if e.respond_to?(:layer)and e.layer==layer}}
		end#if
		group=@model.entities.add_group();gents=group.entities ### temporarily use other layers
		temp=gents.add_group()
		temp.layer=nil
		if @model.active_layer==layer ### ensure layer is not current layer
			@model.active_layer=nil 
		end#if
		(@layers.to_a-[layer]).each{|layer|tc=temp.copy;tc.layer=layer}
		@layers.purge_unused ### purge layer from browser
		group.erase! ### erase! the temporary layer user, use set as was.
		@allowSerialize = true
		@dialog.execute_script("storeSerialize();")
		@model.commit_operation 
	end#def


end#module