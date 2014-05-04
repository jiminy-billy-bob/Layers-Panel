
	
	
/////////////// BASE FUNCTIONS /////////////

	var WIN=false;
	var MAC=false;
	if (navigator.appVersion.indexOf("Win")!=-1) WIN=true;
	else if (navigator.appVersion.indexOf("Mac")!=-1) MAC=true;

	function reloadDialog() {
		location.reload();
	}

	function emptyOl() {
		$('#olsortable').empty();
	}

	function getDialogSize() {
		var size = { "height":$(window).height(), "width":$(window).width() }; //Json
		var jsonSize = $.toJSON( size );
		$('#dialogSize').val(jsonSize);
	}
	
//-------------

	var allowSerialize = true;

	function makeUnselectable(node) {
		if (node.nodeType == 1) {
			node.setAttribute("unselectable", "on");
		}
		var child = node.firstChild;
		while (child) {
			makeUnselectable(child);
			child = child.nextSibling;
		}
		
		$('.inputNameInput').removeAttr('unselectable');
		$('body').removeAttr('unselectable');
		$('html').removeAttr('unselectable');
		$('ol').removeAttr('unselectable');
		$('input').removeAttr('unselectable');
		$('button').removeAttr('unselectable');
		$('label').removeAttr('unselectable');
		$('#confirmDelete').removeAttr('unselectable');
		$('#wrapper').removeAttr('unselectable');
	}


//-------------


	function getModelStates(serialize) {
		allowSerialize = false;
		query = 'skp:getModelStates@' + serialize;
		skpCallback(query);
		allowSerialize = true;
	}
	
//-------------


	function getActiveState() {
		skpCallback('skp:getActiveState@');
	}
	
//-------------


	function getCollapsedGroups() {
		allowSerialize = false;
		skpCallback('skp:getCollapsedGroups@');
		allowSerialize = true;
	}
	
//-------------


	function setActiveStateFromJS(stateID) {
		stateID = stateID.replace('state_', '')
		skpCallback('skp:setActiveStateFromJS@' + stateID);
	}
	
	
//-------------
	
	
	function addState(stateName, stateID, parentID, appendToSelected) {
	
		allowSerialize = false;
		var newState = false;
		if (!stateID) { // stateID not set, new state created from js, else created from ruby
			newState = true;
		}
		
		if (newState) { 
			//Check if State nb exists
			var stateNb = 1;
			while (true) {
				var stateName = 'State ' + stateNb;
				if ($("span").filter(function() { return ($(this).text() === stateName) }).length) {
					stateNb++;
				} 
				else {
					break;
				}
			}
	
			skpCallback('skp:addStateStart@' + stateName);
		
			getStateDictID();
			stateID = stateDictID;
			
			allowSerialize = true;
		}
		
		var stateStr = '<li id="state_' + stateID + '" class="state mjs-nestedSortable-no-nesting mjs-nestedSortable-leaf" unselectable="on"><div class="lidiv" unselectable="on"><div class="handle" unselectable="on"></div><div class="active disabled" unselectable="on"></div><span class="inputName" ><input class="inputNameInput" type="text" value="' + stateName + '" /></span><span class="stateName"><span class="stateNameText" unselectable="on">' + stateName + '</span></span></div></li>'
		
		if (parentID && parentID != "null"){ //ID parentID is set, find it and append to it
			parentID = '#group_' + parentID;
			$(parentID).children("ol").append(stateStr);
		}
		else { //else, append normally
			if($('.ui-selected').length > 0 && appendToSelected != false) { //if something selected
				if($('.ui-selected').last().parent().hasClass('group')){ //if append to group
					$('.ui-selected').last().parent().children('ol').append(stateStr);
				}
				else { $('.ui-selected').last().parent().after(stateStr); }
			}
			else {
				$('.sortable').append(stateStr);
			}
		}
		
		if (newState) { 
			$(".active").removeClass("enabled").addClass("disabled");
			$("#state_" + stateID).children("div").children(".active").removeClass("disabled").addClass("enabled");
			skpCallback('skp:addStateEnd@' + allowSerialize);
		}
		allowSerialize = true;
		return stateID;
	}
	
	
