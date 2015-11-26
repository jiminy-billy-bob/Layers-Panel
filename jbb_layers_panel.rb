#-------------------------------------------------------------------------------
#
# Layers Panel
#
#-------------------------------------------------------------------------------
#
# Thomas Hauchecorne
#
# OSX support by Thomas Thomassen
#
#-------------------------------------------------------------------------------
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
#-------------------------------------------------------------------------------
#
# BY USING THIS SOFTWARE, YOU AGREE TO SEND ANONYMOUS DATA
# (Completely anonymous data, used to enhance the plugin)
#
#-------------------------------------------------------------------------------

module JBB_LayersPanel

	require 'sketchup.rb'
	require 'extensions.rb'

	#-------------------------------------------------------------------------------
	
	@version = "1.2.2"
	@store = "ps"

	lp_ext = SketchupExtension.new 'Layers Panel', 'jbb_layers_panel/layers_panel.rb'

	lp_ext.creator     = 'Thomas Hauchecorne'
	lp_ext.version     = @version
	lp_ext.description = 'Replaces Sketchup\'s layers window, with nesting/sorting/grouping/locking features.'

	Sketchup.register_extension lp_ext, true


	path = File.dirname( __FILE__ ) + "/layers_panel.rb"
	if File.exists?(path)
		File.delete(path)
	end#if

	path = File.dirname( __FILE__ ) + "/Layers Panel.rb"
	if File.exists?(path)
		File.delete(path)
	end#if

end#module