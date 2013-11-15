#-----------------------------------------------------------------------------
require 'sketchup.rb'
#-----------------------------------------------------------------------------

module JBB_LayersPanel

#-----------------------------------------------------------------------------

	MAC = ( Object::RUBY_PLATFORM =~ /darwin/i ? true : false )
	WIN = ( (Object::RUBY_PLATFORM =~ /mswin/i || Object::RUBY_PLATFORM =~ /mingw/i) ? true : false )

#-----------------------------------------------------------------------------

	if WIN

		require 'jbb_layers_panel/Win32API.so'

		WS_CAPTION  = 0x00C00000
		WS_EX_TOOLWINDOW = 0x00000080

		GWL_STYLE   = -16
		GWL_EXSTYLE = -20

		# SetWindowPos() flags
		SWP_NOSIZE       = 0x0001
		SWP_NOMOVE       = 0x0002
		SWP_DRAWFRAME    = 0x0020
		SWP_FRAMECHANGED = 0x0020
		SWP_NOREPOSITION = 0x0200
		WS_MAXIMIZEBOX =  0x10000
		WS_MINIMIZEBOX =  0x20000
		WS_SIZEBOX     =  0x40000

		# Windows Functions
		#FindWindow    = Win32API.new("user32.dll" , "FindWindow"   , 'PP' , 'L')
		#FindWindowEx  = Win32API.new("user32.dll", "FindWindowEx" , 'LLPP', 'L')
		SetWindowPos  = Win32API.new("user32.dll" , "SetWindowPos" , 'LLIIIII', 'I')
		SetWindowLong = Win32API.new("user32.dll" , "SetWindowLong", 'LIL', 'L')
		GetWindowLong = Win32API.new("user32.dll" , "GetWindowLong", 'LI' , 'L')
		GetActiveWindow = Win32API.new("user32.dll", "GetActiveWindow", '', 'L')
		#GetForegroundWindow = Win32API.new("user32.dll", "GetForegroundWindow", '', 'L')
		GetWindowText = Win32API.new("user32.dll", "GetWindowText", 'LPI', 'I')
		GetWindowTextLength = Win32API.new("user32.dll", "GetWindowTextLength", 'L', 'I')
		
	end#if
	
