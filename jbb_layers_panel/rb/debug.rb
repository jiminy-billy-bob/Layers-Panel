
module JBB_LayersPanel

	
	### OPTIONS DIALOG ### ------------------------------------------------------
		
	# Create the WebDialog instance
	def self.createDialogDebug
		@dialogDebug = WebdialogBridge.new("Layers Panel debug", false, "LayersPanelDebug", 250, 100, 300, 200, false)
		@dialogDebug.set_size(350,350)
		@dialogDebug.set_file(@html_path4)
		
		@dialogDebug.add_bridge_callback("getItemsIDs") do  |wdl, startup|
			getDictID = "getDictID('#{@model.get_attribute("jbb_layerspanel", "layerDictID")}');"
			@dialogDebug.execute_script(getDictID)
			
			#Groups
			serialized = @model.get_attribute("jbb_layerspanel", "serialized") #retreive string of serialized items
			groups = serialized.to_s.scan(/group\[(\d+)\]\=(\d+|null)/) #find groups, make an array of them
			groups.each{|match| 
					#match[0] : ID
					#match[1] : parent ID
					match = match.to_a
					name = @model.get_attribute("jbb_layerspanel_groups", match[0])
					addItem = "addItem('#{name}', '#{match[0]}');"
					@dialogDebug.execute_script(addItem)
				}
			
			#Layers
			@layers.each{|layer| 
					addItem = "addItem('#{layer.name}', '#{layer.get_attribute("jbb_layerspanel", "ID")}');"
					@dialogDebug.execute_script(addItem)
				}
		end#callback
		
		@dialogDebug.add_bridge_callback("debugItemsIDs") do  |wdl, action|
			@model.start_operation("Debug Layers Panel", true)
				puts ""
				puts ""
				puts "--- LAYERS PANEL DEBUG ---"
				puts ""
				self.initializeLayerDictID
				highestID = 0
				serialized = @model.get_attribute("jbb_layerspanel", "serialized") #retreive string of serialized items
				groups = serialized.to_s.scan(/group\[(\d+)\]/) #find groups, make an array of them
				groups.each{|match| #Groups
						if match[0].to_i > highestID.to_i
							highestID = match[0].to_i
						end#if
					}
				@layers.each{|layer| 
						if layer.get_attribute("jbb_layerspanel", "ID") > highestID.to_i
							highestID = layer.get_attribute("jbb_layerspanel", "ID")
						end#if
					}
				if @model.get_attribute("jbb_layerspanel", "layerDictID") < highestID.to_i + 1
					@model.set_attribute("jbb_layerspanel", "layerDictID", highestID.to_i+1)
					@layerDictID = highestID.to_i+1
				end#if
				
				ids = nil
				ids = Array.new
				
				#Fix groups first, because keeping groups order is more important as they can contain other items
				serialized = @model.get_attribute("jbb_layerspanel", "serialized") #retreive string of serialized items
				serialized.to_s.gsub!(/group\[(\d+)\]/) do |match| 
					id = match.scan(/group\[(\d+)\]/)[0][0].to_i
					name = "Group" #Default
					if @model.get_attribute("jbb_layerspanel_groups", id) != nil
						name = @model.get_attribute("jbb_layerspanel_groups", id)
					end#if
					if ids[id] != nil
						puts "Fixed ID for \"" + name + "\""
						self.incLayerDictID
						@model.set_attribute("jbb_layerspanel_groups", @layerDictID, name)
						id = @layerDictID
					end#if
					ids[id] = name
					"group[" + id.to_s + "]" #Replace id in serialized string
				end
				@model.set_attribute("jbb_layerspanel", "serialized", serialized)
				
				#Then fix layers
				@layers.each{|layer| 
						if ids[layer.get_attribute("jbb_layerspanel", "ID")] != nil
							puts "Fixed ID for \"" + layer.name + "\""
							layer.set_attribute("jbb_layerspanel", "ID", @layerDictID)
							self.incLayerDictID
						end#if
						ids[layer.get_attribute("jbb_layerspanel", "ID")] = layer.name
					}
					
				@dialogDebug.execute_script("reloadDialog();")
				self.dialogStartup #Reload main dialog
				puts ""
				puts "--- END DEBUG ---"
				puts ""
			@model.commit_operation
		end#callback
	end#def
	
	def self.show_layerspanel_dlg_debug
		if !@dialogDebug || !@dialogDebug.visible?
			self.createDialogDebug
			self.showDialog(@dialogDebug)
			self.make_toolwindow_frame("Layers Panel debug")
			@dialogDebug.execute_script("window.blur()")
		end#if
	end#def
	
	def self.close_layerspanel_dlg_debug
		if @dialogDebug && @dialogDebug.visible?
			@dialogDebug.close
		end#if
	end#def


end#module