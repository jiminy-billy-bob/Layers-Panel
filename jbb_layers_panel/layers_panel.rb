#-----------------------------------------------------------------------------
require 'sketchup.rb'
#-----------------------------------------------------------------------------

module JBB_LayersPanel

#-----------------------------------------------------------------------------

	MAC = ( Object::RUBY_PLATFORM =~ /darwin/i ? true : false )
	WIN = ( (Object::RUBY_PLATFORM =~ /mswin/i || Object::RUBY_PLATFORM =~ /mingw/i) ? true : false )

#-----------------------------------------------------------------------------

	if WIN
		
		if RUBY_VERSION.to_i < 2
			require 'jbb_layers_panel/z_win32api/Win32API.so'
		else 
			require 'Win32API'
		end#if

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
	
	@lpversion = "1.0.3"
	@store = "ps"
	
	@isActive = true
	
	@model = Sketchup.active_model
	@layers = @model.layers
	@entityObservers = Hash.new
	@layerDictID = nil
	@dialog = nil
	@allowSerialize = true
	@previousPageDict = nil
	@previousPageDict2 = nil
	@previousPageDict3 = nil
	@previousPageDict4 = nil
	@check = nil
	@selectedPageLayers = nil
	@timerCheckUpdate = nil
	@heightBeforeMinimize = 300
	
	@jbb_lp_pagesObserver = nil
	@jbb_lp_modelObserver = nil
	@jbb_lp_appObserver = nil
	@jbb_lp_entityObserver = nil
	@jbb_lp_layersObserver = nil
	@jbb_lp_viewObserver = nil
	@jbb_lp_renderingOptionsObserver = nil
	
	@lastActiveModelID = nil
	
	@html_path = File.dirname( __FILE__ ) + "/html/layers Panel.html"
	@html_path2 = File.dirname( __FILE__ ) + "/html/warning.html"
	@html_path3 = File.dirname( __FILE__ ) + "/html/options.html"
	@html_path4 = File.dirname( __FILE__ ) + "/html/debug.html"
	@html_path5 = File.dirname( __FILE__ ) + "/html/color.html"
	
	class << self
		attr_accessor :isActive, :model, :layers, :entityObservers, :layerDictID, :dialog, :allowSerialize, :previousPageDict, :previousPageDict2, :previousPageDict3, :previousPageDict4, :check, :selectedPageLayers, :timerCheckUpdate, :heightBeforeMinimize, :jbb_lp_pagesObserver, :jbb_lp_modelObserver,  :jbb_lp_appObserver,  :jbb_lp_entityObserver,  :jbb_lp_layersObserver,  :jbb_lp_viewObserver, :jbb_lp_renderingOptionsObserver, :lastActiveModelID
	end
  
	
	
	require 'jbb_layers_panel/rb/methods.rb'
	
	require 'jbb_layers_panel/rb/dialog.rb'
	
	require 'jbb_layers_panel/rb/observers.rb'
	
	require 'jbb_layers_panel/rb/menu_toolbar.rb'
	
	require 'jbb_layers_panel/rb/warning.rb'
	
	require 'jbb_layers_panel/rb/options.rb'
	
	require 'jbb_layers_panel/rb/debug.rb'
	
	require 'jbb_layers_panel/rb/color.rb'
	
	
	
	### STARTUP TRIGGERS ### ------------------------------------------------------
	
	self.createDialog
	
	if WIN
		self.openedModel(Sketchup.active_model)
	end#if

	if Sketchup.read_default("jbb_layers_panel", "startup") == true
		self.showDialog(@dialog)
		self.make_toolwindow_frame("Layers Panel")
	end#if
	
end#module

#-----------------------------------------------------------------------------
file_loaded( File.basename(__FILE__) )
