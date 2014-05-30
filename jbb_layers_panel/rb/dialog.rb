
module JBB_LayersPanel
	
	
	### METHODS ### ------------------------------------------------------
	
	def self.dialogStartup
		@dialog.execute_script("emptyOl();")
		self.getModelLayers(false)
		self.getActiveLayer()
		self.getCollapsedGroups()
		self.getLayerColors()
		self.getRenderEngine
		self.checkRenderToolbar
		self.iframeTrack
		self.checkIEwarning
		self.checkForIssues
	end#def
	
	def self.refreshDialog
		@allowSerialize = false
		@dialog.execute_script("emptyOl();")
		self.getModelLayers(false)
		self.getActiveLayer()
		self.getCollapsedGroups()
		self.getLayerColors()
		done = false
		timer = UI.start_timer(0, false) {
			next if done
			done = true
			@allowSerialize = true
		}
	end#def
	
	def self.getModelLayers(serialize)
		serialized = @model.get_attribute("jbb_layerspanel", "serialized") #retreive string of serialized layers
		matches = serialized.to_s.scan(/(layer|group)\[(\d+)\]\=(\d+|null)/) #make an array of it
		
		matches.each do |match| 
			#match[0] : layer or group
			#match[1] : ID
			#match[2] : parent ID
			match = match.to_a
			
			if match[0].to_s == "layer" #if layer
				@layers.each{|layer| 
					if layer.get_attribute("jbb_layerspanel", "ID").to_i == match[1].to_i #if layer's dict ID == match ID
						#puts layer.name
						locked = 'false'
						if layer.get_attribute("jbb_layerspanel", "lock").to_i == 1
							locked = 'true'
						end#if
						# puts locked
						addLayerFromRuby = "addLayerFromRuby('#{layer.name}', '#{match[1]}', '#{match[2]}', false, '#{locked}');"
						@dialog.execute_script(addLayerFromRuby)
						break
					end#if
				}
			else #if group
				groupName = @model.get_attribute("jbb_layerspanel_groups", match[1])
				# puts groupName
				addGroup = "addGroup('#{groupName}', '#{match[1]}', '#{match[2]}');"
				@dialog.execute_script(addGroup)
			end#if
		end#each
		
		#Hide/show groups
		if @model.pages.selected_page == nil
			dict = @model
		else
			dict = @model.pages.selected_page
		end#if
		begin
			dict.attribute_dictionaries["jbb_layerspanel_tempHiddenGroups"].each { | groupID, value |
				if value == 1
					hideGroupFromRuby = "hideGroupFromRuby('#{groupID}');"
					@dialog.execute_script(hideGroupFromRuby)
				elsif value == 2
					hideGroupFromRuby = "hideGroupFromRuby('#{groupID}', true);"
					@dialog.execute_script(hideGroupFromRuby)
				end#if
			}
		rescue
		end#begin
		
		firstOp = true
		#Hide/show layers, add missing layers
		@layers.each{|layer|
			# puts layer.name
			if layer != @layers[0]
				if layer.get_attribute("jbb_layerspanel", "ID") == nil #if layer not IDed
					# puts 'attribute'
					if firstOp == true
						@model.start_operation("Layers Panel ID", true)
							self.initializeLayerDictID
							self.IDLayer(layer)
						@model.commit_operation
						firstOp = false
					else
						@model.start_operation("Layers Panel ID", true, false, true)
							self.IDLayer(layer)
						@model.commit_operation
					end#if
				end#if
				
				layerID = layer.get_attribute("jbb_layerspanel", "ID")
				addLayerFromRuby = "addLayerFromRuby('#{layer.name}', '#{layerID}', undefined, false);"
				@dialog.execute_script(addLayerFromRuby)
				if layer.visible?
					showLayerFromRuby = "showLayerFromRuby('#{layerID}');"
					@dialog.execute_script(showLayerFromRuby)
				elsif dict.get_attribute("jbb_layerspanel_tempHiddenByGroupLayers", layerID) == 1
					hideByGroupFromRuby = "hideByGroupFromRuby('#{layerID}');"
					@dialog.execute_script(hideByGroupFromRuby)
				else
					hideLayerFromRuby = "hideLayerFromRuby('#{layerID}');"
					@dialog.execute_script(hideLayerFromRuby)
				end#if
				
				self.checkEntityObserver(layer)
			end#if
		}
		
		#Render/noRender layers and groups
		begin
			dict.attribute_dictionaries["jbb_layerspanel_render"].each { | itemID, value |
				if value == 0
					hideGroupFromRuby = "noRenderFromRuby('#{itemID}');"
					@dialog.execute_script(hideGroupFromRuby)
				elsif value == 1
					hideGroupFromRuby = "noRenderFromRuby('#{itemID}', true);"
					@dialog.execute_script(hideGroupFromRuby)
				end#if
			}
		rescue
		end#begin
		
	end#def

	def self.getCollapsedGroups()
		serialized = @model.get_attribute("jbb_layerspanel", "serialized") #retreive string of serialized layers
		matches = serialized.to_s.scan(/(layer|group)\[(\d+)\]\=(\d+|null)/) #make an array of it
		
		matches.each do |match| #Group collapsing/expanding
			#match[0] : layer or group
			#match[1] : ID
			#match[2] : parent ID
			match = match.to_a
			
			if match[0].to_s == "group" #if group
				# puts match[1]
				if @model.pages.selected_page == nil
					dict = @model
				else
					dict = @model.pages.selected_page
				end#if
				
				if dict.get_attribute("jbb_layerspanel_collapseGroups", match[1]).to_i == 1
					# puts match[1]
					collapseFromRuby = "collapseFromRuby('#{match[1]}');"
					@dialog.execute_script(collapseFromRuby)
				end#if
			end#if
		end#each
	end#def

	def self.getLayerColors()
		if RUBY_VERSION.to_i >= 2
			@layers.each{|layer| 
					self.setColorFromRuby(layer)
				}
		end#if
	end#def
	
	def self.setColorFromRuby(layer)
		color = layer.color.to_s.sub(/[,]\s{1,}\d{1,}\)/, ')').sub(/(Color)/, "rgb") #Get rid of alpha, and replace "Color" by "rgb"
		if layer == @layers[0]
			layerID = 0
		else
			layerID = layer.get_attribute("jbb_layerspanel", "ID")
		end#if
		setColorFromRuby = "setColorFromRuby('#{layerID}', '#{color}');"
		@dialog.execute_script(setColorFromRuby)
	end#def

	def self.getActiveLayer()
		if @model.active_layer == @layers[0]
			activeLayer = 0
		else
			activeLayer = @model.active_layer.get_attribute("jbb_layerspanel", "ID")
		end#if
			setActiveLayerFromRuby = "setActiveLayerFromRuby('#{activeLayer}');"
			@dialog.execute_script(setActiveLayerFromRuby)
	end#def

	def self.hideByGroup(layerID)
		context = self.currentContext
		context.set_attribute("jbb_layerspanel_tempHiddenByGroupLayers", layerID, 1)
		if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
			context.set_attribute("jbb_layerspanel_hiddenByGroupLayers", layerID, 1)
		end#if
		# puts layer.name + " unhidden by group"
	end#def

	def self.unHideByGroup(layerID)
		context = self.currentContext
		context.set_attribute("jbb_layerspanel_tempHiddenByGroupLayers", layerID, 0)
		if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
			context.set_attribute("jbb_layerspanel_hiddenByGroupLayers", layerID, 0)
		end#if
		# puts layer.name + " unhidden by group"
	end#def
		
	def self.hideGroup(groupID, byGroup)
		context = self.currentContext
		if byGroup
			value = 2
		else
			value = 1
		end#if
		context.set_attribute("jbb_layerspanel_tempHiddenGroups", groupID, value)
		if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
			context.set_attribute("jbb_layerspanel_hiddenGroups", groupID, value)
		end#if
	end#def
		
	def self.unHideGroup(groupID)
		context = self.currentContext
		context.set_attribute("jbb_layerspanel_tempHiddenGroups", groupID, 0)
		if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
			context.set_attribute("jbb_layerspanel_hiddenGroups", groupID, 0)
		end#if
	end#def

	def self.getRenderEngine
		engine = Sketchup.read_default("jbb_layers_panel", "render_engine")
		# puts engine
		useRenderEngine = "useRenderEngine('#{engine}');"
		@dialog.execute_script(useRenderEngine)
	end#def

	def self.checkRenderToolbar
		displayRender = Sketchup.read_default("jbb_layers_panel", "display_render")
		# puts displayRender
		if displayRender == false
			@dialog.execute_script("noRenderToolbar()")
		end#if
	end#def

	def self.iframeTrack
		su = Sketchup.app_name
		suversion = Sketchup.version
		lang = Sketchup.get_locale
		iframeTrack = "iframeTrack('#{@version}', '#{su}', '#{suversion}', '#{lang}', '#{@store}');"
		@dialog.execute_script(iframeTrack)
	end#def

	def self.checkIEwarning
		displayIE = Sketchup.read_default("jbb_layers_panel", "display_IE")
		if displayIE == false
			@dialog.execute_script("noIEwarning()")
		end#if
	end#def

	def self.storeSerialize
		if @allowSerialize == true
			@dialog.execute_script("storeSerialize();")
			serialized = @dialog.get_element_value("serialize")
			# puts serialized
			@model.set_attribute("jbb_layerspanel", "serialized", serialized) #Store serialized in model attribute dict
		end#if
	end#def

	def self.resize(width, height)
		#Extracted and modified from TT's SKUI project
		#http://github.com/thomthom/SKUI
		@dialog.set_size(width, height)
		@dialog.execute_script("getDialogSize();")
		jsonSize = @dialog.get_element_value("dialogSize")
		sizeHash = self.jsonToHash(jsonSize)
		dialog_width = sizeHash['width'].to_i
		dialog_height = sizeHash['height'].to_i
		adjust_width  = width  - dialog_width
		adjust_height = height - dialog_height
		unless adjust_width == 0 && adjust_height == 0
			new_width  = width  + adjust_width
			new_height = height + adjust_height
			@dialog.set_size( new_width, new_height )
		end
		#Correct height when target height is less than border height
		@dialog.execute_script("getDialogSize();")
		jsonSize = @dialog.get_element_value("dialogSize")
		sizeHash = self.jsonToHash(jsonSize)
		dialog_height = sizeHash['height'].to_i
		adjust_height = height - dialog_height
		i = 1
		while adjust_height != 0
			new_height = height + adjust_height + i
			@dialog.set_size( new_width, new_height )
			@dialog.execute_script("getDialogSize();")
			jsonSize = @dialog.get_element_value("dialogSize")
			sizeHash = self.jsonToHash(jsonSize)
			dialog_height = sizeHash['height'].to_i
			adjust_height = height - dialog_height
			i += 1
		end
	end#def
	
	def self.checkForIssues
		issues = false
		highestID = 0
		serialized = @model.get_attribute("jbb_layerspanel", "serialized") #retreive string of serialized items
		groups = serialized.to_s.scan(/group\[(\d+)\]/) #find groups, make an array of them
		groups.each{|match| #Groups
				if match[0].to_i > highestID.to_i
					highestID = match[0].to_i
				end#if
			}
		@layers.each{|layer| 
				id = 0
				if layer.get_attribute("jbb_layerspanel", "ID") != nil
					id = layer.get_attribute("jbb_layerspanel", "ID").to_i
				end#if
				if id > highestID.to_i
					highestID = id
				end#if
			}
		
		layerDictID = 1
		if @model.get_attribute("jbb_layerspanel", "layerDictID") != nil
			layerDictID = @model.get_attribute("jbb_layerspanel", "layerDictID")
		end#if
		if layerDictID < highestID.to_i
			issues = 1
		end#if
		
		ids = nil
		ids = Array.new
		
		#Groups
		serialized = @model.get_attribute("jbb_layerspanel", "serialized") #retreive string of serialized items
		groups = serialized.to_s.scan(/group\[(\d+)\]/) #find groups, make an array of them
		groups.each{|match| #Groups
				id = match[0].to_i
				name = "Group" #Default
				if @model.get_attribute("jbb_layerspanel_groups", id) != nil
					name = @model.get_attribute("jbb_layerspanel_groups", id)
				end#if
				if ids[id] != nil
					issues = 2
				end#if
				ids[id] = name
				"group[" + id.to_s + "]" #Replace id in serialized string
			}
		
		#Layers
		@layers.each{|layer| 
				id = 0
				if layer.get_attribute("jbb_layerspanel", "ID") != nil
					id = layer.get_attribute("jbb_layerspanel", "ID").to_i
				end#if
				if ids[id] != nil
					issues = 3
				end#if
				ids[id] = layer.name
			}
		
		# puts issues
		if issues
			result = UI.messagebox('Layers Panel needs to be fixed. Click "OK" to open the debug dialog', MB_OKCANCEL)
			if result == IDOK
				self.show_layerspanel_dlg_debug
			end
		end#if
	end#def
	
	
	
	
	### WEBDIALOG & CALLBACKS ### ------------------------------------------------------


	# Create the WebDialog instance
	def self.createDialog
		
		if @dialog && @dialog.visible?
			begin
			@dialog.close
			@dialog = nil
			closed = true
			rescue
			end
		end#if
		
		@dialog = WebdialogBridge.new("Layers Panel", false, "LayersPanel", 215, 300, 300, 200, true)
		@dialog.min_width = 199
		@dialog.min_height = 37
		@dialog.set_file(@html_path)
		
		
		### Initialize dialog ### ------------------------------------------------------

		@dialog.add_bridge_callback("getModelLayers") do  |wdl, action|
			self.getModelLayers(true)
		end#callback getModelLayers

		@dialog.add_bridge_callback("getCollapsedGroups") do  |wdl, action|
			self.getCollapsedGroups()
		end#callback getModelLayers

		@dialog.add_bridge_callback("getActiveLayer") do  |wdl, action|
			self.getActiveLayer()
		end#callback getModelLayers

		@dialog.add_bridge_callback("setActiveLayerFromJS") do  |wdl, layerID|
			# puts layerID
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
					@model.active_layer = layer
					
					showLayerFromRuby = "showLayerFromRuby('#{layerID}');"
					@dialog.execute_script(showLayerFromRuby)
					break
				end#if
			}
		end#callback getModelLayers
		
		
		### Layers ### ------------------------------------------------------

		@dialog.add_bridge_callback("addLayerFromJS") do
			@model.start_operation("Add layer", true)
				layer = @layers.add @layers.unique_name
			@model.commit_operation
		end#callback addLayerFromJS

		@dialog.add_bridge_callback("specialAddLayerFromJS") do |wdl, json|
			@model.start_operation("Add layer", true)
			params = self.jsonToHash(json)
			name = params['name']
			visibleExisting = params['visibleExisting']
			visibleNew = params['visibleNew']
			if params['only'] == true
				visibleExisting = false
				visibleNew = false
			end#if
			unique_name = @layers.unique_name name.to_s
			layer = @layers.add unique_name
			if visibleExisting == false
				@model.pages.each do |page|
					if page == @model.pages.selected_page
						page.set_visibility(layer, true)
					else
						page.set_visibility(layer, false)
					end#if
				end#each
			end#if
			if visibleNew == false
				layer.page_behavior=(LAYER_IS_HIDDEN_ON_NEW_PAGES)
			end#if
			@model.commit_operation
		end#callback addLayerFromJS

		@dialog.add_bridge_callback("getUniqueName") do
			unique_name = @layers.unique_name
			getUniqueName = "getUniqueName('#{unique_name}');"
			@dialog.execute_script(getUniqueName)
		end#callback addLayerFromJS

		@dialog.add_bridge_callback("renameLayerFromJS") do |wdl, json|
			@model.start_operation("Rename layer", true)
			hash = self.jsonToHash(json)
			layerID = hash['layerID']
			newLayerName = hash['newLayerName']
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
					self.checkEntityObserver(layer)
					layer.name = newLayerName
					break
				end#if
			}
			UI.refresh_inspectors
			@model.commit_operation
		end#callback renameLayerFromJS

		@dialog.add_bridge_callback("checkLayerForContent") do |wdl, layerID|
			# puts layerID
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
					layerHasContent = false
					
					allents=[]
					@model.entities.each{|e|allents<<e if e.valid? and e.respond_to?(:layer)and e.layer==layer}
					@model.definitions.each{|d|d.entities.each{|e|allents<<e if e.valid? and e.respond_to?(:layer)and e.layer==layer}}
					if allents != [] #Layer has content
						layerHasContent = true
					end#if
					
					checkLayerForContent = "checkLayerForContent('#{layerID}', '#{layerHasContent}');"
					@dialog.execute_script(checkLayerForContent)
					break
				end#if
			}
		end#callback

		@dialog.add_bridge_callback("pickColor") do |wdl, layerID|
			if RUBY_VERSION.to_i >= 2
				self.show_layerspanel_dlg_color
				done = false
				timer = UI.start_timer(0, false) {
					next if done
					done = true
					@layers.each{|layer| 
						if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
							# color = layer.color.to_s.sub(/[,]\s{1,}\d{1,}\)/, ')').sub(/(Color)/, "") #Get rid of alpha and "Color"
							getLayerColor = "getLayerColor('#{layerID}', '#{layer.color.red}', '#{layer.color.green}', '#{layer.color.blue}');"
							@dialogColor.execute_script(getLayerColor)
							break
						end#if
					}
				}
			end#if
		end#callback

		@dialog.add_bridge_callback("lockFromJS") do |wdl, layerID|
			@model.start_operation("Lock layer", true)
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
					layer.set_attribute("jbb_layerspanel", "lock", 1)
					# puts layer.name + " locked"
					break
				end#if
			}
			@model.commit_operation
		end#callback

		@dialog.add_bridge_callback("unlockFromJS") do |wdl, layerID|
			@model.start_operation("Unlock layer", true)
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
					layer.set_attribute("jbb_layerspanel", "lock", 0)
					# puts layer.name + " unlocked"
					break
				end#if
			}
			@model.commit_operation
		end#callback

		@dialog.add_bridge_callback("deleteLayerFromJS") do |wdl, layerID|
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
					self.deleteLayer(layer)
					break
				end#if
			}
		end#callback deleteLayerFromJS

		@dialog.add_bridge_callback("deleteLayerToCurrentFromJS") do |wdl, layerID|
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
					self.deleteLayer(layer, false, true)
					break
				end#if
			}
		end#callback deleteLayerToCurrentFromJS

		@dialog.add_bridge_callback("deleteLayer&GeomFromJS") do |wdl, layerID|
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
					self.deleteLayer(layer, true)
					break
				end#if
			}
		end#callback deleteLayer&GeomFromJS

		@dialog.add_bridge_callback("mergeLayers") do |wdl, layerIDs|
			@model.start_operation("Merge layers", true)
			matches = layerIDs.to_s.scan(/([^,]+),/) #make an array of it
			activeLayer = @model.active_layer #Store current active layer to revert later
			i = 1
			matches.each{|match|
				if i == 1
					firstID = match[0]
					if firstID == "0"
						@model.active_layer = @layers[0]
						foundIt = true
					elsif firstID.to_i == 0
						foundIt = nil
					else
						@layers.each{|layer| 
							if layer.get_attribute("jbb_layerspanel", "ID").to_i == firstID.to_i
								@model.active_layer = layer
								foundIt = true
								break
							end#if
						}
					end#if
					if foundIt != true
						@model.active_layer = @layers.add @layers.unique_name(firstID)
					end#if
					# puts @model.active_layer.name
				else
					@layers.each{|layer| 
						if layer.get_attribute("jbb_layerspanel", "ID").to_i == match[0].to_i
							self.deleteLayer(layer, false, true)
							break
						end#if
					}
				end#if
				i = i+1
				# puts i
			}
			if !activeLayer.deleted?
				@model.active_layer = activeLayer #Restore active layer
			end#if
			self.storeSerialize
			@model.commit_operation
		end#callback mergeLayers

		@dialog.add_bridge_callback("startVisibilityOp") do |wdl, action|
			@model.start_operation("Layer Visibility", true)
		end#callback hideLayerFromJS

		@dialog.add_bridge_callback("endVisibilityOp") do |wdl, action|
			@model.commit_operation
		end#callback hideLayerFromJS

		@dialog.add_bridge_callback("hideLayerFromJS") do |wdl, layerID|
			# @model.start_operation("Hide layer", true)
			# puts layerID
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
					layer.visible = false
					break
				end#if
			}
			# @model.commit_operation
		end#callback hideLayerFromJS

		@dialog.add_bridge_callback("showLayerFromJS") do |wdl, layerID|
			# @model.start_operation("Unhide layer", true)
			# puts layerID
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
					layer.visible = true
					break
				end#if
			}
			# @model.commit_operation
		end#callback showLayerFromJS

		@dialog.add_bridge_callback("hideByGroup") do |wdl, layerID|
			self.hideByGroup(layerID)
		end#callback hideByGroup
		
		
		### Groups ### ------------------------------------------------------
		
		@dialog.add_bridge_callback("addGroupStart") do |wdl, groupName|
			@model.start_operation("Add group layer", true)
			self.initializeLayerDictID
			self.incLayerDictID
			# puts groupName
			# puts @layerDictID
			@model.set_attribute("jbb_layerspanel_groups", @layerDictID, groupName) #Store group's name with ID
			@dialogStates.execute_script("visibilityChanged();") if @dialogStates != nil
			@previousState = 0
		end#callback addGroup

		@dialog.add_bridge_callback("addGroupEnd") do |wdl, allowSerialize|
			allowSerialize == "true" ? self.storeSerialize :
			@model.commit_operation
		end#callback addGroup

		@dialog.add_bridge_callback("renameGroup") do |wdl, renameGroup|
			@model.start_operation("Rename group layer", true)
			hashGroup = self.jsonToHash(renameGroup)
			groupID = hashGroup['groupID']
			# puts groupID
			newGroupName = hashGroup['newGroupName']
			# puts newGroupName
			@model.set_attribute("jbb_layerspanel_groups", groupID, newGroupName) #Store new group's name from ID
			@model.commit_operation
		end#callback renameGroup

		@dialog.add_bridge_callback("collapseGroup") do |wdl, groupID|
			# puts "collapse " + groupID
			@model.start_operation("Collapse group layer", true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
			end#if
			dict.set_attribute("jbb_layerspanel_collapseGroups", groupID, 1)
			@dialogStates.execute_script("visibilityChanged();") if @dialogStates != nil
			@previousState = 0
			@model.commit_operation
		end#callback collapseGroup

		@dialog.add_bridge_callback("expandGroup") do |wdl, groupID|
			# puts "expand " + groupID
			@model.start_operation("Expand group layer", true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
			end#if
			dict.set_attribute("jbb_layerspanel_collapseGroups", groupID, 0)
			@dialogStates.execute_script("visibilityChanged();") if @dialogStates != nil
			@previousState = 0
			@model.commit_operation
		end#callback expandGroup

		@dialog.add_bridge_callback("hideGroup") do |wdl, groupID|
			self.hideGroup(groupID, false)
			@dialogStates.execute_script("visibilityChanged();") if @dialogStates != nil
			@previousState = 0
		end#callback hideGroup

		@dialog.add_bridge_callback("hideGroupByGroup") do |wdl, groupID|
			self.hideGroup(groupID, true)
		end#callback hideGroupByGroup

		@dialog.add_bridge_callback("unHideGroup") do |wdl, groupID|
			self.unHideGroup(groupID)
			@dialogStates.execute_script("visibilityChanged();") if @dialogStates != nil
			@previousState = 0
		end#callback unHideGroup

		@dialog.add_bridge_callback("groupLayers") do |wdl, action|
			@model.start_operation("Group layers", true, false, true) #merges with previous "Add group" operation
				self.storeSerialize
				@dialogStates.execute_script("visibilityChanged();") if @dialogStates != nil
				@previousState = 0
			@model.commit_operation
		end#callback groupLayers

		@dialog.add_bridge_callback("unGroupLayers") do |wdl, action|
			@model.start_operation("Ungroup layers", true)
				self.storeSerialize
				@dialogStates.execute_script("visibilityChanged();") if @dialogStates != nil
				@previousState = 0
			@model.commit_operation
		end#callback unGroupLayers

		@dialog.add_bridge_callback("purgeGroups") do |wdl, action|
			@model.start_operation("Purge groups", true)
				self.storeSerialize
				@dialogStates.execute_script("visibilityChanged();") if @dialogStates != nil
				@previousState = 0
			@model.commit_operation
		end#callback
		
		
		### Render ### ------------------------------------------------------

		@dialog.add_bridge_callback("useRenderEngine") do |wdl, engine|
			Sketchup.write_default("jbb_layers_panel", "render_engine", engine)
		end#callback render

		@dialog.add_bridge_callback("getRenderEngine") do |wdl, action|
			self.getRenderEngine
		end#callback render

		@dialog.add_bridge_callback("checkRenderToolbar") do |wdl, action|
			self.checkRenderToolbar
		end#callback render

		@dialog.add_bridge_callback("render") do |wdl, itemID|
			# puts "Render item " + itemID
			@model.start_operation("Render layer", true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
			end#if
			dict.set_attribute("jbb_layerspanel_render", itemID, 2)
			@model.commit_operation
		end#callback render

		@dialog.add_bridge_callback("noRender") do |wdl, itemID|
			# puts "noRender item " + itemID
			@model.start_operation("noRender layer", true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
			end#if
			dict.set_attribute("jbb_layerspanel_render", itemID, 0)
			@model.commit_operation
		end#callback noRender

		@dialog.add_bridge_callback("noRenderByGroup") do |wdl, itemID|
			# puts "noRenderByGroup item " + itemID
			@model.start_operation("noRenderByGroup layer", true, false, true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
			end#if
			dict.set_attribute("jbb_layerspanel_render", itemID, 1)
			@model.commit_operation
		end#callback noRenderByGroup

		@dialog.add_bridge_callback("triggerRender") do |wdl, engine|
			# puts "render"
			@model.start_operation("Render", true)
				
				#Create dummy layer and make it active, to allow visibility change of current active layer
				activeLayer = @model.active_layer #Store current active layer to revert later
				if engine != "podium" #Podium doesn't like this for some reason... So layer0 will always be rendered on Podium
					dummyLayer = @layers.add @layers.unique_name("Dummy layer")
					@model.active_layer = dummyLayer
				end#if
				
				#Get current dict (model or current scene)
				if @model.pages.selected_page == nil
					dict = @model
				else
					dict = @model.pages.selected_page
				end#if

				#Change layers visibility
				@layers.each{|layer|
					layerID = layer.get_attribute("jbb_layerspanel", "ID")
					
					#Store current visibility to revert later
					if layer.visible?
						layer.set_attribute("jbb_layerspanel", "visibilityBeforeRender", 2)
					elsif dict.get_attribute("jbb_layerspanel_tempHiddenByGroupLayers", layerID) == 1
						layer.set_attribute("jbb_layerspanel", "visibilityBeforeRender", 1)
					else
						layer.set_attribute("jbb_layerspanel", "visibilityBeforeRender", 0)
					end#if
					
					if dict.get_attribute("jbb_layerspanel_render", layerID) == 0
						layer.visible = false
					elsif dict.get_attribute("jbb_layerspanel_render", layerID) == 1
						layer.visible = false
					else
						layer.visible = true
					end#if
				}
			
				if engine == "vray"
					begin
						VRayForSketchUp.launch_vray_render
					rescue
						UI.messagebox("Vray is not installed on this system, or is disabled.")
					end
				elsif engine == "vrayrt"
					begin
						VRayForSketchUp.launch_vray_rt_render
					rescue
						UI.messagebox("Vray RT is not installed on this system, or is disabled.")
					end
				elsif engine == "mx"
					begin
						MX::Export.export('maxwell')
					rescue
						UI.messagebox("Maxwell is not installed on this system, or is disabled.")
					end
				elsif engine == "mxstudio"
					begin
						MX::Export.export('studio')
					rescue
						UI.messagebox("Maxwell is not installed on this system, or is disabled.")
					end
				elsif engine == "mxnet"
					begin
						MX::Export.export('network')
					rescue
						UI.messagebox("Maxwell is not installed on this system, or is disabled.")
					end
				elsif engine == "mxfire"
					begin
						MX::Export.export('fire')
					rescue
						UI.messagebox("Maxwell is not installed on this system, or is disabled.")
					end
				elsif engine == "kt"
					begin
						SU2KT.export
					rescue
						UI.messagebox("Kerkythea is not installed on this system, or is disabled.")
					end
				elsif engine == "ks"
					begin
						if not $ks4_instance
							$ks4_instance = KeyShot4::KeyShot4Exporter.new
						end
						$ks4_instance.ks4export ""
					rescue
						UI.messagebox("KeyShot is not installed on this system, or is disabled.")
					end
				elsif engine == "indigo"
					begin
						SkIndigo.export(0,true,nil,true,false)
					rescue
						UI.messagebox("Indigo is not installed on this system, or is disabled.")
					end
				elsif engine == "podium"
					@Podium = false
					begin
						Podium::const_get "Podium" #Check if podium is initialized
						@Podium = true
					rescue
						UI.messagebox("Podium is not installed on this system, or is disabled.")
					end
					if @Podium
						Podium::render
					end
				end#if

				
				#Revert layers visibility
				@layers.each{|layer|
					layerID = layer.get_attribute("jbb_layerspanel", "ID")
					if layer.get_attribute("jbb_layerspanel", "visibilityBeforeRender") == 0
						layer.visible = false
					elsif layer.get_attribute("jbb_layerspanel", "visibilityBeforeRender") == 1
						dict.set_attribute("jbb_layerspanel_tempHiddenByGroupLayers", layerID, 1)
						layer.visible = false
					elsif layer.get_attribute("jbb_layerspanel", "visibilityBeforeRender") == 2
						layer.visible = true
					end#if
				}
				
				#Revert to the previous active layer
				@model.active_layer = activeLayer
				done = false
				timer_01 = UI.start_timer(0, false) {
					next if done
					done = true
					if engine != "podium" #Podium doesn't like this for some reason...
						self.deleteLayer(dummyLayer)
					end#if
				}
			@model.commit_operation
		end#callback triggerRender
		
		
		### Misc ### ------------------------------------------------------

		@dialog.add_bridge_callback("getSelectionLayer") do |wdl, layerID|
			selection = @model.selection
			if selection.empty?
				UI.messagebox("Please select an object")
			elsif selection.length == 1
				@model.start_operation("Set selection's layer current", true)
				model.active_layer = selection[0].layer
				@model.commit_operation
			else
				UI.messagebox("Please select only ONE object")
			end#if
		end#callback

		@dialog.add_bridge_callback("highlightSelectionLayer") do |wdl, action|
			selection = @model.selection
			if selection.empty?
				UI.messagebox("Please select at least one object")
			else selection.length == 1
				@model.start_operation("Highlight selection's layer", true)
					selection.each { |entity| 
						layerID = entity.layer.get_attribute("jbb_layerspanel", "ID")
						hightlightLayer = "hightlightLayer('#{layerID}');"
						@dialog.execute_script(hightlightLayer)
					}
				@model.commit_operation
			end#if
		end#callback

		@dialog.add_bridge_callback("selectFromLayer") do |wdl, layerID|
			@model.start_operation("Select highlighted layer's entities", true)
			selection = @model.selection
			entities = @model.active_entities
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
					entities.each { |entity| 
						if entity.layer == layer
							selection.add entity
						end#if
					}
					break
				end#if
			}
			@model.commit_operation
		end#callback

		@dialog.add_bridge_callback("moveSelection") do |wdl, layerID|
			selection = @model.selection
			if selection.empty?
				UI.messagebox("Please select at least one object")
			else
				@model.start_operation("Move selection to hilighted layer", true)
				@layers.each{|layer| 
					if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
						selection.each{|e|
							e.layer=layer
						}
						break
					end#if
				}
				@model.commit_operation
			end#if
		end#callback

		@dialog.add_bridge_callback("purgeLayersFromJS") do |wdl, act|
			@model.start_operation("Purge unused layers", true)
			group=@model.entities.add_group()
			group.layer=nil
			gents=group.entities ### temporarily use locked layers
			temp=gents.add_group()
			temp.layer=nil
			@layers.each{|layer|
				if layer.get_attribute("jbb_layerspanel", "lock").to_i == 1
					tc=temp.copy
					tc.layer=layer
				end#if
			}
			@layers.purge_unused ### purge layer from browser
			if group.deleted? == false
				group.erase! ### erase! the temporary layer user, use set as was.
			end#if
			self.storeSerialize
			@dialogStates.execute_script("visibilityChanged();") if @dialogStates != nil
			@previousState = 0
			@model.commit_operation
		end#callback purgeLayersFromJS

		@dialog.add_bridge_callback("getLayerDictID") do |wdl, act|
			if @layerDictID == nil
				self.initializeLayerDictID
			end#if
			sendLayerDictID = "receiveLayerDictID('#{@layerDictID}');"
			@dialog.execute_script(sendLayerDictID)
		end#callback getLayerDictID

		@dialog.add_bridge_callback("storeSerialize") do
			@model.start_operation("storeSerialize", true, false, true) #Merge with previous operation
			self.storeSerialize
			@model.commit_operation
		end#callback storeSerialize

		@dialog.add_bridge_callback("storeSerialize2") do
			self.storeSerialize2
		end#callback storeSerialize

		@dialog.add_bridge_callback("sortItem") do |wdl, serialized|
			@model.start_operation("Sort layer/group", true)
			self.storeSerialize
			@model.commit_operation
		end#callback 

		@dialog.add_bridge_callback("iframeTrack") do
			self.iframeTrack
		end#callback

		@dialog.add_bridge_callback("openOptionsDialog") do
			self.show_layerspanel_dlg_options
		end#callback

		@dialog.add_bridge_callback("openDebugDialog") do
			self.show_layerspanel_dlg_debug
		end#callback

		@dialog.add_bridge_callback("undo") do
			Sketchup.send_action("editUndo:")
		end#callback 

		@dialog.add_bridge_callback("redo") do
			Sketchup.send_action("editRedo:")
		end#callback

		@dialog.add_bridge_callback("checkIEwarning") do |wdl, action|
			self.checkIEwarning
		end#callback render

		@dialog.add_bridge_callback("startup") do |wdl, action|
			self.dialogStartup
		end#callback render

		@dialog.add_bridge_callback("minimizeDialog") do |wdl, size|
			sizeHash = self.jsonToHash(size)
			self.resize(sizeHash['width'].to_i, 10)
			@heightBeforeMinimize = sizeHash['height']
		end#callback render

		@dialog.add_bridge_callback("maximizeDialog") do |wdl, width|
			width = width.to_i
			height = @heightBeforeMinimize
			self.resize(width, height)
		end#callback render

		@dialog.add_bridge_callback("colorByLayer") do |wdl, action|
			if @model.rendering_options["DisplayColorByLayer"] == true
				@model.rendering_options["DisplayColorByLayer"] = false
			else
				@model.rendering_options["DisplayColorByLayer"] = true
			end#if
		end#callback render
		
		
		############
		if closed
			self.showDialog(@dialog)
			self.make_toolwindow_frame("Layers Panel")
			true
		end#if
		
	end#def
	# self.createDialog


end#module