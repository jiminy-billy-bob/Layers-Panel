
module JBB_LayersPanel

	
	
	def self.jsonToHash(string)
		hashString = eval( string.inspect.gsub(':','=>') ) #Convert Json string to hash string
		hash = eval(hashString) #Convert hash string to proper hash object
		return hash
	end#def
	
	def self.showDialog(dialog)
		if MAC
			dialog.show_modal()
		else
			dialog.show()
		end#if
	end#def
	
	def self.resetVariables
		@model = Sketchup.active_model
		@layers = @model.layers
		@layerDictID = @model.get_attribute("jbb_layerspanel", "layerDictID")
	end#def

	class WebdialogBridge < UI::WebDialog
		def add_bridge_callback(callback, &block)
			add_action_callback(callback) do  |webdialog, params|
				# puts "add_bridge_callback(#{callback}) { |#{params}| }"
				block.call(webdialog, params)
				execute_script('skpCallbackReceived();')
			end
		end
	end # WebdialogBridge
	
	def self.currentContext
		if @model.pages.selected_page == nil
			return @model
		else
			return @model.pages.selected_page
		end#if
	end#def
	
	
	### LAYER SERIALIZE ### ------------------------------------------------------
	
	def self.incLayerDictID
		@layerDictID = @layerDictID + 1
		@model.set_attribute("jbb_layerspanel", "layerDictID", @layerDictID) #Store incremented layerDictID in model attribute dict
		# puts "incLayerDictID"
	end#def
	
	def self.initializeLayerDictID
		if @layerDictID == nil
			if @model.get_attribute("jbb_layerspanel", "layerDictID") != nil #Get layerDictID from model if exists
				@layerDictID = @model.get_attribute("jbb_layerspanel", "layerDictID")
			else #Else, create it
				@layers[0].set_attribute("jbb_layerspanel", "ID", 0) #Give Layer0 ID 0
				@layerDictID = 0
			end#if
			self.incLayerDictID
		end#if
	end#def
	
	def self.IDLayer(layer) #Give a unique custom id to a layer
		if layer.get_attribute("jbb_layerspanel", "ID") != nil 
			#puts layer.name + " already IDed " + layer.get_attribute("jbb_layerspanel", "ID").to_s
		else
			self.incLayerDictID
			layer.set_attribute("jbb_layerspanel", "ID", @layerDictID)
			# puts "layerDictID " + @layerDictID.to_s
		end#if
	end#def
	
	def self.checkEntityObserver(layer) #check if layer has observer, else attach to it
		if @entityObservers[layer.entityID] != true
			@entityObservers[layer.entityID] = true
			layer.add_observer(@jbb_lp_entityObserver)
			# puts layer.name
		end#if
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
		@model.commit_operation 
	end#def
	
	
	### API ### ------------------------------------------------------
	
	def self.getLayerByID(layerID)
		@layers.each{|layer| 
			if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i #if layer's dict ID == match ID
				return layer
				break
			end#if
		}
	end#def
	
	def self.getLayerID(layer)
		return layer.get_attribute("jbb_layerspanel", "ID").to_i
	end#def
	
	def self.render?(layer)
		layerID = layer.get_attribute("jbb_layerspanel", "ID")
		context = self.currentContext
		if context.get_attribute("jbb_layerspanel_render", layerID) == 0
			return false
		elsif context.get_attribute("jbb_layerspanel_render", layerID) == 1
			return false
		else
			return true
		end#if
	end#def
	
	def self.setRenderBehav(layer, bool)
		layerID = layer.get_attribute("jbb_layerspanel", "ID")
		context = self.currentContext
		if bool == false
			context.set_attribute("jbb_layerspanel_render", layerID, 0)
		else
			context.set_attribute("jbb_layerspanel_render", layerID, 2)
		end#if
		self.refreshDialog
	end#def

end#module