#-----------------------------------------------------------------------------
	
	@lpversion = "0.7"
	@model = Sketchup.active_model
	@layers = @model.layers
	@layerDictID = nil
	@dialog = nil
	@allowSerialize = true
	@previousPageDict = nil
	@previousPageDict2 = nil
	@previousPageDict3 = nil
	@previousPageDict4 = nil
	@check = nil
	@store = "ps"
	@selectedPageLayers = nil
	@timerCheckUpdate = nil
	@heightBeforeMinimize = 300
	
	@jbb_lp_pagesObserver = nil
	@jbb_lp_modelObserver = nil
	@jbb_lp_appObserver = nil
	@jbb_lp_entityObserver = nil
	@jbb_lp_layersObserver = nil
	
	@isActive = true
	
	class << self
		attr_accessor :isActive, :model, :layers, :layerDictID, :dialog, :allowSerialize, :previousPageDict, :previousPageDict2, :previousPageDict3, :previousPageDict4, :check, :selectedPageLayers, :timerCheckUpdate, :heightBeforeMinimize, :jbb_lp_pagesObserver, :jbb_lp_modelObserver,  :jbb_lp_appObserver,  :jbb_lp_entityObserver,  :jbb_lp_layersObserver
	end
	
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
		begin
			if layer.get_attribute("jbb_layerspanel", "ID") != nil 
				#puts layer.name + " already IDed " + layer.get_attribute("jbb_layerspanel", "ID").to_s
			else
				@model.start_operation("ID layer", true, false, true)
				layer.set_attribute("jbb_layerspanel", "ID", @layerDictID)
				# puts "layerDictID " + @layerDictID.to_s
				self.incLayerDictID
				@model.commit_operation 
			end#if
		rescue
		end
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
  
  
  
	### WEBDIALOG & CALLBACKS ### ------------------------------------------------------
	
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
		# @model.start_operation("Layers Panel", true)
		
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
		# if dict.attribute_dictionaries["jbb_layerspanel_hiddenGroups"]
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
		
		#Hide/show layers, add missing layers
		@layers.each{|layer|
			# puts layer.name
			if layer != @layers[0]
				if layer.get_attribute("jbb_layerspanel", "ID") == nil 
					# puts 'attribute'
					self.initializeLayerDictID
					self.IdLayer(layer)
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
					@model.start_operation("Add layer observer", true, false, true)
					layer.add_observer(@jbb_lp_entityObserver)
					layer.set_attribute("jbb_layerspanel", "observer", 1)
					# puts 'observer ' + layer.name
					@model.commit_operation 
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
		
		# @model.commit_operation
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
		# @model.start_operation("Unhide layer", true, false, true)
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
		# @model.commit_operation
	end#def

	def self.getRenderEngine
		engine = Sketchup.read_default("jbb_layers_panel", "render_engine")
		# puts engine
		useRenderEngine = "useRenderEngine('#{engine}');"
		@dialog.execute_script(useRenderEngine)
	end#def

	def self.checkRenderToolbar
		displayRender = Sketchup.read_default("jbb_layers_panel", "display_render")
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
		@model.start_operation("Store Serialize", true, false, true)
		serialized = @dialog.get_element_value("serialize")
		# puts serialized
		@model.set_attribute("jbb_layerspanel", "serialized", serialized) #Store serialized in model attribute dict
		@model.commit_operation
	end#def
	
	
		
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
		
		@dialog = UI::WebDialog.new("Layers Panel", false, "LayersPanel", 215, 300, 300, 200, true)
		@dialog.min_width = 199
		@dialog.min_height = 37
		@html_path = File.dirname( __FILE__ ) + "/layers Panel.html"
		@dialog.set_file(@html_path)
		
		
		### Initialize dialog ### ------------------------------------------------------

		@dialog.add_action_callback("getModelLayers") do  |wdl, action|
			self.getModelLayers(true)
		end#callback getModelLayers

		@dialog.add_action_callback("getCollapsedGroups") do  |wdl, action|
			self.getCollapsedGroups()
		end#callback getModelLayers

		@dialog.add_action_callback("getActiveLayer") do  |wdl, action|
			self.getActiveLayer()
		end#callback getModelLayers

		@dialog.add_action_callback("setActiveLayerFromJS") do  |wdl, layerId|
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

		@dialog.add_action_callback("addLayerFromJS") do
			@model.start_operation("Add layer", true)
				layer = @layers.add @layers.unique_name
			@model.commit_operation
		end#callback addLayerFromJS

		@dialog.add_action_callback("addHiddenLayerFromJS") do
			@model.start_operation("Add layer", true)
			layer = @layers.add @layers.unique_name
			layer.page_behavior=(LAYER_HIDDEN_BY_DEFAULT | LAYER_IS_HIDDEN_ON_NEW_PAGES)
			@model.commit_operation
		end#callback addLayerFromJS

		@dialog.add_action_callback("renameLayerFromJS") do |wdl, layerNameS|
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

		@dialog.add_action_callback("checkLayerForContent") do |wdl, layerId|
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

		@dialog.add_action_callback("lockFromJS") do |wdl, layerId|
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

		@dialog.add_action_callback("unlockFromJS") do |wdl, layerId|
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

		@dialog.add_action_callback("deleteLayerFromJS") do |wdl, layerId|
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					self.deleteLayer(layer)
					break
				end#if
			}
		end#callback deleteLayerFromJS

		@dialog.add_action_callback("deleteLayerToCurrentFromJS") do |wdl, layerId|
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					self.deleteLayer(layer, false, true)
					break
				end#if
			}
		end#callback deleteLayerToCurrentFromJS

		@dialog.add_action_callback("deleteLayer&GeomFromJS") do |wdl, layerId|
			@layers.each{|layer| 
				if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerId.to_i
					self.deleteLayer(layer, true)
					break
				end#if
			}
		end#callback deleteLayer&GeomFromJS

		@dialog.add_action_callback("mergeLayers") do |wdl, layerIDs|
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
		end#callback mergeLayers

		@dialog.add_action_callback("hideLayerFromJS") do |wdl, layerId|
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

		@dialog.add_action_callback("showLayerFromJS") do |wdl, layerId|
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

		@dialog.add_action_callback("hideByGroup") do |wdl, layerId|
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
		
		@dialog.add_action_callback("addGroupStart") do |wdl, groupName|
			@model.start_operation("Add group layer", true)
			self.initializeLayerDictID
			# puts groupName
			# puts @layerDictID
			@model.set_attribute("jbb_layerspanel_groups", @layerDictID, groupName) #Store group's name with ID
		end#callback addGroup

		@dialog.add_action_callback("addGroupEnd") do |wdl, groupName|
			# @dialog.execute_script("storeSerialize();")
			@model.commit_operation
		end#callback addGroup

		@dialog.add_action_callback("renameGroup") do |wdl, renameGroup|
			@model.start_operation("Rename group layer", true)
			hashGroup = self.jsonToHash(renameGroup)
			groupId = hashGroup['groupID']
			# puts groupId
			newGroupName = hashGroup['newGroupName']
			# puts newGroupName
			@model.set_attribute("jbb_layerspanel_groups", groupId, newGroupName) #Store new group's name from ID
			@model.commit_operation
		end#callback renameGroup

		@dialog.add_action_callback("collapseGroup") do |wdl, groupId|
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

		@dialog.add_action_callback("expandGroup") do |wdl, groupId|
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

		@dialog.add_action_callback("hideGroup") do |wdl, groupId|
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

		@dialog.add_action_callback("hideGroupByGroup") do |wdl, groupId|
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

		@dialog.add_action_callback("unHideGroup") do |wdl, groupId|
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
		
		
		### Render ### ------------------------------------------------------

		@dialog.add_action_callback("useRenderEngine") do |wdl, engine|
			Sketchup.write_default("jbb_layers_panel", "render_engine", engine)
		end#callback render

		@dialog.add_action_callback("getRenderEngine") do |wdl, action|
			self.getRenderEngine
		end#callback render

		@dialog.add_action_callback("checkRenderToolbar") do |wdl, action|
			self.checkRenderToolbar
		end#callback render

		@dialog.add_action_callback("render") do |wdl, itemId|
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

		@dialog.add_action_callback("noRender") do |wdl, itemId|
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

		@dialog.add_action_callback("noRenderByGroup") do |wdl, itemId|
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

		@dialog.add_action_callback("triggerRender") do |wdl, engine|
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
				timer_01 = UI.start_timer(0, false) {
					UI.stop_timer(timer_01)
					self.deleteLayer(dummyLayer)
				}
			@model.commit_operation
		end#callback triggerRender
		
		
		### Misc ### ------------------------------------------------------

		@dialog.add_action_callback("getSelectionLayer") do |wdl, layerId|
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

		@dialog.add_action_callback("moveSelection") do |wdl, layerId|
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

		@dialog.add_action_callback("purgeLayersFromJS") do |wdl, act|
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
			@model.commit_operation
		end#callback purgeLayersFromJS

		@dialog.add_action_callback("getLayerDictID") do |wdl, act|
			# @model.start_operation("Add group layer", true, false, true)
			self.initializeLayerDictID
			sendLayerDictID = "receiveLayerDictID('#{@layerDictID}');"
			@dialog.execute_script(sendLayerDictID)
			self.incLayerDictID
			# @model.commit_operation
		end#callback getLayerDictID

		@dialog.add_action_callback("storeSerialize") do
			self.storeSerialize
		end#callback storeSerialize

		@dialog.add_action_callback("sortItem") do |wdl, serialized|
			@model.start_operation("Sort layer/group", true)
			@dialog.execute_script("storeSerialize();")
			@model.commit_operation
		end#callback 

		@dialog.add_action_callback("iframeTrack") do
			self.iframeTrack
		end#callback

		@dialog.add_action_callback("openOptionsDialog") do
			self.show_layerspanel_dlg_options
		end#callback

		@dialog.add_action_callback("undo") do
			Sketchup.send_action("editUndo:")
		end#callback 

		@dialog.add_action_callback("redo") do
			Sketchup.send_action("editRedo:")
		end#callback

		@dialog.set_on_close do
			# @dialog.execute_script("storeSerialize();")
		end

		@dialog.add_action_callback("checkIEwarning") do |wdl, action|
			self.checkIEwarning
		end#callback render

		@dialog.add_action_callback("startup") do |wdl, action|
			self.dialogStartup
		end#callback render

		@dialog.add_action_callback("minimizeDialog") do |wdl, size|
			sizeHash = self.jsonToHash(size)
			@dialog.set_size(sizeHash['width'].to_i + 16, 37)
			@heightBeforeMinimize = sizeHash['height']
		end#callback render

		@dialog.add_action_callback("maximizeDialog") do |wdl, size|
			sizeHash = self.jsonToHash(size)
			@dialog.set_size(sizeHash['width'].to_i + 16, @heightBeforeMinimize + 34)
		end#callback render
		
		
		############
		if closed
			if MAC
				@dialog.show_modal()
			else
				@dialog.show()
			end#if
			self.make_toolwindow_frame("Layers Panel")
			true
		end#if
		
	end#def
	# self.createDialog
	
  
  
	### ENTITYOBSERVER ### ------------------------------------------------------
	#Watches for layers to be hidden or renamed (Which layers observer doesn't support)
	
	class JBB_LP_EntityObserver < Sketchup::EntityObserver
		def onChangeEntity(layer)
			if layer.deleted? == false
				# puts 'onchangeentity ' + layer.name
				if layer.get_attribute("jbb_layerspanel", "ID") != nil #Verify entity exists (onChangeEntity mistrigger)
					# puts layer.name
					if layer == JBB_LayersPanel.layers[0]
						layerId = 0
					else
						layerId = layer.get_attribute("jbb_layerspanel", "ID")
					end#if
					
					if layer.visible?
						showLayerFromRuby = "showLayerFromRuby('#{layerId}');"
						JBB_LayersPanel.dialog.execute_script(showLayerFromRuby)
						timer_04b = UI.start_timer(0, false) {
							UI.stop_timer(timer_04b)
							JBB_LayersPanel.unHideByGroup(layerId)
						}
					else
						hideLayerFromRuby = "hideLayerFromRuby('#{layerId}');"
						JBB_LayersPanel.dialog.execute_script(hideLayerFromRuby)
					end#if
					
					renameLayerFromRuby = "renameLayerFromRuby('#{layerId}', '#{layer.name}');"
					JBB_LayersPanel.dialog.execute_script(renameLayerFromRuby)
					
					if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
						timer_04 = UI.start_timer(0, false) {
							UI.stop_timer(timer_04)
							if	JBB_LayersPanel.model.pages.selected_page != nil
								JBB_LayersPanel.model.pages.selected_page.update(32) #Update page's layers state
								# puts "update " + JBB_LayersPanel.model.pages.selected_page.name
							end#if
						}
					end#if
				end#if
			end#if
		end#def
	end#class
	
	@jbb_lp_entityObserver = JBB_LP_EntityObserver.new
	
	# Attach the observer to layer0
	@layers[0].add_observer(@jbb_lp_entityObserver)



	### LAYERSOBSERVER ### ------------------------------------------------------
	
	# Layers observer
	class JBB_LP_layersObserver < Sketchup::LayersObserver
	
		def onLayerAdded(layers, layer)
			timer_02 = UI.start_timer(0, false) {
				begin
				UI.stop_timer(timer_02)
				JBB_LayersPanel.model.start_operation("Add layer", true, true, true)
					JBB_LayersPanel.initializeLayerDictID
					JBB_LayersPanel.IdLayer(layer)
					if JBB_LayersPanel.dialog
						layerIdForJS = layer.get_attribute("jbb_layerspanel", "ID")
						addLayerFromRuby = "addLayerFromRuby('#{layer.name}', '#{layerIdForJS}');"
						JBB_LayersPanel.dialog.execute_script(addLayerFromRuby)
						showLayerFromRuby = "showLayerFromRuby('#{layerIdForJS}');"
						JBB_LayersPanel.dialog.execute_script(showLayerFromRuby)
					end#if
				JBB_LayersPanel.model.commit_operation
				JBB_LayersPanel.model.start_operation("Add layer", true, false, true)
					# puts "lo"
					layer.set_attribute("jbb_layerspanel", "observer", 1)
					layer.add_observer(JBB_LayersPanel.jbb_lp_entityObserver)
				JBB_LayersPanel.model.commit_operation
				rescue
				end
			}
		end#onLayerAdded
		
		def onLayerRemoved(layers, layer)
			layerId = layer.get_attribute("jbb_layerspanel", "ID")
			deleteLayerFromRuby = "deleteLayerFromRuby('#{layerId}');"
			JBB_LayersPanel.dialog.execute_script(deleteLayerFromRuby)
            timer_03 = UI.start_timer(0, false) {
                UI.stop_timer(timer_03)
				if JBB_LayersPanel.allowSerialize == true
					JBB_LayersPanel.dialog.execute_script("storeSerialize();")
				end#if
            }
		end#onLayerRemoved
		
		
		def onCurrentLayerChanged(layers, layer)
			if Sketchup.read_default("jbb_layers_panel", "display_warning") != false
				tool_name = Sketchup.active_model.tools.active_tool_name
				if layer != layers[0]
					if tool_name == "SketchTool" || tool_name == "RectangleTool" || tool_name == "CircleTool" || tool_name == "ArcTool" || tool_name == "PolyTool" || tool_name == "FreehandTool"
						JBB_LayersPanel.show_layerspanel_dlg_warning
					end#if
				else
					JBB_LayersPanel.close_layerspanel_dlg_warning
				end#if
			end#if
			if JBB_LayersPanel.dialog
				JBB_LayersPanel.dialog.execute_script('getActiveLayer();')
			end#if
		end#onLayerRemoved
		
	end#JBB_LP_layersObserver
	
	@jbb_lp_layersObserver = JBB_LP_layersObserver.new
	
	# Attach the observer.
	@layers.add_observer(@jbb_lp_layersObserver)
	
  
  
	### APPOBSERVER ### ------------------------------------------------------
	
	class JBB_LP_AppObserver < Sketchup::AppObserver

		def onNewModel(newModel)
            timer_05 = UI.start_timer(0, false) {
                UI.stop_timer(timer_05)
				JBB_LayersPanel.openedModel(newModel)
			}
		end#def

		def onOpenModel(newModel)
            timer_06 = UI.start_timer(0, false) {
				UI.stop_timer(timer_06)
				JBB_LayersPanel.openedModel(newModel)
			}
		end#def

	end#class
	
	def self.openedModel(newModel)
		@model.start_operation("Initialize Layers Panel", true)
			self.createDialog
			
			JBB_LayersPanel.model = newModel
			JBB_LayersPanel.layers = newModel.layers
			
			JBB_LayersPanel.layerDictID = nil
			
			JBB_LayersPanel.model.add_observer(@jbb_lp_modelObserver)
			JBB_LayersPanel.model.pages.add_observer(@jbb_lp_pagesObserver)
			JBB_LayersPanel.layers.add_observer(@jbb_lp_layersObserver)
			
			JBB_LayersPanel.layers.each{|layer|
				layer.remove_observer(@jbb_lp_entityObserver) #Reset observer to make sure layer is watched
				layer.add_observer(@jbb_lp_entityObserver)
				layer.set_attribute("jbb_layerspanel", "observer", 1)
			}
			
			JBB_LayersPanel.dialog.execute_script("reloadDialog();")
		@model.commit_operation
	end#def
	
	@jbb_lp_appObserver = JBB_LP_AppObserver.new

	# Attach the observer
	Sketchup.add_observer(@jbb_lp_appObserver)
	
  
  
	### MODELOBSERVER ### ------------------------------------------------------
	
	class JBB_LP_ModelObserver < Sketchup::ModelObserver
		def onTransactionUndo(model)
			JBB_LayersPanel.dialog.execute_script("emptyOl();")
			JBB_LayersPanel.getModelLayers(false)
			JBB_LayersPanel.getActiveLayer()
			JBB_LayersPanel.getCollapsedGroups()
		end#def
		def onTransactionRedo(model)
			JBB_LayersPanel.dialog.execute_script("emptyOl();")
			JBB_LayersPanel.getModelLayers(false)
			JBB_LayersPanel.getActiveLayer()
			JBB_LayersPanel.getCollapsedGroups()
		end#def
	end#class
	
	@jbb_lp_modelObserver = JBB_LP_ModelObserver.new

	# Attach the observer
	@model.add_observer(@jbb_lp_modelObserver)
	
  
  
	### PAGESOBSERVER ### ------------------------------------------------------
	
	class JBB_LP_PagesObserver < Sketchup::PagesObserver
		def onContentsModified(pages)
			activePage = JBB_LayersPanel.model.pages.selected_page
			
			if JBB_LayersPanel.check == 0 #First trigger
				JBB_LayersPanel.checkPageUpdate
				JBB_LayersPanel.check = 1
			
			else #second trigger
				JBB_LayersPanel.previousPageDict = activePage.attribute_dictionary "jbb_layerspanel_collapseGroups", true
				JBB_LayersPanel.previousPageDict2 = activePage.attribute_dictionary "jbb_layerspanel_tempHiddenGroups", true
				JBB_LayersPanel.previousPageDict3 = activePage.attribute_dictionary "jbb_layerspanel_tempHiddenByGroupLayers", true
				JBB_LayersPanel.previousPageDict4 = activePage.attribute_dictionary "jbb_layerspanel_render", true
				
				dict = activePage.attribute_dictionary "jbb_layerspanel_hiddenGroups", true
				dict2 = activePage.attribute_dictionary "jbb_layerspanel_hiddenByGroupLayers", true
				
				JBB_LayersPanel.check = 0
				
				timer_07 = UI.start_timer(0, false) {
					UI.stop_timer(timer_07)
					dict.each { | key, value |
					   activePage.set_attribute("jbb_layerspanel_tempHiddenGroups", key, value)
					}
					dict2.each { | key, value |
					   activePage.set_attribute("jbb_layerspanel_tempHiddenByGroupLayers", key, value)
					}
					JBB_LayersPanel.selectedPageLayers = activePage.layers
				
					JBB_LayersPanel.dialog.execute_script("emptyOl();")
					JBB_LayersPanel.getModelLayers(false)
					JBB_LayersPanel.getActiveLayer()
					JBB_LayersPanel.getCollapsedGroups()
				}
			end#if
		end#def
		def onElementAdded(pages, page)
			if JBB_LayersPanel.previousPageDict == nil
				dict = JBB_LayersPanel.model.attribute_dictionary "jbb_layerspanel_collapseGroups", true
			else
				dict = JBB_LayersPanel.previousPageDict
			end#if
			
			if JBB_LayersPanel.previousPageDict2 == nil
				dict2 = JBB_LayersPanel.model.attribute_dictionary "jbb_layerspanel_hiddenGroups", true
			else
				dict2 = JBB_LayersPanel.previousPageDict2
			end#if
			
			if JBB_LayersPanel.previousPageDict3 == nil
				dict3 = JBB_LayersPanel.model.attribute_dictionary "jbb_layerspanel_hiddenByGroupLayers", true
			else
				dict3 = JBB_LayersPanel.previousPageDict3
			end#if
			
			if JBB_LayersPanel.previousPageDict4 == nil
				dict4 = JBB_LayersPanel.model.attribute_dictionary "jbb_layerspanel_render", true
			else
				dict4 = JBB_LayersPanel.previousPageDict4
			end#if
			
			# puts "added " + page.name
			JBB_LayersPanel.check = 1
			
            timer_08 = UI.start_timer(0, false) {
                UI.stop_timer(timer_08)
				dict.each { | key, value |
				   page.set_attribute("jbb_layerspanel_collapseGroups", key, value)
				}
				dict2.each { | key, value |
				   page.set_attribute("jbb_layerspanel_hiddenGroups", key, value)
				}
				dict3.each { | key, value |
				   page.set_attribute("jbb_layerspanel_hiddenByGroupLayers", key, value)
				}
				dict4.each { | key, value |
				   page.set_attribute("jbb_layerspanel_render", key, value)
				}
				activePage = JBB_LayersPanel.model.pages.selected_page
				JBB_LayersPanel.model.pages.selected_page = activePage
			}
		end#def
	end#class
	
	def self.checkPageUpdate
		if Sketchup.read_default("jbb_layers_panel", "auto_update") == false
			activePage = Sketchup.active_model.pages.selected_page
			begin
				if @selectedPageLayers == activePage.layers
					# puts "Not updated"
				else
					# puts "Updated !"
					self.updateDictionaries(activePage)
				end#if
			rescue
			end
			
			begin
				@selectedPageLayers = activePage.layers
			rescue
			end
		end#if
	end#def
	
	def self.updateDictionaries(activePage)
		timer_09 = UI.start_timer(0, false) {
			UI.stop_timer(timer_09)
			dict = activePage.attribute_dictionary "jbb_layerspanel_tempHiddenGroups", true
			dict2 = activePage.attribute_dictionary "jbb_layerspanel_tempHiddenByGroupLayers", true
			
			dict.each { | key, value |
			   activePage.set_attribute("jbb_layerspanel_hiddenGroups", key, value)
			}
			dict2.each { | key, value |
			   activePage.set_attribute("jbb_layerspanel_hiddenByGroupLayers", key, value)
			}
		}
	end#def
	
	# Update page layers
	def self.startUpdateTimer
		begin
			@selectedPageLayers = Sketchup.active_model.pages.selected_page.layers
		rescue
		end
		
		@timerCheckUpdate = UI.start_timer(0.3, true) {
			if @check == 0
				self.checkPageUpdate
			end#if
		}
	end#def
	def self.stopUpdateTimer
		UI.stop_timer(@timerCheckUpdate)
	end#def
	
	if Sketchup.read_default("jbb_layers_panel", "auto_update") == false
		self.startUpdateTimer
	end#if
	
	@jbb_lp_pagesObserver = JBB_LP_PagesObserver.new

	# Attach the observer
	@model.pages.add_observer(@jbb_lp_pagesObserver)



	### MENU & TOOLBARS ### ------------------------------------------------------
	
	def self.toggle_layerspanel_dlg
		if @dialog && @dialog.visible?
			@dialog.close
			# @dialog = nil
			false
		else
			self.createDialog
			if MAC
				@dialog.show_modal()
			else
				@dialog.show()
			end#if
			self.make_toolwindow_frame("Layers Panel")
			true
		end#if
	end#def
	
	# Thomthom's snippet :
	# http://sketchucation.com/forums/viewtopic.php?p=280331#p280331
	def self.make_toolwindow_frame(window_title)
		if WIN
			# Retrieves the window handle to the active window attached to the calling
			# thread's message queue. 
			hwnd = GetActiveWindow.call
			return nil if hwnd.nil?

			# Verify window text as extra security to ensure it's the correct window.
			buf_len = GetWindowTextLength.call(hwnd)
			return nil if buf_len == 0

			str = ' ' * (buf_len + 1)
			result = GetWindowText.call(hwnd, str, str.length)
			return nil if result == 0

			return nil unless str.strip == window_title.strip

			# Set frame to Toolwindow
			style = GetWindowLong.call(hwnd, GWL_EXSTYLE)
			return nil if style == 0

			result = SetWindowLong.call(hwnd, GWL_EXSTYLE, style | WS_EX_TOOLWINDOW)
			return nil if result == 0

			# Remove and disable minimze and maximize
			# http://support.microsoft.com/kb/137033
			style = GetWindowLong.call(hwnd, GWL_STYLE)
			return nil if style == 0

			style = style & ~WS_MINIMIZEBOX
			style = style & ~WS_MAXIMIZEBOX
			result = SetWindowLong.call(hwnd, GWL_STYLE,  style)
			return nil if result == 0

			# Refresh the window frame
			result = SetWindowPos.call(hwnd, 0, 0, 0, 0, 0, SWP_FRAMECHANGED|SWP_NOSIZE|SWP_NOMOVE)
			result != 0
		end#if
	end#def
	
	def self.layerspanel_dlg_validation_proc
		if @dialog && @dialog.visible?
			MF_CHECKED
		else
			MF_UNCHECKED
		end#if
	end#def
  
	unless file_loaded?( __FILE__ )
		# Commands
		cmd = UI::Command.new( 'Layers Panel' ) { self.toggle_layerspanel_dlg }
		cmd.status_bar_text = 'Show or hide the Layers Panel.'
		cmd.small_icon = "lp_16.png"
		cmd.large_icon = "lp_24.png"
		cmd.tooltip = 'Layers Panel'
		cmd.set_validation_proc { self.layerspanel_dlg_validation_proc }
		cmd_toggle_layerspanel_dlg = cmd

		window_menu = UI.menu("Window")
		lp_menu = window_menu.add_submenu("Layers Panel")
		lp_menu.add_item( cmd_toggle_layerspanel_dlg )
		lp_menu.add_item( "Options" ) { JBB_LayersPanel.show_layerspanel_dlg_options }
		
		layerspanel_tb = UI::Toolbar.new "Layers Panel"
		layerspanel_tb.add_item cmd_toggle_layerspanel_dlg
		layerspanel_tb.show
	end
	
	
	
	### WARNING LAYER0 ### ------------------------------------------------------
		
	# Create the WebDialog instance
	def self.createDialogWarning
		@dialogWarning = UI::WebDialog.new("Layers Panel Warning", false, "LayersPanelWarning", 265, 65, 300, 200, false)
		@dialogWarning.set_size(265,65)
		@html_path2 = File.dirname( __FILE__ ) + "/warning.html"
		@dialogWarning.set_file(@html_path2)
		
		@dialogWarning.add_action_callback("displayWarning") do  |wdl, display|
			# puts display
			if display == "true"
				Sketchup.write_default("jbb_layers_panel", "display_warning", true)
			else
				Sketchup.write_default("jbb_layers_panel", "display_warning", false)
			end
		end#callback
	end#def
	
	def self.show_layerspanel_dlg_warning
		if !@dialogWarning || !@dialogWarning.visible?
			self.createDialogWarning
			@dialogWarning.show()
			self.make_toolwindow_frame("Layers Panel Warning")
			@dialogWarning.execute_script("window.blur()")
		end#if
	end#def
	
	def self.close_layerspanel_dlg_warning
		if @dialogWarning && @dialogWarning.visible?
			@dialogWarning.close
		end#if
	end#def
	
	class JBB_LP_ToolsObserver < Sketchup::ToolsObserver
		def onActiveToolChanged(tools, tool_name, tool_id)
			if Sketchup.read_default("jbb_layers_panel", "display_warning") != false
				# puts "onActiveToolChanged: " + tool_name.to_s
				if tool_name != "CameraOrbitTool"
					if tool_name == "SketchTool" || tool_name == "RectangleTool" || tool_name == "CircleTool" || tool_name == "ArcTool" || tool_name == "PolyTool" || tool_name == "FreehandTool"
						if Sketchup.active_model.active_layer != Sketchup.active_model.layers[0]
							JBB_LayersPanel.show_layerspanel_dlg_warning
						end#if
					else
						JBB_LayersPanel.close_layerspanel_dlg_warning
					end#if
				end#if
			end#if
		end
	end
	@model.tools.add_observer(JBB_LP_ToolsObserver.new)
	
	
	
	### OPTIONS DIALOG ### ------------------------------------------------------
		
	# Create the WebDialog instance
	def self.createDialogOptions
		@dialogOptions = UI::WebDialog.new("Layers Panel options", false, "LayersPanelOptions", 250, 100, 300, 200, false)
		@dialogOptions.set_size(270,320)
		@html_path3 = File.dirname( __FILE__ ) + "/options.html"
		@dialogOptions.set_file(@html_path3)
		
		@dialogOptions.add_action_callback("startup") do  |wdl, startup|
			if startup == "true"
				Sketchup.write_default("jbb_layers_panel", "startup", true)
			else
				Sketchup.write_default("jbb_layers_panel", "startup", false)
			end
		end#callback
		
		@dialogOptions.add_action_callback("displayWarning") do  |wdl, display|
			# puts display
			if display == "true"
				Sketchup.write_default("jbb_layers_panel", "display_warning", true)
			else
				Sketchup.write_default("jbb_layers_panel", "display_warning", false)
			end
		end#callback
		
		@dialogOptions.add_action_callback("displayRender") do  |wdl, display|
			# puts display
			if display == "true"
				Sketchup.write_default("jbb_layers_panel", "display_render", true)
			else
				Sketchup.write_default("jbb_layers_panel", "display_render", false)
			end
		end#callback
		
		@dialogOptions.add_action_callback("displayIE") do  |wdl, display|
			# puts display
			if display == "true"
				Sketchup.write_default("jbb_layers_panel", "display_IE", true)
			else
				Sketchup.write_default("jbb_layers_panel", "display_IE", false)
			end
		end#callback
		
		@dialogOptions.add_action_callback("autoUpdate") do  |wdl, autoUpdate|
			# puts autoUpdate
			if autoUpdate == "true"
				Sketchup.write_default("jbb_layers_panel", "auto_update", true)
				begin
					self.stopUpdateTimer
				rescue
				end
			else
				Sketchup.write_default("jbb_layers_panel", "auto_update", false)
				self.startUpdateTimer
			end
		end#callback
		
		@dialogOptions.add_action_callback("close") do  |wdl, display|
			JBB_LayersPanel.close_layerspanel_dlg_options
			JBB_LayersPanel.dialog.execute_script("reloadDialog();")
		end#callback
		
		@dialogOptions.add_action_callback("getOptions") do  ||
			startup = Sketchup.read_default("jbb_layers_panel", "startup")
			displayRender = Sketchup.read_default("jbb_layers_panel", "display_render")
			displayWarning = Sketchup.read_default("jbb_layers_panel", "display_warning")
			displayIE = Sketchup.read_default("jbb_layers_panel", "display_IE")
			autoUpdate = Sketchup.read_default("jbb_layers_panel", "auto_update")
			
			if startup == true
				@dialogOptions.execute_script("checkStartup()")
			end#if
			if displayRender == false
				@dialogOptions.execute_script("uncheckRender()")
			end#if
			if displayWarning == false
				@dialogOptions.execute_script("uncheckWarning()")
			end#if
			if displayIE == false
				@dialogOptions.execute_script("uncheckIE()")
			end#if
			if autoUpdate == true
				@dialogOptions.execute_script("checkUpdate()")
			end#if
		end#callback
	end#def
	
	def self.show_layerspanel_dlg_options
		if !@dialogOptions || !@dialogOptions.visible?
			self.createDialogOptions
			@dialogOptions.show()
			self.make_toolwindow_frame("Layers Panel options")
			@dialogOptions.execute_script("window.blur()")
		end#if
	end#def
	
	def self.close_layerspanel_dlg_options
		if @dialogOptions && @dialogOptions.visible?
			@dialogOptions.close
		end#if
	end#def
	
	
	
	### STARTUP TRIGGERS ### ------------------------------------------------------
	
	self.createDialog
	
	if WIN
		self.openedModel(Sketchup.active_model)
	end#if

	if Sketchup.read_default("jbb_layers_panel", "startup") == true
		@dialog.show()
		self.make_toolwindow_frame("Layers Panel")
	end#if
	
end#module

#-----------------------------------------------------------------------------
file_loaded( File.basename(__FILE__) )
