
module JBB_LayersPanel

	
	### OPTIONS DIALOG ### ------------------------------------------------------
		
	# Create the WebDialog instance
	def self.createDialogHistory
		@dialogHistory = WebdialogBridge.new("Layers Panel history", false, "LayersPanelHistory", 330, 350, 300, 200, true)
		@dialogHistory.min_width = 330
		@dialogHistory.set_file(@html_path7)
		@serialized_history = nil
		
		@dialogHistory.add_bridge_callback("getItems") do  |wdl, startup|
			@serialized_history = @model.get_attribute("jbb_layerspanel", "serialized_history")
			if @serialized_history
				i = 0
				@serialized_history.each{|item|
					addItem = "addItem('#{i}', '#{item[0]}', '#{item[1]}', '#{item[2]}');"
					@dialogHistory.execute_script(addItem)
					i += 1
				}
			end#if
		end#callback
		
		@dialogHistory.add_bridge_callback("setSerialized") do  |wdl, id|
			if @serialized_history
				serialized = @serialized_history[id.to_i][1]
				@serialized_history.shift if @serialized_history.length >= 200
				@serialized_history << [Time.now.strftime("%Y-%m-%d %H:%M:%S"), serialized, "History"]
				@model.start_operation("Layers Panel history", true)
				self.set_attribute(@model, "jbb_layerspanel", "serialized", serialized)
				self.set_attribute(@model, "jbb_layerspanel", "serialized_history", @serialized_history)
				self.refreshDialog
				@model.commit_operation
			end#if
		end#callback
	end#def
	
	def self.show_layerspanel_dlg_history
		if !@dialogHistory || !@dialogHistory.visible?
			self.createDialogHistory
			self.showDialog(@dialogHistory)
			self.make_toolwindow_frame("Layers Panel history")
			@dialogHistory.execute_script("window.blur()")
		end#if
	end#def
	
	def self.close_layerspanel_dlg_history
		if @dialogHistory && @dialogHistory.visible?
			@dialogHistory.close
		end#if
	end#def


end#module