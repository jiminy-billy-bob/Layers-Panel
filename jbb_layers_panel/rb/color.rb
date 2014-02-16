
module JBB_LayersPanel
if RUBY_VERSION.to_i >= 2
	
	### OPTIONS DIALOG ### ------------------------------------------------------
		
	# Create the WebDialog instance
	def self.createDialogColor
		@dialogColor = WebdialogBridge.new("Layers Panel color picker", false, "LayersPanelColor", 250, 100, 300, 200, false)
		@dialogColor.set_size(555,360)
		@dialogColor.set_file(@html_path5)
		
		
		@dialogColor.add_bridge_callback("setLayerColor") do |wdl, json|
			@model.start_operation("Change layer color", true)
				hash = self.jsonToHash(json)
				layerID = hash['layerID']
				@layers.each{|layer| 
					if layer.get_attribute("jbb_layerspanel", "ID").to_i == layerID.to_i
						layer.color = Sketchup::Color.new(hash['red'], hash['green'], hash['blue'])
						break
					end#if
				}
				self.getLayerColors()
				self.close_layerspanel_dlg_color
			@model.commit_operation
		end#callback
		
		@dialogColor.add_bridge_callback("closeDialog") do |wdl, json|
			self.close_layerspanel_dlg_color
		end#callback
	end#def
	
	def self.show_layerspanel_dlg_color
		if !@dialogColor || !@dialogColor.visible?
			self.createDialogColor
			self.showDialog(@dialogColor)
			self.make_toolwindow_frame("Layers Panel color picker")
			@dialogColor.execute_script("window.blur()")
		end#if
	end#def
	
	def self.close_layerspanel_dlg_color
		if @dialogColor && @dialogColor.visible?
			@dialogColor.close
		end#if
	end#def

end#if
end#module