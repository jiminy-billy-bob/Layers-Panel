
module JBB_LayersPanel

	def self.resizeStates(width, height)
		#Extracted and modified from TT's SKUI project
		#http://github.com/thomthom/SKUI
		@dialogStates.set_size(width, height)
		@dialogStates.execute_script("getDialogSize();")
		jsonSize = @dialogStates.get_element_value("dialogSize")
		sizeHash = self.jsonToHash(jsonSize)
		dialog_width = sizeHash['width'].to_i
		dialog_height = sizeHash['height'].to_i
		adjust_width  = width  - dialog_width
		adjust_height = height - dialog_height
		unless adjust_width == 0 && adjust_height == 0
			new_width  = width  + adjust_width
			new_height = height + adjust_height
			@dialogStates.set_size( new_width, new_height )
		end
		#Correct height when target height is less than border height
		@dialogStates.execute_script("getDialogSize();")
		jsonSize = @dialogStates.get_element_value("dialogSize")
		sizeHash = self.jsonToHash(jsonSize)
		dialog_height = sizeHash['height'].to_i
		adjust_height = height - dialog_height
		i = 1
		while adjust_height != 0
			new_height = height + adjust_height + i
			@dialogStates.set_size( new_width, new_height )
			@dialogStates.execute_script("getDialogSize();")
			jsonSize = @dialogStates.get_element_value("dialogSize")
			sizeHash = self.jsonToHash(jsonSize)
			dialog_height = sizeHash['height'].to_i
			adjust_height = height - dialog_height
			i += 1
		end
	end#def
	
	def self.incStateDictID
		@stateDictID = @stateDictID + 1
		@model.set_attribute("jbb_layerspanel", "stateDictID", @stateDictID) #Store incremented stateDictID in model attribute dict
		# puts "incStateDictID"
	end#def
	
	def self.initializeStateDictID
		if @stateDictID == nil
			if @model.get_attribute("jbb_layerspanel", "stateDictID") != nil #Get stateDictID from model if exists
				@stateDictID = @model.get_attribute("jbb_layerspanel", "stateDictID")
			else #Else, create it
				@stateDictID = 0
			end#if
			self.incStateDictID
		end#if
	end#def

	def self.storeStateSerialize
		# if @allowStateSerialize == true
			@dialogStates.execute_script("storeSerialize();")
			serialized = @dialogStates.get_element_value("serialize")
			@model.set_attribute("jbb_layerspanel", "stateSerialized", serialized) #Store serialized in model attribute dict
		# end#if
	end#def
	
	def self.statesDialogStartup
		@allowStatesChange = false
		serialized = @model.get_attribute("jbb_layerspanel", "stateSerialized") #retreive string of serialized layers
		matches = serialized.to_s.scan(/(state|group)\[(\d+)\]\=(\d+|null)/) #make an array of it
		
		matches.each do |match| 
			#match[0] : state or group
			#match[1] : ID
			#match[2] : parent ID
			match = match.to_a
			
			if match[0].to_s == "state" #if state
				stateName = @model.get_attribute("jbb_layerspanel_states", match[1])
				addState = "addState('#{stateName}', '#{match[1]}', '#{match[2]}', false);"
				@dialogStates.execute_script(addState)
			else #if group
				groupName = @model.get_attribute("jbb_layerspanel_statesGroups", match[1])
				addGroup = "addGroup('#{groupName}', '#{match[1]}', '#{match[2]}');"
				@dialogStates.execute_script(addGroup)
			end#if
		end#each
		self.getCollapsedStatesGroups()
		@allowStatesChange = true
	end#def
	
	def self.refreshStatesDialog
		@dialogStates.execute_script("emptyOl();")
		self.statesDialogStartup
	end#def
	
	def self.updateState(stateID)
		context = self.currentContext
		visibleLayers = Array.new
		visibleGroups = Array.new
		hiddenByGroupsLayers = Array.new
		hiddenByGroupsGroups = Array.new
		collapsedGroups = Array.new
		@layers.each{|layer|
			layerID = layer.get_attribute("jbb_layerspanel", "ID")
			if layer.visible?
				visibleLayers.push(layer.get_attribute("jbb_layerspanel", "ID").to_i)
			elsif context.get_attribute("jbb_layerspanel_tempHiddenByGroupLayers", layerID) == 1
				hiddenByGroupsLayers.push(layer.get_attribute("jbb_layerspanel", "ID").to_i)
			end#if
		}
		groups = context.attribute_dictionaries["jbb_layerspanel_groups"]
		if groups != nil
			groups.each { | groupID, value |
				if context.get_attribute("jbb_layerspanel_tempHiddenGroups", groupID).to_i == 1
				elsif context.get_attribute("jbb_layerspanel_tempHiddenGroups", groupID).to_i == 2
					hiddenByGroupsGroups.push(groupID.to_i)
				else
					visibleGroups.push(groupID.to_i)
				end#if
				if context.get_attribute("jbb_layerspanel_collapseGroups", groupID).to_i == 1
					collapsedGroups.push(groupID.to_i)
				end#if
			}
		end#if
		
		@model.set_attribute("jbb_layerspanel_states", stateID.to_s + "activeLayerID", @model.active_layer.get_attribute("jbb_layerspanel", "ID").to_i)
		@model.set_attribute("jbb_layerspanel_states", stateID.to_s + "visibleLayers", visibleLayers)
		@model.set_attribute("jbb_layerspanel_states", stateID.to_s + "visibleGroups", visibleGroups)
		@model.set_attribute("jbb_layerspanel_states", stateID.to_s + "hiddenByGroupsLayers", hiddenByGroupsLayers)
		@model.set_attribute("jbb_layerspanel_states", stateID.to_s + "hiddenByGroupsGroups", hiddenByGroupsGroups)
		@model.set_attribute("jbb_layerspanel_states", stateID.to_s + "collapsedGroups", collapsedGroups)
	end#def

	def self.getCollapsedStatesGroups()
		serialized = @model.get_attribute("jbb_layerspanel", "stateSerialized") #retreive string of serialized layers
		matches = serialized.to_s.scan(/(layer|group)\[(\d+)\]\=(\d+|null)/) #make an array of it
		
		matches.each do |match| #Group collapsing/expanding
			#match[0] : layer or group
			#match[1] : ID
			#match[2] : parent ID
			match = match.to_a
			
			if match[0].to_s == "group" #if group
				# puts match[1]
				context = self.currentContext
				
				if context.get_attribute("jbb_layerspanel_collapseStatesGroups", match[1]).to_i == 1
					# puts match[1]
					collapseFromRuby = "collapseFromRuby('#{match[1]}');"
					@dialogStates.execute_script(collapseFromRuby)
				end#if
			end#if
		end#each
	end#def

	
	### STATES DIALOG ### ------------------------------------------------------
		
	# Create the WebDialog instance
	def self.createDialogStates
		@dialogStates = WebdialogBridge.new("Layer States", false, "LayersPanelStates", 215, 300, 300, 200, true)
		@dialogStates.min_width = 199
		@dialogStates.min_height = 37
		@dialogStates.set_file(@html_path6)
		
		
		### Initialize dialog ### ------------------------------------------------------

		@dialogStates.add_bridge_callback("startup") do  |wdl, action|
			self.statesDialogStartup
		end#callback
		
		
		### States ### ------------------------------------------------------
		
		@dialogStates.add_bridge_callback("addStateStart") do |wdl, stateName|
			@model.start_operation("Add layer state", true)
			self.initializeStateDictID
			self.incStateDictID
			# puts stateName
			# puts @stateDictID
			@model.set_attribute("jbb_layerspanel_states", @stateDictID, stateName)
			@previousState = @stateDictID
			self.updateState(@stateDictID)
		end#callback 

		@dialogStates.add_bridge_callback("addStateEnd") do |wdl, allowSerialize|
			# allowSerialize == "true" ? self.storeStateSerialize :
			self.storeStateSerialize
			@model.commit_operation
		end#callback 
		
		@previousState = 0
		@dialogStates.add_bridge_callback("setActiveStateFromJS") do |wdl, stateID|
			@allowStatesChange = false
			@model.start_operation("Change layers state", true)
			if stateID.to_i != 0 && @previousState == 0
				self.updateState(0)
			end#if
			
			if @model.get_attribute("jbb_layerspanel_states", stateID.to_s + "visibleLayers") != nil #Make sure there is something to read
				context = self.currentContext
				groups = context.attribute_dictionaries["jbb_layerspanel_groups"]
				
				#Set active layer
				activeLayerID = @model.get_attribute("jbb_layerspanel_states", stateID.to_s + "activeLayerID")
				@layers.each{|layer| 
					if layer.get_attribute("jbb_layerspanel", "ID").to_i == activeLayerID.to_i
						layer.visible = true
						@model.active_layer = layer
						break
					end#if
				}
				
				#Hide all layers and groups
				@layers.each{|layer| 
					layer.visible = false
					self.unHideByGroup(layer.get_attribute("jbb_layerspanel", "ID").to_i)
				}
				if groups != nil
					groups.each { | groupID, value |
						self.hideGroup(groupID, false)
					}
				end#if
				
				visibleLayers = @model.get_attribute("jbb_layerspanel_states", stateID.to_s + "visibleLayers")
				visibleGroups = @model.get_attribute("jbb_layerspanel_states", stateID.to_s + "visibleGroups")
				hiddenByGroupsLayers = @model.get_attribute("jbb_layerspanel_states", stateID.to_s + "hiddenByGroupsLayers")
				hiddenByGroupsGroups = @model.get_attribute("jbb_layerspanel_states", stateID.to_s + "hiddenByGroupsGroups")
				collapsedGroups = @model.get_attribute("jbb_layerspanel_states", stateID.to_s + "collapsedGroups")
				
				#Unhide visible layers and groups
				visibleLayers.each{|layerID|
					@layers.each{|layer| 
						if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
							layer.visible = true
							break
						end#if
					}
				}
				visibleGroups.each{|groupID|
					self.unHideGroup(groupID)
				}
				
				#Set hiddenByGroup tags
				hiddenByGroupsLayers.each{|layerID|
					@layers.each{|layer| 
						if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
							self.hideByGroup(layer.get_attribute("jbb_layerspanel", "ID").to_i)
							break
						end#if
					}
				}
				hiddenByGroupsGroups.each{|groupID|
					self.hideGroup(groupID, true)
				}
				
				#Expand all groups
				if context.attribute_dictionaries["jbb_layerspanel_collapseGroups"] != nil
					context.attribute_dictionaries["jbb_layerspanel_collapseGroups"].each{|groupID, value|
						context.set_attribute("jbb_layerspanel_collapseGroups", groupID, 0)
					}
				end#if
				#Collapse groups
				collapsedGroups.each{|groupID|
					context.set_attribute("jbb_layerspanel_collapseGroups", groupID, 1)
				}
				
				self.refreshDialog
			end#if
			@model.commit_operation
			@allowStatesChange = true
			@previousState = stateID.to_i
		end#callback

		@dialogStates.add_bridge_callback("updateState") do |wdl, stateID|
			@model.start_operation("Update State", true)
			self.updateState(stateID)
			@model.commit_operation
		end#callback 

		@dialogStates.add_bridge_callback("renameState") do |wdl, renameState|
			@model.start_operation("Rename layer state", true)
			hashState = self.jsonToHash(renameState)
			stateID = hashState['stateID']
			# puts stateID
			newStateName = hashState['newStateName']
			# puts newStateName
			@model.set_attribute("jbb_layerspanel_states", stateID, newStateName) #Store new state's name from ID
			@model.commit_operation
		end#callback
		
		
		### Groups ### ------------------------------------------------------
		
		@dialogStates.add_bridge_callback("addGroupStart") do |wdl, groupName|
			@model.start_operation("Add layer state group", true)
			self.initializeStateDictID
			self.incStateDictID
			# puts groupName
			# puts @stateDictID
			@model.set_attribute("jbb_layerspanel_statesGroups", @stateDictID, groupName)
		end#callback 

		@dialogStates.add_bridge_callback("addGroupEnd") do |wdl, allowSerialize|
			# allowSerialize == "true" ? self.storeStateSerialize :
			self.storeStateSerialize
			@model.commit_operation
		end#callback 

		@dialogStates.add_bridge_callback("groupStates") do |wdl, action|
			@model.start_operation("Group layer states", true, false, true) #merges with previous "Add group" operation
				self.storeStateSerialize
			@model.commit_operation
		end#callback

		@dialogStates.add_bridge_callback("unGroupStates") do |wdl, action|
			@model.start_operation("Ungroup layer states", true)
				self.storeStateSerialize
			@model.commit_operation
		end#callback

		@dialogStates.add_bridge_callback("collapseGroup") do |wdl, groupID|
			# puts "collapse " + groupID
			@model.start_operation("Collapse group layer", true)
			self.currentContext.set_attribute("jbb_layerspanel_collapseStatesGroups", groupID, 1)
			@model.commit_operation
		end#callback

		@dialogStates.add_bridge_callback("expandGroup") do |wdl, groupID|
			# puts "expand " + groupID
			@model.start_operation("Expand group layer", true)
			self.currentContext.set_attribute("jbb_layerspanel_collapseStatesGroups", groupID, 0)
			@model.commit_operation
		end#callback

		@dialogStates.add_bridge_callback("getCollapsedGroups") do |wdl, a|
			self.getCollapsedStatesGroups()
		end#callback

		@dialogStates.add_bridge_callback("renameGroup") do |wdl, renameGroup|
			@model.start_operation("Rename layer state group", true)
			hashGroup = self.jsonToHash(renameGroup)
			groupID = hashGroup['groupID']
			# puts groupID
			newGroupName = hashGroup['newGroupName']
			# puts newGroupName
			@model.set_attribute("jbb_layerspanel_statesGroups", groupID, newGroupName) #Store new group's name from ID
			@model.commit_operation
		end#callback
		
		
		### Misc ### ------------------------------------------------------

		@dialogStates.add_bridge_callback("getStateDictID") do |wdl, act|
			if @stateDictID == nil
				self.initializeStateDictID
			end#if
			sendStateDictID = "receiveStateDictID('#{@stateDictID}');"
			@dialogStates.execute_script(sendStateDictID)
		end#callback

		@dialogStates.add_bridge_callback("minimizeDialog") do |wdl, size|
			sizeHash = self.jsonToHash(size)
			self.resizeStates(sizeHash['width'].to_i, 10)
			@heightBeforeMinimizeStates = sizeHash['height']
		end#callback 

		@dialogStates.add_bridge_callback("maximizeDialog") do |wdl, width|
			width = width.to_i
			height = @heightBeforeMinimizeStates
			self.resizeStates(width, height)
		end#callback

		@dialogStates.add_bridge_callback("sortItem") do |wdl, serialized|
			@model.start_operation("Sort layer state", true)
			self.storeStateSerialize
			@model.commit_operation
		end#callback 

		@dialogStates.add_bridge_callback("storeSerialize") do |wdl, serialized|
			@model.start_operation("Sort layer state", true)
			self.storeStateSerialize
			@model.commit_operation
		end#callback 

		@dialogStates.add_bridge_callback("delete") do |wdl, serialized|
			@model.start_operation("Delete layer state", true)
			self.storeStateSerialize
			@model.commit_operation
		end#callback 

		@dialogStates.add_bridge_callback("undo") do
			Sketchup.send_action("editUndo:")
		end#callback 

		@dialogStates.add_bridge_callback("redo") do
			Sketchup.send_action("editRedo:")
		end#callback
		
	end#def
	
	def self.show_layerspanel_dlg_states
		if !@dialogStates || !@dialogStates.visible?
			self.createDialogStates
			self.showDialog(@dialogStates)
			self.make_toolwindow_frame("Layer States")
			@dialogStates.execute_script("window.blur()")
		end#if
	end#def
	
	def self.close_layerspanel_dlg_states
		if @dialogStates && @dialogStates.visible?
			@dialogStates.close
		end#if
	end#def


end#module