
module JBB_LayersPanel

	
	
	def self.set_attribute(target, name, key, value)
		if key && key != ""
			target.set_attribute(name, key, value)
		else
			puts "Attribute key is empty - Name : " + name + " - value : " + value.to_s
		end#if
	end#def
	
	def self.jsonToHash(string)
		string = string.to_s.gsub('/',"\\").gsub('\\\\',"\\") #This is for unicode values
		hashString = eval( string.inspect.gsub(':','=>') ) #Convert Json string to hash string
		hash = eval(hashString) #Convert hash string to proper hash object
		return hash
	end#def
	
	def self.showDialog(dialog, mainDialog = false)
		if OSX
			dialog.show_modal()
			if mainDialog
				width = Sketchup.read_default("jbb_layers_panel", "dialog_width")
				height = Sketchup.read_default("jbb_layers_panel", "dialog_height")
				width = 215 if width == nil
				height = 300 if height == nil
				dialog.set_size(width,height)
				
				x = Sketchup.read_default("jbb_layers_panel", "dialog_x")
				y = Sketchup.read_default("jbb_layers_panel", "dialog_y")
				x = 300 if x == nil
				y = 200 if y == nil
				dialog.set_position(x,y)
			end#if
		else
			dialog.show()
		end#if
		SCFapi.store_event(@scfKey, 'Layers_Panel', 'Dialog', 'Open') if @scfApi
	end#def
	
	def self.resetVariables
		@model = Sketchup.active_model
		@layers = @model.layers
		@layerDictID = @model.get_attribute("jbb_layerspanel", "layerDictID")
	end#def

	class WebdialogBridge < UI::WebDialog
		def add_bridge_callback(callback, &block)
			add_action_callback(callback) do  |webdialog, params|
				if callback != "startup" &&  callback != "useRenderEngine" &&  callback != "getCollapsedGroups"
					JBB_LayersPanel.empty_layers_to_id_stack
					# puts callback
				end#if
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
		self.set_attribute(@model, "jbb_layerspanel", "layerDictID", @layerDictID) #Store incremented layerDictID in model attribute dict
		# puts "incLayerDictID"
	end#def
	
	def self.initializeLayerDictID
		if @layerDictID == nil
			if @model.get_attribute("jbb_layerspanel", "layerDictID") != nil #Get layerDictID from model if exists
				@layerDictID = @model.get_attribute("jbb_layerspanel", "layerDictID")
			else #Else, create it
				layer0 = @layers[0]
				layer0.set_attribute("jbb_layerspanel", "ID", 0) if !layer0.deleted? #Give Layer0 ID 0
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
			self.set_attribute(layer, "jbb_layerspanel", "ID", @layerDictID)
			# puts "layerDictID " + @layerDictID.to_s
		end#if
	end#def
	
	def self.empty_layers_to_id_stack
		@model.start_operation("Layers Panel ID", true)
			self.initializeLayerDictID
			@layer_to_ID.each{|layer|
				self.IDLayer(layer) if !layer.deleted?
			}
			@layer_to_ID = []
		@model.commit_operation
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
	
	def self.deleteLayer(layer, delete_geometry=false, currentLayer=false, operation=true)
		@model.start_operation("Delete layer", true) if operation
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
		@model.commit_operation if operation
	end#def
	
	
	### API ### ------------------------------------------------------
	
	def self.is_active?
		return true
	end#def
	
	def self.add_group(groupName = nil)
		if groupName == nil
			highestNumber = 0
			if @model.attribute_dictionaries["jbb_layerspanel_groups"] != nil
				@model.attribute_dictionaries["jbb_layerspanel_groups"].each { | groupID, name |
					number = (/Group\s(\d+)/).match(name)
					number = number.captures[0].to_i if number != nil
					highestNumber = number if number > highestNumber
				}
			end#if
			highestNumber = highestNumber + 1
			groupName = 'Group ' + highestNumber.to_s
		end#if
		
		self.initializeLayerDictID
		self.incLayerDictID
		self.set_attribute(@model, "jbb_layerspanel_groups", @layerDictID, groupName) #Store group's name with ID
		
		serialized = @model.get_attribute("jbb_layerspanel", "serialized")
		serialized = "" if serialized == nil
		serialized = serialized + 'group[' + @layerDictID.to_s + ']=null'
		self.set_attribute(@model, "jbb_layerspanel", "serialized", serialized)
		
		self.refreshDialog
		@dialogStates.execute_script("visibilityChanged();") if @dialogStates != nil
		@previousState = 0
		
		return @layerDictID
	end#def
	
	def self.delete_group(groupID)
		state = false
		serialized = @model.get_attribute("jbb_layerspanel", "serialized").to_s
		serialized.gsub!(/group\[#{groupID}\]\=(\d+|null)/) { |match| 
			state = true if match
			'' 
		}
		#Get rid of extra "&" (At the start/end of the string, or when there's two of them)
		serialized.gsub!(/\A(&)/) { |match| 
			''
		}
		serialized.gsub!(/(&)\z/) { |match| 
			''
		}
		serialized.gsub!(/&{2}/) { |match| 
			'&'
		}
		#Remove groupID as parent from other items
		serialized.gsub!(/(layer|group)\[\d+\]\=#{groupID}/) { |match| 
			match.gsub!(/\=#{groupID}/) { |match| '=null' } 
		}
		self.set_attribute(@model, "jbb_layerspanel", "serialized", serialized)
		self.refreshDialog
		return state
	end#def
	
	def self.rename_group(groupID, groupName)
		self.set_attribute(@model, "jbb_layerspanel_groups", groupID, groupName.to_s)
		self.refreshDialog
		return true
	end#def
	
	def self.collapse_group(groupID, all_scenes = true)
		self.set_attribute(@model, "jbb_layerspanel_collapseGroups", groupID, 1)
		if @model.pages.length > 0
			if all_scenes
				@model.pages.each{|page|
					self.set_attribute(page, "jbb_layerspanel_collapseGroups", groupID, 1)
				}
			else
				self.set_attribute(@model.pages.selected_page, "jbb_layerspanel_collapseGroups", groupID, 1)
			end#if
		end#if
		@dialogStates.execute_script("visibilityChanged();") if @dialogStates != nil
		@previousState = 0
		self.refreshDialog
	end#def
	
	def self.get_layer_by_ID(layerID)
		@layers.each{|layer| 
			if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i #if layer's dict ID == match ID
				return layer
				break
			end#if
		}
		return nil
	end#def
	
	def self.get_layerID(layer)
		return layer.get_attribute("jbb_layerspanel", "ID").to_i
	end#def
	
	def self.get_groupID_by_name(groupName)
		ids = []
		if @model.attribute_dictionaries["jbb_layerspanel_groups"] != nil
			@model.attribute_dictionaries["jbb_layerspanel_groups"].each { | groupID, name |
				if groupName == name
					ids << groupID.to_i
				end#if
			}
			if ids.length > 1
				return ids
			else
				return ids[0]
			end#if
		end#if
		return nil
	end#def
	
	def self.get_group_name_by_ID(groupID)
		return @model.get_attribute("jbb_layerspanel_groups", groupID)
	end#def
	
	def self.nest_into(itemID, targetID)
		item = target = nil
		if itemID != targetID
			serialized = @model.get_attribute("jbb_layerspanel", "serialized") #retreive string of serialized layers
			target = (/(layer|group)\[#{targetID}\]\=(\d+|null)/).match(serialized) #Check that target exists
			if target
				serialized.to_s.gsub!(/(layer|group)\[#{itemID}\]\=(\d+|null)/) { |match| 
					item = match
					match.gsub!(/\=(\d+|null)/) { |m| '=' + targetID.to_s } #Replace item parent by target
				}
				self.set_attribute(@model, "jbb_layerspanel", "serialized", serialized)
				self.move_nextTo(itemID, targetID, "after", false)
				self.refreshDialog
			end#if
		end#if
		
		if target && item && itemID != targetID
			return true
		else
			return false
		end#if
	end#def
	
	def self.move_before(itemID, targetID)
		self.move_nextTo(itemID, targetID, "before")
	end#def
	
	def self.move_after(itemID, targetID)
		self.move_nextTo(itemID, targetID, "after")
	end#def
	
	def self.move_nextTo(itemID, targetID, side, replaceParent = true)
		if itemID != targetID
			serialized = @model.get_attribute("jbb_layerspanel", "serialized") #retreive string of serialized layers
			item = target = parent = nil
			#Check that target exists
			target = (/(layer|group)\[#{targetID}\]\=(\d+|null)/).match(serialized)
			parent = target.captures[1] if target
			#Erase item from the serialized string
			if target
				serialized.to_s.gsub!(/(layer|group)\[#{itemID}\]\=(\d+|null)/) { |match| 
					item = match
					item.gsub!(/\=(\d+|null)/) { |match| '=' + parent } if replaceParent #Replace item parent by target parent
					''
				}
			end#if
			if item && item != target
				#Put item next to target
				serialized.to_s.gsub!(/(layer|group)\[#{targetID}\]\=(\d+|null)/) { |match| 
					if side == "before"
						item + '&' + match
					elsif side == "after"
						match + '&' + item
					end#if
				}
			end#if
			#Get rid of extra "&" (At the start/end of the string, or when there's two of them)
			serialized.to_s.gsub!(/\A(&)/) { |match| 
				''
			}
			serialized.to_s.gsub!(/(&)\z/) { |match| 
				''
			}
			serialized.to_s.gsub!(/&{2}/) { |match| 
				'&'
			}
			self.set_attribute(@model, "jbb_layerspanel", "serialized", serialized) #Store serialized in model attribute dict
			self.refreshDialog
		end#if
		
		if target && item && itemID != targetID
			return true
		else
			return false
		end#if
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
	
	def self.set_render_behav(layer, bool)
		layerID = layer.get_attribute("jbb_layerspanel", "ID")
		context = self.currentContext
		if bool == false
			self.set_attribute(context, "jbb_layerspanel_render", layerID, 0)
		else
			self.set_attribute(context, "jbb_layerspanel_render", layerID, 2)
		end#if
		self.refreshDialog
		return nil
	end#def

end#module