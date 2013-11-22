
module JBB_LayersPanel

	
	### WARNING LAYER0 ### ------------------------------------------------------
		
	# Create the WebDialog instance
	def self.createDialogWarning
		@dialogWarning = UI::WebDialog.new("Layers Panel Warning", false, "LayersPanelWarning", 265, 65, 300, 200, false)
		@dialogWarning.set_size(265,65)
		# @html_path2 = File.dirname( __FILE__ ) + "/warning.html"
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


end#module