//-------------
	
	
	function addGroup(groupName, groupID, parentID, appendToSelected) {
	
		allowSerialize = false;
		var newGroup = false;
		if (!groupID) { // stateID not set, new state created from js, else created from ruby
			newGroup = true;
		}
	
		if (newGroup) {
			//Check if Group nb exists
			var groupNb = 1;
			while (true) {
				var groupName = 'Group ' + groupNb;
				if ($("span").filter(function() { return ($(this).text() === groupName) }).length) {
					groupNb++;
				} 
				else {
					break;
				}
			}
	
			skpCallback('skp:addGroupStart@' + groupName);
		
			getStateDictID();
			groupID = stateDictID;
			
			allowSerialize = true;
		}
		
		var groupStr = '<li id="group_' + groupID + '" class="group mjs-nestedSortable-branch mjs-nestedSortable-expanded"><div class="lidiv"><div class="handle"></div><span class="disclose"></span><span class="inputName" ><input class="inputNameInput" type="text" /></span><span class="stateName"><span class="stateNameText">' + groupName + '</span></span></div><ol></ol></li>';
		
		if (parentID && parentID != "null"){ //ID parentID is set, find it and append to it
			parentID = '#group_' + parentID;
			$(parentID).children("ol").append(groupStr);
		}
		else { //else, append normally
			if($('.ui-selected').length > 0 && appendToSelected != false) { //if something selected
				if($('.ui-selected').last().parent().hasClass('group')){ //if append to group
					$('.ui-selected').last().parent().children('ol').append(groupStr);
				}
				else { $('.ui-selected').last().parent().after(groupStr); }
			}
			else {
				$('.sortable').append(groupStr);
			}
		}
		
		if (newGroup) {
			skpCallback('skp:addGroupEnd@' + allowSerialize);
		}
		allowSerialize = true;
		return groupID;
	}
	
	function groupStates() { // Group selected states
		if($(".ui-selected").length){
			groupID = addGroup(undefined, undefined, undefined, false);
			groupID = "#group_" + groupID;
			groupOl = $(groupID).children("ol");
			
			firstSelected = $(".ui-selected:first").parent();
			
			$(groupID).insertAfter(firstSelected);
			
			$('.ui-selected').each(function() {
				var item = $(this).parent();
				if (!item.parent().parent().children(".lidiv").is(".ui-selected") && !item.is("#state_0")) { // If not nested in selected
					item.appendTo(groupOl);
				}
			});
			$('.ui-selected').each(function() {
				$(this).removeClass("ui-selected"); // Deselect all
			});
			$(groupID).children(".lidiv").addClass("ui-selected"); // Select new group
			
			skpCallback('skp:groupStates@');
		}
	}
	
	function unGroupStates() { // Ungroup selected group
		if($(".ui-selected").length){
			$(".ui-selected").each(function() {
				var item = $(this).parent();
				if (isGroup(item) && !item.parent().parent().children(".lidiv").is(".ui-selected")) { // If group && not nested in selected
					item.addClass("delete");
				}
			});
			$(".ui-selected").each(function() {
				var item = $(this).parent();
				if(isGroup(item)){
					if (item.hasClass("delete")) {
						item.children("ol").children("li").insertBefore(item);
						item.empty().remove();
					}
					skpCallback('skp:unGroupStates@');
				}
			});
		}
	}
	
//-------------
	
	function renameState(stateID, newStateName) {
		var renameState = { "stateID":stateID, "newStateName":newStateName }; //Json
		renameState = $.toJSON( renameState );
		skpCallback('skp:renameState@' + renameState);
	}
	
	function renameGroup(groupID, newGroupName) {
		var renameGroup = { "groupID":groupID, "newGroupName":newGroupName }; //Json
		renameGroup = $.toJSON( renameGroup );
		skpCallback('skp:renameGroup@' + renameGroup);
	}
	
	function collapseFromRuby(groupID) {
		$("#group_" + groupID).removeClass('mjs-nestedSortable-expanded').addClass('mjs-nestedSortable-collapsed');
	}
	
	
//-------------
	
	
	function trash() {
		$('.ui-selected').each(function() {
			if ($(this).parent().hasClass("group")) { // If Group
				$(this).parent().find('.lidiv').addClass('ui-selected'); // Select all nested states and groups
			}
		});
		
		var deleted = false;
		var isActive = false;
		$('.ui-selected').each(function() { // Then, delete groups
			deleted = true;
			$(this).parent().empty().remove();
			if($(this).find('.active').hasClass('enabled')){ isActive = true; }
		});
		
		if(deleted){ skpCallback('skp:delete@'); }
		if(isActive){ $("#state_0").find(".active").removeClass("disabled").addClass("enabled"); }
	}

	
