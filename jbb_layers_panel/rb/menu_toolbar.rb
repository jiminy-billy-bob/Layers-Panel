
module JBB_LayersPanel

	
	
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
		cmd.small_icon = "../lp_16.png"
		cmd.large_icon = "../lp_24.png"
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


end#module