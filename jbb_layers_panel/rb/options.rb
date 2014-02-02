
module JBB_LayersPanel

	
	### OPTIONS DIALOG ### ------------------------------------------------------
		
	# Create the WebDialog instance
	def self.createDialogOptions
		@dialogOptions = WebdialogBridge.new("Layers Panel options", false, "LayersPanelOptions", 250, 100, 300, 200, false)
		@dialogOptions.set_size(270,280)
		@dialogOptions.set_file(@html_path3)
		
		@dialogOptions.add_bridge_callback("startup") do  |wdl, startup|
			if startup == "true"
				Sketchup.write_default("jbb_layers_panel", "startup", true)
			else
				Sketchup.write_default("jbb_layers_panel", "startup", false)
			end
		end#callback
		
		@dialogOptions.add_bridge_callback("displayWarning") do  |wdl, display|
			# puts display
			if display == "true"
				Sketchup.write_default("jbb_layers_panel", "display_warning", true)
			else
				Sketchup.write_default("jbb_layers_panel", "display_warning", false)
			end
		end#callback
		
		@dialogOptions.add_bridge_callback("displayRender") do  |wdl, display|
			# puts display
			if display == "true"
				Sketchup.write_default("jbb_layers_panel", "display_render", true)
			else
				Sketchup.write_default("jbb_layers_panel", "display_render", false)
			end
		end#callback
		
		@dialogOptions.add_bridge_callback("autoUpdate") do  |wdl, autoUpdate|
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
		
		@dialogOptions.add_bridge_callback("close") do  |wdl, display|
			JBB_LayersPanel.close_layerspanel_dlg_options
			JBB_LayersPanel.dialog.execute_script("reloadDialog();")
		end#callback
		
		@dialogOptions.add_bridge_callback("getOptions") do  ||
			startup = Sketchup.read_default("jbb_layers_panel", "startup")
			displayRender = Sketchup.read_default("jbb_layers_panel", "display_render")
			displayWarning = Sketchup.read_default("jbb_layers_panel", "display_warning")
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
			if autoUpdate == true
				@dialogOptions.execute_script("checkUpdate()")
			end#if
		end#callback
	end#def
	
	def self.show_layerspanel_dlg_options
		if !@dialogOptions || !@dialogOptions.visible?
			self.createDialogOptions
			self.showDialog(@dialogOptions)
			self.make_toolwindow_frame("Layers Panel options")
			@dialogOptions.execute_script("window.blur()")
		end#if
	end#def
	
	def self.close_layerspanel_dlg_options
		if @dialogOptions && @dialogOptions.visible?
			@dialogOptions.close
		end#if
	end#def


end#module