//-------------
	
	
	function getStateDictID() {
		skpCallback('skp:getStateDictID');
	}
	
	
	function receiveStateDictID(receivedStateDictID) {
		stateDictID = receivedStateDictID;
	}
	
	
//-------------
	
	
	function storeSerialize() {
		if (allowSerialize == true) {
			serialized = $('ol.sortable').nestedSortable('serialize');
			$('#serialize').val(serialized);
		}
	}
	
	
//-------------
	
	
	function visibilityChanged(stateID) {
		$(".active").removeClass("enabled").addClass("disabled");
		$("#state_0").find(".active").removeClass("disabled").addClass("enabled");
	}
	
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	
	


$(document).ready(function(){


	makeUnselectable(document);
	
	skpCallback('skp:startup@');
	
	var selectedItems = [];
	$('#states').selectable({
		cancel: ".active, .handle, .disclose, .inputName, .stateNameText", 
		filter: ".lidiv",
		selecting: function(e, ui) { // Enable shift-click selection
			var curr = $(ui.selecting.tagName, e.target).index(ui.selecting); // get selecting item index
			if(e.shiftKey && prev > -1) { // if shift key was pressed and there is previous - select them all
				$(ui.selecting.tagName, e.target).slice(Math.min(prev, curr), 1 + Math.max(prev, curr)).filter(".lidiv").addClass('ui-selected');
				prev = -1; // and reset prev
			} else {
				prev = curr; // othervise just save prev
			}
		},
		stop: function(event, ui) {
		}
	});

	$(document).bind("contextmenu", function(e) { // Disable right-click
		return false;
	});
	
	
	$(document).click(function (e) {
		if(allowDeselect && !$(e.target).is('.disclose, .handle, .active, .inputName, .inputNameInput, .stateName, .stateNameText')) {
			if(!$(e.target).parent().is('.footerElement, .headerElement, .headerElement2, #renderListButton')) {
				if(!$(e.target).parents(".menu").length) {
					$('.ui-selected').removeClass('ui-selected');
				}
			}
		}
	});
	
	$(document).on('click', '.disclose', function (e) {
		var groupID = $(this).parent().parent().attr('id').replace('group_', '');
		if ($(this).closest('li').hasClass('mjs-nestedSortable-collapsed')) {
			$(this).closest('li').removeClass('mjs-nestedSortable-collapsed').addClass('mjs-nestedSortable-expanded');
			skpCallback('skp:expandGroup@' + groupID);
		}
		else if ($(this).closest('li').hasClass('mjs-nestedSortable-expanded')) {
			$(this).closest('li').removeClass('mjs-nestedSortable-expanded').addClass('mjs-nestedSortable-collapsed');
			skpCallback('skp:collapseGroup@' + groupID);
		}
		else {
			$(this).closest('li').addClass('mjs-nestedSortable-collapsed');
			skpCallback('skp:collapseGroup@' + groupID);
		}
	});
	
	$(document).on('click', '.active', function (e) {
		activeStateID = $(this).parent().parent().attr('id');
		activeStateID = activeStateID.replace('state_', '');
		
		if ($(this).parent().children(".visibility").hasClass("hidden")) { // State hidden
			showStateFromJS(activeStateID);
		}
		
		$(".active").removeClass("enabled").addClass("disabled");
		$(this).toggleClass("enabled").toggleClass("disabled");
		setActiveStateFromJS(activeStateID);
	});
	
	

	
	////////////// SORTING /////////////////
	allowDeselect = true;
	
	$('ol.sortable')
		.nestedSortable({
			delay: 100,
			forcePlaceholderSize: true,
			handle: '.handle',
			helper:	'clone',
			items: 'li',
			opacity: .6,
			placeholder: 'placeholder',
			revert: 0,
			tabSize: 18,
			tolerance: 'pointer',
			toleranceElement: '> div',
			
			containment: $('#statesContainer'),

			isTree: true,
			expandOnHover: 500
		});
		
	var selected;
	$(document).on('mousedown', '.handle', function (e) {
		selected = false;
		if($(this).parent().hasClass("ui-selected")){
			selected = true;
		}
		
		if(selected == true && e.which == 1){ //e.which == 1 is left-click only
			$('body').append('<div id="helpers"></div>'); // Create helpers container
			$('#helpers').css({
				position: "absolute",
				left:  e.pageX-10,
				top:   e.pageY-10
			});
			$(".ui-selected").each(function(e){
				if (!$(this).parent().hasClass("sorted")){ // If not already in #helpers (Usefull when mouseup outside dialog)
					if ($(this).parents("ol").parents().children(".ui-selected").length > 0){ // If nested in selected group, do nothing
					} else { // Else, put it in the helpers container
						$(this).parent().clone().addClass("sorted").css({
							width: $(this).parent().width(),
							opacity: 0.6
						}).appendTo("#helpers"); // Put them in helpers container
					}
				}
			});
		}
	});
	
	$( "ol.sortable" ).on( "sortstart", function( event, ui ) { // When an item is sorted
		allowDeselect = false;
		
		if(selected == true){
			ui.helper.remove();
			ui.item.remove();
			$(".ui-selected").parent().not(".sorted").each(function(){
				if ($(this).parents(".sorted").length > 0){
				} else { $(this).remove(); }
			});
		}
	});
	
	$( "ol.sortable" ).on( "sort", function( e, ui ) { // When an item is sorted
		if(selected == true){
			$('#helpers').css({
				position: "absolute",
				left:  e.pageX-10,
				top:   e.pageY-10
			});
		}
	});
	
	$( "ol.sortable" ).on( "sortbeforestop", function( e, ui ) {
		if(selected == true){
			lastSorted = ui.placeholder;
			$("#helpers").children().each(function(e){
				$(this).removeAttr('style').insertAfter(lastSorted);
				lastSorted = $(this);
			});
			$('#helpers').remove(); // Destroy the helpers container
		}
	});
	
	$( "ol.sortable" ).on( "sortstop", function( event, ui ) { // When an item is sorted
		allowDeselect = true;
		
		if(selected == false){
			ui.item.addClass("sorted");
		}
		
		$(".sorted").each(function(e){
			if ($(this).parents('.hiddenGroup').length > 0) { // If nested in hiddenGroup
				if ($(this).children(".lidiv").children(".visibility").hasClass("visible")) { //if item visible
					hide($(this), true);
				}
			}
			else { //sorted outside group
				if ($(this).children(".lidiv").children(".visibility").hasClass("hiddenByGroup")) { //if item hiddenByGroup
					unHide($(this));
				}
			}
			
			if ($(this).parents('.noRenderGroup').length > 0) { // If nested in noRenderGroup
				if ($(this).children(".lidiv").children(".rendering").hasClass("render")) { //if item render
					noRender($(this), true);
				}
			}
			else { //sorted outside group
				if ($(this).children(".lidiv").children(".rendering").hasClass("noRenderByGroup")) { //if item noRenderByGroup
					render($(this));
				}
			}
			
			if($(this).hasClass("group")){
				$(this).removeClass("mjs-nestedSortable-leaf");
				$(this).addClass("mjs-nestedSortable-branch");
				$(this).addClass("mjs-nestedSortable-expanded");
			}
			
			$(this).removeClass("sorted");
		});
		
		skpCallback('skp:sortItem@');
	});
	
	
	
	
	////////////// RENAME /////////////////
	
	//Detect double click, hide name, show input
	$(document).on('dblclick', '.stateNameText', function (e) {
		if ($(this).closest('div').parent().is('#state_0')) {} //Can't rename State0
		else {
			var name = $(this).text();
			$(this).closest('div').children(".stateName").hide();
			$(this).closest('div').children(".inputName").css('display', 'block').children(".inputNameInput").val(name).focus().select();
		}
	});
	//Select state when clicking (.selectable() messes with dblclick)
	$(document).on('click', '.stateNameText', function (e) {
		$(".ui-selected").each(function(e){
			$(this).removeClass("ui-selected");
		});
		$(this).closest('div').addClass("ui-selected");
	});
	
	//Detect enter key, trigger blur
	$(document).on('keyup', '.inputNameInput', function (e) {
		if ( e.keyCode === 13 ) { // 13 is enter key
			$(this).blur();
		}
	});
	
	//Detect esc key, fetch back the old name, trigger blur
	$(document).on('keyup', '.inputNameInput', function (e) {
		if ( e.keyCode === 27 ) { // 27 is esc key
			var name = $(this).closest('div').children(".stateName").children(".stateNameText").text();
			$(this).val(name);
			$(this).blur();
		}
	});
	
	//Detect blur, hide input and transfer name
	$(document).on('blur', '.inputNameInput', function (e) {
	
		var group = false;
		if ($(this).closest('div').parent().hasClass("group")) { //If group
			var group = true;
		}
		
		var oldname = $(this).closest('div').children(".stateName").children(".stateNameText").text();
		var stateName = $(this).val();
		if (group == false) { // If state
			stateID = $(this).closest('div').parent().attr('id');
			stateID = stateID.replace('state_', '');
		} else { // If group
			groupID = $(this).closest('div').parent().attr('id');
			groupID = groupID.replace('group_', '');
		}
		
		if(stateName.length == 0 ) { // Check if state name is empty
			alert('Invalid State Name.\n\nState name must have at least one character.');
			$(this).focus();
		}
		
		else if ( oldname == stateName ) { // Name doesn't change
			$(this).closest('span').hide();
			$(this).closest('div').children(".stateName").show();
		}
		
		else { // Name changes
			var stateName = $(this).val();
			$(this).closest('span').hide();
			$(this).closest('div').children(".stateName").show();
			$(this).closest('div').children(".stateName").children(".stateNameText").text(stateName);
			if (group == false) { // If state
				renameState(stateID, stateName); // Send rename to ruby
			} else { // If group
				renameGroup(groupID, stateName); // Send rename to ruby
			}
		}
	});
	
	
	
	////////////// HEADER ////////////////
	
	$('#minimize').click(function () {
		var size = { "height":$(window).height(), "width":$(window).width() }; //Json
		var jsonSize = $.toJSON( size );
		
		if($(window).height() > 10){
			skpCallback('skp:minimizeDialog@' + jsonSize);
		}
		else {
			skpCallback('skp:maximizeDialog@' + $(window).width());
		}
	});
	$(window).resize(function(){
		if($(window).height() > 10){
			$('#minimize').css({height: '3px'});
		}
		else {
			$('#minimize').css({height: '10px'});
		}
	});
	

	////////////// FOOTER ////////////////
	
	$('.footerElement').hover(function () {
		$(this).toggleClass('footerHover');
	}).mouseup(function(){
		$(this).removeClass('footerClick');
    }).mousedown(function(){
		$(this).addClass('footerClick');
    }).mouseleave(function(){
		$(this).removeClass('footerClick');
    });
	
	
	// Add a new State
	$('#newState').click(addState);
	
	// Add a new group
	$('#newGroup').click(addGroup);
	
	// Delete group or state
	$('#trash').click(trash);
	
	$('#update').click(function() {
		$(".ui-selected").each(function(e){
			stateID = $(this).parent().attr('id');
			stateID = stateID.replace('state_', '');
			skpCallback('skp:updateState@' + stateID);
		});
	});
	
	
	$('#print').click(function() {
		window.prompt("Copy to clipboard: Ctrl+C, Enter", $("#olsortable").html());
	});
	
	
	////////////// UNDO REDO ////////////////
	
	$(document).keydown(function(e){
		if( e.which === 90 && (e.ctrlKey||e.metaKey) ){
			skpCallback('skp:undo');
		}          
	}); 
	
	$(document).keydown(function(e){
		if( e.which === 89 && (e.ctrlKey||e.metaKey) ){
			skpCallback('skp:redo');
		}          
	}); 
	
	////////////// SHORTCUTS ////////////////
	
	$(document).keydown(function(e){ // CTRL A
		if( e.which === 65 && (e.ctrlKey||e.metaKey)){
			$(".lidiv").addClass("ui-selected");
		}          
	}); 
	
	$(document).keydown(function(e){ // CTRL G
		if( e.which === 71 && (e.ctrlKey||e.metaKey) && !e.shiftKey ){
			groupStates();
		}          
	}); 
	
	$(document).keydown(function(e){ // CTRL SHIFT G
		if( e.which === 71 && (e.ctrlKey||e.metaKey) && e.shiftKey ){
			unGroupStates();
		}          
	});
	
	//////////////
	
	getCollapsedGroups();
	
	//////////////
	
	$(window).resize(function(){
		$('#statesContainer').css({
			height: $(window).height() - 55
		});
	});
	$(window).resize();
});