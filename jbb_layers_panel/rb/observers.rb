
module JBB_LayersPanel

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
						done_04b = false
						timer_04b = UI.start_timer(0, false) {
							next if done_04b
							done_04b = true
							if JBB_LayersPanel.allowSerialize == true
								JBB_LayersPanel.model.start_operation("Unhide layer", true, false, true)
								JBB_LayersPanel.unHideByGroup(layerId)
								JBB_LayersPanel.model.commit_operation
							end#if
						}
					else
						hideLayerFromRuby = "hideLayerFromRuby('#{layerId}');"
						JBB_LayersPanel.dialog.execute_script(hideLayerFromRuby)
					end#if
					
					renameLayerFromRuby = "renameLayerFromRuby('#{layerId}', '#{layer.name}');"
					JBB_LayersPanel.dialog.execute_script(renameLayerFromRuby)
					
					if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
						done_04 = false
						timer_04 = UI.start_timer(0, false) {
							next if done_04
							done_04 = true
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

	if MAC
		# Attach the observer to layer0
		@layers[0].add_observer(@jbb_lp_entityObserver)
	end#if



	### LAYERSOBSERVER ### ------------------------------------------------------

	# Layers observer
	class JBB_LP_layersObserver < Sketchup::LayersObserver

		def onLayerAdded(layers, layer)
			done_02 = false
			timer_02 = UI.start_timer(0, false) {
				next if done_02
				done_02 = true
				if JBB_LayersPanel.allowSerialize == true
					if Sketchup.active_model.tools.active_tool_name != 'PasteTool'
						JBB_LayersPanel.model.start_operation("Add layer", true, true, true)
					end#if
						JBB_LayersPanel.layers.each {| l | layer = l }
						JBB_LayersPanel.initializeLayerDictID
						JBB_LayersPanel.IdLayer(layer)
						if JBB_LayersPanel.dialog
							layerIdForJS = layer.get_attribute("jbb_layerspanel", "ID")
							addLayerFromRuby = "addLayerFromRuby('#{layer.name}', '#{layerIdForJS}');"
							JBB_LayersPanel.dialog.execute_script(addLayerFromRuby)
							showLayerFromRuby = "showLayerFromRuby('#{layerIdForJS}');"
							JBB_LayersPanel.dialog.execute_script(showLayerFromRuby)
							if RUBY_VERSION.to_i >= 2
								JBB_LayersPanel.setColorFromRuby(layer)
							end#if
						end#if
						JBB_LayersPanel.checkEntityObserver(layer)
						JBB_LayersPanel.storeSerialize
					if Sketchup.active_model.tools.active_tool_name != 'PasteTool'
						JBB_LayersPanel.model.commit_operation
					end#if
				end#if
				if layer.name == "Google Earth Snapshot"
					UI.start_timer(0, false) {
						JBB_LayersPanel.dialog.execute_script("reloadDialog();")
					}
				end#if
			}
		end#onLayerAdded
		
		def onLayerRemoved(layers, layer)
			layerId = layer.get_attribute("jbb_layerspanel", "ID")
			deleteLayerFromRuby = "deleteLayerFromRuby('#{layerId}');"
			JBB_LayersPanel.dialog.execute_script(deleteLayerFromRuby)
			done_03 = false
			timer_03 = UI.start_timer(0, false) {
				next if done_03
				done_03 = true
				if JBB_LayersPanel.allowSerialize == true
					JBB_LayersPanel.model.start_operation("Delete layer", true, false, true)
					JBB_LayersPanel.storeSerialize
					JBB_LayersPanel.model.commit_operation
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

	if MAC
		# Attach the observer.
		@layers.add_observer(@jbb_lp_layersObserver)
	end#if



	### MODELOBSERVER ### ------------------------------------------------------

	class JBB_LP_ModelObserver < Sketchup::ModelObserver
		def onTransactionUndo(model)
			# puts "undo"
			JBB_LayersPanel.allowSerialize = false
			JBB_LayersPanel.dialog.execute_script("emptyOl();")
			JBB_LayersPanel.getModelLayers(false)
			JBB_LayersPanel.getActiveLayer()
			JBB_LayersPanel.getCollapsedGroups()
			JBB_LayersPanel.getLayerColors()
			done_19 = false
			timer_19 = UI.start_timer(0, false) {
				next if done_19
				done_19 = true
				JBB_LayersPanel.allowSerialize = true
			}
		end#def
		def onTransactionRedo(model)
			# puts "redo"
			JBB_LayersPanel.allowSerialize = false
			JBB_LayersPanel.dialog.execute_script("emptyOl();")
			JBB_LayersPanel.getModelLayers(false)
			JBB_LayersPanel.getActiveLayer()
			JBB_LayersPanel.getCollapsedGroups()
			JBB_LayersPanel.getLayerColors()
			done_18 = false
			timer_18 = UI.start_timer(0, false) {
				next if done_18
				done_18 = true
				JBB_LayersPanel.allowSerialize = true
			}
		end#def
	end#class

	@jbb_lp_modelObserver = JBB_LP_ModelObserver.new

	if MAC
		# Attach the observer
		@model.add_observer(@jbb_lp_modelObserver)
	end#if



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
				
				done_07 = false
				timer_07 = UI.start_timer(0, false) {
					next if done_07
					done_07 = true
					dict.each { | key, value |
					   activePage.set_attribute("jbb_layerspanel_tempHiddenGroups", key, value)
					}
					dict2.each { | key, value |
					   activePage.set_attribute("jbb_layerspanel_tempHiddenByGroupLayers", key, value)
					}
					JBB_LayersPanel.selectedPageLayers = activePage.layers
				
					JBB_LayersPanel.dialog.execute_script("emptyOl();")
					JBB_LayersPanel.getModelLayers(false)
					JBB_LayersPanel.getLayerColors()
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
			
			done_08 = false
			timer_08 = UI.start_timer(0, false) {
				next if done_08
				done_08 = true
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
		done_09 = false
		timer_09 = UI.start_timer(0, false) {
			next if done_09
			done_09 = true
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

	if MAC
		# Attach the observer
		@model.pages.add_observer(@jbb_lp_pagesObserver)
	end#if



	### RENDERINGOPTIONSOBSERVER ### ------------------------------------------------------

	#Track active model change
	class JBB_LP_RenderingOptionsObserver < Sketchup::RenderingOptionsObserver
		def onRenderingOptionsChanged(renderoptions, type)
			if type == 16
				if JBB_LayersPanel.model.rendering_options["DisplayColorByLayer"] == true
					JBB_LayersPanel.dialog.execute_script("toogleColorsButton(true);")
				else
					JBB_LayersPanel.dialog.execute_script("toogleColorsButton(false);")
				end#if
			end#if
		end
	end#def
	
	@jbb_lp_renderingOptionsObserver = JBB_LP_RenderingOptionsObserver.new
	
	if MAC
		# Attach the observer
		@model.rendering_options.add_observer(@jbb_lp_renderingOptionsObserver)
	end#if



	### VIEWOBSERVER ### ------------------------------------------------------

	#Track active model change
	class JBB_LP_ViewObserver < Sketchup::ViewObserver
		def onViewChanged(view) 
			if MAC
				# puts Sketchup.active_model.definitions.entityID
				if JBB_LayersPanel.lastActiveModelID != Sketchup.active_model.definitions.entityID
					JBB_LayersPanel.resetVariables
					JBB_LayersPanel.dialogStartup #Reload main dialog
				end#if
				JBB_LayersPanel.lastActiveModelID = Sketchup.active_model.definitions.entityID
			end#if
		end
	end#def
	
	if MAC
		@jbb_lp_viewObserver = JBB_LP_ViewObserver.new

		# Attach the observer
		@model.active_view.add_observer(@jbb_lp_viewObserver)
	end#if



	### APPOBSERVER ### ------------------------------------------------------

	class JBB_LP_AppObserver < Sketchup::AppObserver

		def onNewModel(newModel)
			done_05 = false
			timer_05 = UI.start_timer(0, false) {
				next if done_05
				done_05 = true
				JBB_LayersPanel.openedModel(newModel)
			}
		end#def

		def onOpenModel(newModel)
			done_06 = false
			timer_06 = UI.start_timer(0, false) {
				next if done_06
				done_06 = true
				JBB_LayersPanel.openedModel(newModel)
			}
		end#def

	end#class

	def self.openedModel(newModel)
		self.createDialog
		JBB_LayersPanel.model = newModel
		JBB_LayersPanel.layers = newModel.layers
		
		JBB_LayersPanel.layerDictID = nil
		
		JBB_LayersPanel.model.add_observer(JBB_LayersPanel.jbb_lp_modelObserver)
		JBB_LayersPanel.model.pages.add_observer(JBB_LayersPanel.jbb_lp_pagesObserver)
		JBB_LayersPanel.layers.add_observer(JBB_LayersPanel.jbb_lp_layersObserver)
		@model.rendering_options.add_observer(@jbb_lp_renderingOptionsObserver)
		
		if MAC #Track active model change
			JBB_LayersPanel.model.active_view.add_observer(JBB_LayersPanel.jbb_lp_viewObserver)
		end#if
		
		JBB_LayersPanel.layers.each{|layer|
			JBB_LayersPanel.checkEntityObserver(layer)
		}
		
		JBB_LayersPanel.dialog.execute_script("reloadDialog();")
	end#def

	@jbb_lp_appObserver = JBB_LP_AppObserver.new

	# Attach the observer
	Sketchup.add_observer(@jbb_lp_appObserver)


end#module