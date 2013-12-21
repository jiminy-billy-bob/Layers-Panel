
module JBB_LayersPanel
	
	
	### METHODS ### ------------------------------------------------------
	
	def self.dialogStartup
		@dialog.execute_script("emptyOl();")
		self.getModelLayers(false)
		self.getActiveLayer()
		self.getCollapsedGroups()
		self.getRenderEngine
		self.checkRenderToolbar
		self.iframeTrack
		self.checkIEwarning
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
			dict.attribute_dictionaries["jbb_layerspanel_tempHiddenGroups"].each { | groupId, value |
				if value == 1
					hideGroupFromRuby = "hideGroupFromRuby('#{groupId}');"
					@dialog.execute_script(hideGroupFromRuby)
				elsif value == 2
					hideGroupFromRuby = "hideGroupFromRuby('#{groupId}', true);"
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
							self.IdLayer(layer)
						@model.commit_operation
						firstOp = false
					else
						@model.start_operation("Layers Panel ID", true, false, true)
							self.IdLayer(layer)
						@model.commit_operation
					end#if
				end#if
				
				layerId = layer.get_attribute("jbb_layerspanel", "ID")
				addLayerFromRuby = "addLayerFromRuby('#{layer.name}', '#{layerId}', undefined, false);"
				@dialog.execute_script(addLayerFromRuby)
				if layer.visible?
					showLayerFromRuby = "showLayerFromRuby('#{layerId}');"
					@dialog.execute_script(showLayerFromRuby)
				elsif dict.get_attribute("jbb_layerspanel_tempHiddenByGroupLayers", layerId) == 1
					hideByGroupFromRuby = "hideByGroupFromRuby('#{layerId}');"
					@dialog.execute_script(hideByGroupFromRuby)
				else
					hideLayerFromRuby = "hideLayerFromRuby('#{layerId}');"
					@dialog.execute_script(hideLayerFromRuby)
				end#if
				
				if layer.get_attribute("jbb_layerspanel", "observer") != 1
					if firstOp == true
						@model.start_operation("Add layer observer", true)
							layer.add_observer(@jbb_lp_entityObserver)
							layer.set_attribute("jbb_layerspanel", "observer", 1)
							# puts 'observer ' + layer.name
						@model.commit_operation 
						firstOp = false
					else
						@model.start_operation("Add layer observer", true, false, true)
							layer.add_observer(@jbb_lp_entityObserver)
							layer.set_attribute("jbb_layerspanel", "observer", 1)
							# puts 'observer ' + layer.name
						@model.commit_operation 
					end#if
				end#if
			end#if
		}
		
		#Render/noRender layers and groups
		begin
			dict.attribute_dictionaries["jbb_layerspanel_render"].each { | itemId, value |
				if value == 0
					hideGroupFromRuby = "noRenderFromRuby('#{itemId}');"
					@dialog.execute_script(hideGroupFromRuby)
				elsif value == 1
					hideGroupFromRuby = "noRenderFromRuby('#{itemId}', true);"
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

	def self.getActiveLayer()
		if @model.active_layer == @layers[0]
			activeLayer = 0
		else
			activeLayer = @model.active_layer.get_attribute("jbb_layerspanel", "ID")
		end#if
			setActiveLayerFromRuby = "setActiveLayerFromRuby('#{activeLayer}');"
			@dialog.execute_script(setActiveLayerFromRuby)
	end#def

	def self.unHideByGroup(layerId)
		if @model.pages.selected_page == nil
			dict = @model
		else
			dict = @model.pages.selected_page
		end#if
		dict.set_attribute("jbb_layerspanel_tempHiddenByGroupLayers", layerId, 0)
		if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
			dict.set_attribute("jbb_layerspanel_hiddenByGroupLayers", layerId, 0)
		end#if
		# puts layer.name + " unhidden by group"
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
		iframeTrack = "iframeTrack('#{@lpversion}', '#{su}', '#{suversion}', '#{lang}', '#{@store}');"
		@dialog.execute_script(iframeTrack)
	end#def

	def self.checkIEwarning
		displayIE = Sketchup.read_default("jbb_layers_panel", "display_IE")
		if displayIE == false
			@dialog.execute_script("noIEwarning()")
		end#if
	end#def

	def self.storeSerialize
		@dialog.execute_script("storeSerialize();")
	end#def

	def self.storeSerialize2
		if @allowSerialize == true
			serialized = @dialog.get_element_value("serialize")
			# puts serialized
			@model.set_attribute("jbb_layerspanel", "serialized", serialized) #Store serialized in model attribute dict
		end#if
	end#def
	
	
	
	
	### WEBDIALOG & CALLBACKS ### ------------------------------------------------------

	class WebdialogBridge < UI::WebDialog

		def add_bridge_callback(callback, &block)
			add_action_callback(callback) do  |webdialog, params|
				# puts "add_bridge_callback(#{callback}) { |#{params}| }"
				block.call(webdialog, params)
				execute_script('skpCallbackReceived();')
			end
		end

	end # WebdialogBridge


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

		@dialog.add_bridge_callback("setActiveLayerFromJS") do  |wdl, layerId|
			# puts layerId
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					@model.active_layer = layer
					
					showLayerFromRuby = "showLayerFromRuby('#{layerId}');"
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

		@dialog.add_bridge_callback("addHiddenLayerFromJS") do
			@model.start_operation("Add layer", true)
			layer = @layers.add @layers.unique_name
			layer.page_behavior=(LAYER_IS_HIDDEN_ON_NEW_PAGES)
			@model.pages.each do |page|
				if page == @model.pages.selected_page
					page.set_visibility(layer, true)
				else
					page.set_visibility(layer, false)
				end#if
			end#each
			@model.commit_operation
		end#callback addLayerFromJS

		@dialog.add_bridge_callback("renameLayerFromJS") do |wdl, layerNameS|
			@model.start_operation("Rename layer", true)
			hashLayerNames = self.jsonToHash(layerNameS)
			layerId = hashLayerNames['layerID']
			newLayerName = hashLayerNames['newLayerName']
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					layer.remove_observer(@jbb_lp_entityObserver) #Reset observer to make sure layer is watched
					layer.add_observer(@jbb_lp_entityObserver)
					layer.set_attribute("jbb_layerspanel", "observer", 1)
					layer.name = newLayerName
					break
				end#if
			}
			UI.refresh_inspectors
			@model.commit_operation
		end#callback renameLayerFromJS

		@dialog.add_bridge_callback("checkLayerForContent") do |wdl, layerId|
			# puts layerId
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					layerHasContent = false
					
					allents=[]
					@model.entities.each{|e|allents<<e if e.valid? and e.respond_to?(:layer)and e.layer==layer}
					@model.definitions.each{|d|d.entities.each{|e|allents<<e if e.valid? and e.respond_to?(:layer)and e.layer==layer}}
					if allents != [] #Layer has content
						layerHasContent = true
					end#if
					
					checkLayerForContent = "checkLayerForContent('#{layerId}', '#{layerHasContent}');"
					@dialog.execute_script(checkLayerForContent)
					break
				end#if
			}
		end#callback

		@dialog.add_bridge_callback("lockFromJS") do |wdl, layerId|
			@model.start_operation("Lock layer", true)
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					layer.set_attribute("jbb_layerspanel", "lock", 1)
					# puts layer.name + " locked"
					break
				end#if
			}
			@model.commit_operation
		end#callback

		@dialog.add_bridge_callback("unlockFromJS") do |wdl, layerId|
			@model.start_operation("Unlock layer", true)
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					layer.set_attribute("jbb_layerspanel", "lock", 0)
					# puts layer.name + " unlocked"
					break
				end#if
			}
			@model.commit_operation
		end#callback

		@dialog.add_bridge_callback("deleteLayerFromJS") do |wdl, layerId|
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					self.deleteLayer(layer)
					break
				end#if
			}
		end#callback deleteLayerFromJS

		@dialog.add_bridge_callback("deleteLayerToCurrentFromJS") do |wdl, layerId|
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					self.deleteLayer(layer, false, true)
					break
				end#if
			}
		end#callback deleteLayerToCurrentFromJS

		@dialog.add_bridge_callback("deleteLayer&GeomFromJS") do |wdl, layerId|
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
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

		@dialog.add_bridge_callback("hideLayerFromJS") do |wdl, layerId|
			@model.start_operation("Hide layer", true)
			# puts layerId
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					layer.visible = false
					break
				end#if
			}
			@model.commit_operation
		end#callback hideLayerFromJS

		@dialog.add_bridge_callback("showLayerFromJS") do |wdl, layerId|
			@model.start_operation("Unhide layer", true)
			# puts layerId
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					layer.visible = true
					break
				end#if
			}
			@model.commit_operation
		end#callback showLayerFromJS

		@dialog.add_bridge_callback("hideByGroup") do |wdl, layerId|
			@model.start_operation("Hide layer", true, false, true)
			# puts layerId
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
			end#if
			dict.set_attribute("jbb_layerspanel_tempHiddenByGroupLayers", layerId, 1)
			if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
				dict.set_attribute("jbb_layerspanel_hiddenByGroupLayers", layerId, 1)
			end#if
			@model.commit_operation
		end#callback hideByGroup
		
		
		### Groups ### ------------------------------------------------------
		
		@dialog.add_bridge_callback("addGroupStart") do |wdl, groupName|
			@model.start_operation("Add group layer", true)
			self.initializeLayerDictID
			self.incLayerDictID
			# puts groupName
			# puts @layerDictID
			@model.set_attribute("jbb_layerspanel_groups", @layerDictID, groupName) #Store group's name with ID
		end#callback addGroup

		@dialog.add_bridge_callback("addGroupEnd") do |wdl, groupName|
			@model.commit_operation
		end#callback addGroup

		@dialog.add_bridge_callback("renameGroup") do |wdl, renameGroup|
			@model.start_operation("Rename group layer", true)
			hashGroup = self.jsonToHash(renameGroup)
			groupId = hashGroup['groupID']
			# puts groupId
			newGroupName = hashGroup['newGroupName']
			# puts newGroupName
			@model.set_attribute("jbb_layerspanel_groups", groupId, newGroupName) #Store new group's name from ID
			@model.commit_operation
		end#callback renameGroup

		@dialog.add_bridge_callback("collapseGroup") do |wdl, groupId|
			# puts "collapse " + groupId
			@model.start_operation("Collapse group layer", true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
			end#if
			dict.set_attribute("jbb_layerspanel_collapseGroups", groupId, 1)
			@model.commit_operation
		end#callback collapseGroup

		@dialog.add_bridge_callback("expandGroup") do |wdl, groupId|
			# puts "expand " + groupId
			@model.start_operation("Expand group layer", true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
			end#if
			dict.set_attribute("jbb_layerspanel_collapseGroups", groupId, 0)
			@model.commit_operation
		end#callback expandGroup

		@dialog.add_bridge_callback("hideGroup") do |wdl, groupId|
			# puts "Hide group " + groupId
			@model.start_operation("Hide group layer", true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
				# puts 'hide - current page : ' + @model.pages.selected_page.name
			end#if
			dict.set_attribute("jbb_layerspanel_tempHiddenGroups", groupId, 1)
			if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
				dict.set_attribute("jbb_layerspanel_hiddenGroups", groupId, 1)
			end#if
			# puts "hide group"
			@model.commit_operation
		end#callback hideGroup

		@dialog.add_bridge_callback("hideGroupByGroup") do |wdl, groupId|
			# puts "HideByGroup group " + groupId
			@model.start_operation("Hide group layer", true, false, true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
				# puts 'hidebygroup - current page : ' + @model.pages.selected_page.name
			end#if
			dict.set_attribute("jbb_layerspanel_tempHiddenGroups", groupId, 2)
			if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
				dict.set_attribute("jbb_layerspanel_hiddenGroups", groupId, 2)
			end#if
			@model.commit_operation
		end#callback hideGroupByGroup

		@dialog.add_bridge_callback("unHideGroup") do |wdl, groupId|
			# puts "Hide group " + groupId
			@model.start_operation("Unhide group layer", true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
				# puts 'unhide - current page : ' + @model.pages.selected_page.name
			end#if
			dict.set_attribute("jbb_layerspanel_tempHiddenGroups", groupId, 0)
			if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
				dict.set_attribute("jbb_layerspanel_hiddenGroups", groupId, 0)
			end#if
			# puts "unhide group"
			@model.commit_operation
		end#callback unHideGroup

		@dialog.add_bridge_callback("groupLayers") do |wdl, action|
			@model.start_operation("Group layers", true, false, true) #merges with previous "Add group" operation
				self.storeSerialize
			@model.commit_operation
		end#callback groupLayers

		@dialog.add_bridge_callback("unGroupLayers") do |wdl, action|
			@model.start_operation("Ungroup layers", true)
				self.storeSerialize
			@model.commit_operation
		end#callback unGroupLayers

		@dialog.add_bridge_callback("purgeGroups") do |wdl, action|
			@model.start_operation("Purge groups", true)
				self.storeSerialize
			@model.commit_operation
		end#callback unGroupLayers
		
		
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

		@dialog.add_bridge_callback("render") do |wdl, itemId|
			# puts "Render item " + itemId
			@model.start_operation("Render layer", true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
			end#if
			dict.set_attribute("jbb_layerspanel_render", itemId, 2)
			@model.commit_operation
		end#callback render

		@dialog.add_bridge_callback("noRender") do |wdl, itemId|
			# puts "noRender item " + itemId
			@model.start_operation("noRender layer", true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
			end#if
			dict.set_attribute("jbb_layerspanel_render", itemId, 0)
			@model.commit_operation
		end#callback noRender

		@dialog.add_bridge_callback("noRenderByGroup") do |wdl, itemId|
			# puts "noRenderByGroup item " + itemId
			@model.start_operation("noRenderByGroup layer", true, false, true)
			if @model.pages.selected_page == nil
				dict = @model
			else
				dict = @model.pages.selected_page
			end#if
			dict.set_attribute("jbb_layerspanel_render", itemId, 1)
			@model.commit_operation
		end#callback noRenderByGroup

		@dialog.add_bridge_callback("triggerRender") do |wdl, engine|
			# puts "render"
			@model.start_operation("test", true)
				
				#Create dummy layer and make it active, to allow visibility change of current active layer
				activeLayer = @model.active_layer #Store current active layer to revert later
				dummyLayer = @layers.add @layers.unique_name("Dummy layer")
				@model.active_layer = dummyLayer
				
				#Get current dict (model or current scene)
				if @model.pages.selected_page == nil
					dict = @model
				else
					dict = @model.pages.selected_page
				end#if

				#Change layers visibility
				@layers.each{|layer|
					layerId = layer.get_attribute("jbb_layerspanel", "ID")
					
					#Store current visibility to revert later
					if layer.visible?
						layer.set_attribute("jbb_layerspanel", "visibilityBeforeRender", 2)
					elsif dict.get_attribute("jbb_layerspanel_tempHiddenByGroupLayers", layerId) == 1
						layer.set_attribute("jbb_layerspanel", "visibilityBeforeRender", 1)
					else
						layer.set_attribute("jbb_layerspanel", "visibilityBeforeRender", 0)
					end#if
					
					if dict.get_attribute("jbb_layerspanel_render", layerId) == 0
						layer.visible = false
					elsif dict.get_attribute("jbb_layerspanel_render", layerId) == 1
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
						SkIndigo.export(0,true,nil,true)
					rescue
						UI.messagebox("Indigo is not installed on this system, or is disabled.")
					end
				elsif engine == "podium"
					begin
						Podium::render
					rescue
						UI.messagebox("Podium is not installed on this system, or is disabled.")
					end
				end#if

				
				#Revert layers visibility
				@layers.each{|layer|
					layerId = layer.get_attribute("jbb_layerspanel", "ID")
					if layer.get_attribute("jbb_layerspanel", "visibilityBeforeRender") == 0
						layer.visible = false
					elsif layer.get_attribute("jbb_layerspanel", "visibilityBeforeRender") == 1
						dict.set_attribute("jbb_layerspanel_tempHiddenByGroupLayers", layerId, 1)
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
					self.deleteLayer(dummyLayer)
				}
			@model.commit_operation
		end#callback triggerRender
		
		
		### Misc ### ------------------------------------------------------

		@dialog.add_bridge_callback("getSelectionLayer") do |wdl, layerId|
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
						layerId = entity.layer.get_attribute("jbb_layerspanel", "ID")
						hightlightLayer = "hightlightLayer('#{layerId}');"
						@dialog.execute_script(hightlightLayer)
					}
				@model.commit_operation
			end#if
		end#callback

		@dialog.add_bridge_callback("selectFromLayer") do |wdl, layerId|
			@model.start_operation("Select highlighted layer's entities", true)
			selection = @model.selection
			entities = @model.active_entities
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
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

		@dialog.add_bridge_callback("moveSelection") do |wdl, layerId|
			selection = @model.selection
			if selection.empty?
				UI.messagebox("Please select at least one object")
			else
				@model.start_operation("Move selection to hilighted layer", true)
				@layers.each{|layer| 
					if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
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
			@dialog.set_size(sizeHash['width'].to_i + 16, 37)
			@heightBeforeMinimize = sizeHash['height']
		end#callback render

		@dialog.add_bridge_callback("maximizeDialog") do |wdl, size|
			sizeHash = self.jsonToHash(size)
			@dialog.set_size(sizeHash['width'].to_i + 16, @heightBeforeMinimize + 34)
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