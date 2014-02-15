
module JBB_LayersPanel

	
	### OPTIONS DIALOG ### ------------------------------------------------------
		
	# Create the WebDialog instance
	def self.createDialogDebug
		@dialogDebug = WebdialogBridge.new("Layers Panel debug", false, "LayersPanelDebug", 250, 100, 300, 200, false)
		@dialogDebug.set_size(350,350)
		@dialogDebug.set_file(@html_path4)
		
		@dialogDebug.add_bridge_callback("getLayersIDs") do  |wdl, startup|
			getDictID = "getDictID('#{@model.get_attribute("jbb_layerspanel", "layerDictID")}');"
			@dialogDebug.execute_script(getDictID)
			
			@layers.each{|layer| 
					addLayer = "addLayer('#{layer.name}', '#{layer.get_attribute("jbb_layerspanel", "ID")}');"
					@dialogDebug.execute_script(addLayer)
				}
		end#callback
		
		@dialogDebug.add_bridge_callback("debugLayersIDs") do  |wdl, action|
			@model.start_operation("Debug Layers Panel", true)
				self.initializeLayerDictID
				highestID = 0
				@layers.each{|layer| 
						if layer.get_attribute("jbb_layerspanel", "ID") > highestID.to_i
							highestID = layer.get_attribute("jbb_layerspanel", "ID")
						end#if
					}
				if @model.get_attribute("jbb_layerspanel", "layerDictID") < highestID.to_i + 1
					@model.set_attribute("jbb_layerspanel", "layerDictID", highestID.to_i+1)
				end#if
					
				ids = nil
				ids = Array.new
				@layers.each{|layer| 
						if ids[layer.get_attribute("jbb_layerspanel", "ID")] != nil
							puts "Fixed ID for \"" + layer.name + "\""
							layer.set_attribute("jbb_layerspanel", "ID", @layerDictID)
							self.incLayerDictID
						end#if
						ids[layer.get_attribute("jbb_layerspanel", "ID")] = layer.name
					}
					
				@dialogDebug.execute_script("reloadDialog();")
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