# encoding UTF-8
#
#  !_fix_ruby_startup2-1.rb
#
#  ver :  2.0.0 by Dan Rathbun
#  ver :  2.1.0 by TIG: It now changes the two Ruby-Lib paths' drive to match 
#  the Tools-path's drive: thus allowing for SketchUp.exe installation that's 
#  NOT on system drive to be fixed, when initial opened SKP is not on the same 
#  drive as Sketchup.exe. 
#  It also allows for several custom-plugins folders preceeding Ruby-Libs.
#  ver :  2.1.1 by TIG: v14 specific trap added.

#
#  Drop in "Tools" folder - for v2014 MR0 use only...
#

if RUBY_PLATFORM !~ /darwin/i && Sketchup.version == "14.0.4900"

  fix = false

  tdrve = $:.grep(/\/Tools$/)[0][0,2]    # the Tools path
  rlibs = $:.grep(/\/Tools\/RubyStdLib/) # the 2 Ruby-Lib paths
  
  rlibs.each{|rlib|
  
    i = $:.index(rlib)
	
	if $:[i][0,2] != tdrve # wrong drive letter !
	
	  fix = true
	  $:[i] = tdrve + $:[i][2..-1] # replaces Ruby-Lib drive with Tool's drive
	  
	end
	
  }
  
  if fix
  
    $".unshift('enumerator.so') unless $".include?('enumerator.so')

    scripts = [
      'enc/encdb.so',
      'enc/iso_8859_1.so',
      'enc/trans/transdb.so',
      'rubygems.rb' # --> 'rbconfig.rb' & all rubygems files
    ]

    for script in scripts do
      require(script)
    end
  
  end # fix
  
end # if not running on Mac OR v2014
