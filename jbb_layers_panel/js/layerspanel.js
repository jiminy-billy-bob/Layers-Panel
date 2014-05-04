
	
	
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
		addLayerFromRuby("Layer0", "0", undefined, false)
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


	function getModelLayers(serialize) {
		allowSerialize = false;
		query = 'skp:getModelLayers@' + serialize;
		skpCallback(query);
		allowSerialize = true;
	}
	
//-------------


	function getActiveLayer() {
		skpCallback('skp:getActiveLayer@');
	}
	
//-------------


	function getCollapsedGroups() {
		allowSerialize = false;
		skpCallback('skp:getCollapsedGroups@');
		allowSerialize = true;
	}
	
//-------------


	function setActiveLayerFromRuby(layerID) {
		$(".enabled").removeClass("enabled").addClass("disabled");
		$("#layer_" + layerID).children("div").children(".active").removeClass("disabled").addClass("enabled");
	}
	
//-------------


	function setActiveLayerFromJS(layerID) {
		layerID = layerID.replace('layer_', '')
		skpCallback('skp:setActiveLayerFromJS@' + layerID);
	}
	
//-------------
	
	
	function addLayerFromRuby(layerName, layerID, parentID, serialize, lock) {
	
		if ($("#layer_" + layerID).length == 0) { // layer doesn't exists yet in the DOM
		
			var locked = '';
			if (lock == "true"){
				locked = ' locked';
			}
			
			var layerStr = '<li id="layer_' + layerID + '" class="layer mjs-nestedSortable-no-nesting mjs-nestedSortable-leaf" unselectable="on"><div class="lidiv" unselectable="on"><div class="handle" unselectable="on"></div><div class="rendering render" unselectable="on"></div><div class="visibility visible" unselectable="on"></div><div class="active disabled" unselectable="on"></div><div class="lock2' + locked + '" unselectable="on"></div><span class="inputName" ><input class="inputNameInput" type="text" value="' + layerName + '" /></span><span class="layerName"><span class="layerNameText" unselectable="on">' + layerName + '</span></span></div></li>'
			
			if (parentID && parentID != "null"){ //ID parentID is set, find it and append to it
				parentID = '#group_' + parentID;
				$(parentID).children("ol").append(layerStr);
			}
			else { //else, append normally
				if($('.ui-selected').length > 0) { //if something selected
					selectedItem = $('.ui-selected').last().parent()
					if(selectedItem.hasClass('group')){ //if append to group
						selectedItem.children('ol').append(layerStr);
					}
					else { selectedItem.after(layerStr); }
				}
				else {
					$('.sortable').append(layerStr);
				}
			}
		}
		
		allowSerialize = true;
	}
	
	
//-------------
	
	function addLayerFromJS() {
		skpCallback('skp:addLayerFromJS');
	}
	
	function getUniqueName(unique_name) {
		$("#newLayerName").val(unique_name);
	}
	
//-------------
	
	
	function addGroup(groupName, groupID, parentID, appendToSelected) {
	
		allowSerialize = false;
		var newGroup = false;
		if (!groupID) { // groupID not set, new group created from js, else created from ruby
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
		
			getLayerDictID();
			groupID = layerDictID;
			
			allowSerialize = true;
		}
		
		var groupStr = '<li id="group_' + groupID + '" class="group mjs-nestedSortable-branch mjs-nestedSortable-expanded"><div class="lidiv"><div class="handle"></div><div class="rendering render" unselectable="on"></div><div class="visibility visible"></div><span class="disclose"></span><span class="inputName" ><input class="inputNameInput" type="text" /></span><span class="layerName"><span class="layerNameText">' + groupName + '</span></span></div><ol></ol></li>';
		
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
	
	function groupLayers() { // Group selected layers
		if($(".ui-selected").length){
			groupID = addGroup(undefined, undefined, undefined, false);
			groupID = "#group_" + groupID;
			groupOl = $(groupID).children("ol");
			
			firstSelected = $(".ui-selected:first").parent();
			
			$(groupID).insertAfter(firstSelected);
			
			$('.ui-selected').each(function() {
				var item = $(this).parent();
				if (!item.parent().parent().children(".lidiv").is(".ui-selected") && !item.is("#layer_0")) { // If not nested in selected
					item.appendTo(groupOl);
				}
			});
			$('.ui-selected').each(function() {
				$(this).removeClass("ui-selected"); // Deselect all
			});
			$(groupID).children(".lidiv").addClass("ui-selected"); // Select new group
			
			skpCallback('skp:groupLayers@');
		}
	}
	
	function unGroupLayers() { // Ungroup selected group
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
					skpCallback('skp:unGroupLayers@');
				}
			});
		}
	}
	
//-------------
	
	
	function renameLayerFromJS(layerID, newLayerName) {
	
		var layerNameS = { "layerID":layerID, "newLayerName":newLayerName }; //Json
		var JsonLayerNameS = $.toJSON( layerNameS );
		skpCallback('skp:renameLayerFromJS@' + JsonLayerNameS);
		
	}
	
	function renameLayerFromRuby(layerID, layerName) {
		$("#layer_" + layerID).children("div").children(".layerName").children(".layerNameText").text(layerName);
	}
	
	function renameGroup(groupID, newGroupName) {
	
		groupID = groupID.replace('group_', '')
		var renameGroup = { "groupID":groupID, "newGroupName":newGroupName }; //Json
		var renameGroup2 = $.toJSON( renameGroup );
		skpCallback('skp:renameGroup@' + renameGroup2);
		
	}
	
	function collapseFromRuby(groupID) {
		$("#group_" + groupID).removeClass('mjs-nestedSortable-expanded').addClass('mjs-nestedSortable-collapsed');
		
	}
	
	
//-------------
	
	
	function setColorFromRuby(layerID, color) {
		$("#layer_" + layerID).find(".handle, .handle0").css( "background-color", color );
	}
	
	function toogleColorsButton(check){
		if(check == true){
			$("#colors").parent().addClass('footerElementChecked');
		} else {
			$("#colors").parent().removeClass('footerElementChecked');
		}
	}
	
	
//-------------
	
	
	function lock() {
		var unlocked = false;
		$('.ui-selected').each(function() { // Check if at least one layer is unlocked
			if ($(this).parent().hasClass("layer")) { // If layer
				if(!$(this).parent().find('.lock2').hasClass('locked')){
					unlocked = true;
					return false;
				}
			}
		});
		$('.ui-selected').each(function() { // Lock or unlock layers
			if ($(this).parent().hasClass("layer")) { // If layer
				layerID = $(this).closest('div').parent().attr('id');
				layerID = layerID.replace('layer_', '');
				if(unlocked == false){
					$(this).parent().find('.lock2').removeClass('locked');
					skpCallback('skp:unlockFromJS@' + layerID);
				}
				else{
					$(this).parent().find('.lock2').addClass('locked');
					skpCallback('skp:lockFromJS@' + layerID);
				}
			}
		});
		unlocked = false;
	}
	
	
//-------------
	
	
	function trash(deleteGeom, currentLayer) {
	
		var layer0 = false;
		$('.ui-selected').each(function() {
			if($(this).parent().is("#layer_0")){
				layer0 = true;
			}
		});
		if(layer0){
			alert("You can't delete layer0");
			return;
		}
		
		var locked = false;
		$('.ui-selected').each(function() { // Check if at least one layer is locked
			if($(this).parent().find('.lock2').hasClass('locked')){
				locked = true;
				return false;
			}
		});
		
		if(locked == false){
		
			$('#id0').children('.lidiv').removeClass('ui-selected'); // Prevent Layer0 delete
			
			layerContent = false; //Reset
			
			$('.ui-selected').each(function() {
				if ($(this).parent().hasClass("group")) { // If Group
					$(this).parent().find('.lidiv').addClass('ui-selected'); // Select all nested layers and groups
				}
			});
			
			if(deleteGeom == true){
				if(confirm("Are you sure you want to delete this layer(s) and all of its content ?")){
					trash2(true);
				}
			}
			else if(currentLayer == true){
				trash2(false, true);
			}
			else{
				trash2(false);
			}
		}
		else {
			alert("You can't delete locked layers.");
		}
	}

	function trash2(deleteGeom, currentLayer) {
		$('.ui-selected').each(function() { // First, deal with layers
			if ($(this).parent().hasClass("layer")) { // If layer
				layerID = $(this).parent().attr('id');
				layerID = layerID.replace('layer_', '')
				deleteLayerFromJS(layerID, deleteGeom, currentLayer); 
			}
		});
		
		$('.ui-selected').each(function() { // Then, delete groups
			if ($(this).parent().hasClass("group")) { // If group
				$(this).parent().empty().remove();
			}
			skpCallback('skp:storeSerialize@');
		});
	}
	
	
//-------------

	
	var layerContent = false
	function checkLayerForContent(layerID, layerHasContent) {
		if (layerHasContent == "true") { 
			layerContent = true;
		}
	}
	
	
//-------------
	
	
	function deleteLayerFromJS(layerID, deleteGeom, currentLayer) {
		if(deleteGeom == true) {
			 skpCallback('skp:deleteLayer&GeomFromJS@' + layerID);
		}
		else if(currentLayer == true) {
			skpCallback('skp:deleteLayerToCurrentFromJS@' + layerID);
		}
		else {
			skpCallback('skp:deleteLayerFromJS@' + layerID);
		}
	}
	
	function deleteLayerFromRuby(layerID) {
		$("#layer_" + layerID).empty().remove();
	}
	
	function mergeLayers() {
		$('.ui-selected').each(function() { // Select all nested layers and groups
			var item = $(this).parent();
			if (isGroup(item)) {
				item.find('.lidiv').addClass('ui-selected'); 
			}
		});
		var layerIDs = '';
		var i = 1;
		$('.ui-selected').each(function() { // Create a string with all the ID of the layers being merged
			var item = $(this).parent();
			if (i == 1 && isGroup(item)) {
				layerIDs += item.children(".lidiv").children(".layerName").children(".layerNameText").text();
				layerIDs += ','
			}
			else if (!isGroup(item)) {
				layerIDs += item.attr('id').replace('layer_', '');
				layerIDs += ','
			}
			i++;
		});
		$('.ui-selected').each(function() { // Remove all groups
			var item = $(this).parent();
			if (isGroup(item)) {
				item.empty().remove();
			}
		});
		skpCallback('skp:mergeLayers@' + layerIDs);
	}
	
	
//-------------
	
	
	function showLayerFromJS(layerID) {
		skpCallback('skp:showLayerFromJS@' + layerID);
	}
	
	
	function hideLayerFromJS(layerID, grouped) {
		skpCallback('skp:hideLayerFromJS@' + layerID);
	}
	
	
	function showLayerFromRuby(layerID) {
		unHide($("#layer_" + layerID), undefined, true);
		$("#layer_" + layerID).children("div").children(".visibility").removeClass("hidden").addClass("visible");
	}
	
	
	function hideLayerFromRuby(layerID) {
		hide($("#layer_" + layerID), undefined, true);
		$("#layer_" + layerID).children("div").children(".visibility").removeClass("visible").addClass("hidden");
	}
	
	
	function hideByGroupFromRuby(layerID) {
		$("#layer_" + layerID).children("div").children(".visibility").removeClass("visible").removeClass("hidden").addClass("hiddenByGroup");
	}
	
	
	function hideGroupFromRuby(groupID, byGroup) {
		if (!byGroup) {
			$("#group_" + groupID).addClass("hiddenGroup").children("div").children(".visibility").removeClass("visible").addClass("hidden");
		}
		else {
			$("#group_" + groupID).addClass("hiddenGroup").children("div").children(".visibility").removeClass("visible").addClass("hiddenByGroup");
		}
	}
	
	
	function purgeGroups() {
		$(".group").each(function(){
			if($(this).find(".layer").length == 0){
				$(this).remove();
			}
		});
		skpCallback('skp:purgeGroups@');
	}
	
	
//-------------
	

	function isGroup(item){
		if(item.hasClass("group")){ return true; }
		else { return false; }
	}


	function hide(item, byGroup, ruby, warning) {
	
		if(item.find(".enabled").length) { // If active layer
			if(warning != false){
				alert('You cannot hide the current layer.');
			}
		}
		
		else {
			visibility = item.children("div").children(".visibility");
			
			visibility.removeClass("visible");
			
			if (byGroup) {
				visibility.addClass("hiddenByGroup");
			}
			else {
				visibility.addClass("hidden");
			}
			
			if ( isGroup(item) ) { //is group
				var groupID = item.attr('id').replace('group_', '');
				if (!byGroup) { //mark group as hidden directly on its highest element
					item.addClass("hiddenGroup"); 
					skpCallback('skp:hideGroup@' + groupID);
				}
				else {
					skpCallback('skp:hideGroupByGroup@' + groupID);
				}
			
				item.children("ol").children(".group").each(function(i) { // Hide visible groups
					if ( $(this).children(".lidiv").children(".visibility").hasClass("visible") ) {
						hide($(this), true);
					}
				});
				item.children("ol").children(".layer").each(function(i) { // Hide visible layers
					if ( $(this).children(".lidiv").children(".visibility").hasClass("visible") ) {
						hide($(this), true);
					}
				});
			}
			else { //is layer
				if (ruby != true){
					layerID = item.attr('id').replace('layer_', '');
					hideLayerFromJS(layerID);
					if (byGroup) {
						skpCallback('skp:hideByGroup@' + layerID);
					}
				}
			}
		}
	}
	
	
	function unHide(item, clicked, ruby) {
	
		visibility = item.children("div").children(".visibility");
		
		if(clicked){ visibility.addClass("hiddenByGroup"); }
		
		if (item.parents(".hiddenGroup").length > 0) { // If nested in hidden group
			stop = false
			item.parents(".hiddenGroup").each(function() {
				if(!stop){ closestHiddenGroup = $(this); }
				stop = true
			});
			unHide(closestHiddenGroup, true);
		}
		else {
			visibility.removeClass("hiddenByGroup").removeClass("hidden").addClass("visible");
			
			if ( isGroup(item) ) { //is group
				item.removeClass("hiddenGroup");
				groupID = item.attr('id').replace('group_', '');
				skpCallback('skp:unHideGroup@' + groupID);
			
				item.children("ol").children(".group").each(function(i) { // unHide hiddenByGroup groups
					if ( $(this).children(".lidiv").children(".visibility").hasClass("hiddenByGroup") ) {
						unHide($(this), true);
					}
				});
				item.children("ol").children(".layer").each(function(i) { // unHide hiddenByGroup layers
					if ( $(this).children(".lidiv").children(".visibility").hasClass("hiddenByGroup") ) {
						unHide($(this), true);
					}
				});
			}
			else { //is layer
				if (ruby != true){
					layerID = item.attr('id').replace('layer_', '');
					showLayerFromJS(layerID);
				}
			}
		}
	}
	
//-------------

	
	function noRenderFromRuby(itemID, byGroup) {
		if($("#group_" + itemID).length == 0){
			var item = $("#layer_" + itemID);
		}
		else {
			var item = $("#group_" + itemID);
			item.addClass("noRenderGroup")
		}
		
		if (!byGroup) {
			item.children("div").children(".rendering").removeClass("render").addClass("noRender");
		}
		else {
			item.children("div").children(".rendering").removeClass("render").addClass("noRenderByGroup");
		}
	}

	function noRender(item, byGroup, ruby) {
	
		rendering = item.children("div").children(".rendering");
		
		rendering.removeClass("render");
		
		if (byGroup) {
			rendering.addClass("noRenderByGroup");
		}
		else {
			rendering.addClass("noRender");
		}
		
		if ( isGroup(item) ) { //is group
			var groupID = item.attr('id').replace('group_', '');
			if (!byGroup) { //mark group as noRender directly on its highest element
				item.addClass("noRenderGroup"); 
				skpCallback('skp:noRender@' + groupID);
			}
			else {
				skpCallback('skp:noRenderByGroup@' + groupID);
			}
		
			item.children("ol").children(".group").each(function(i) { // noRender render groups
				if ( $(this).children(".lidiv").children(".rendering").hasClass("render") ) {
					noRender($(this), true);
				}
			});
			item.children("ol").children(".layer").each(function(i) { // noRender render layers
				if ( $(this).children(".lidiv").children(".rendering").hasClass("render") ) {
					noRender($(this), true);
				}
			});
		}
		else { //is layer
			if (ruby != true){
				layerID = item.attr('id').replace('layer_', '');
				if (byGroup) {
					skpCallback('skp:noRenderByGroup@' + layerID);
				}
				else {
					skpCallback('skp:noRender@' + layerID);
				}
			}
		}
		
	}
	
	
	function render(item, clicked, ruby) {
	
		rendering = item.children("div").children(".rendering");
		
		if(clicked){ rendering.addClass("noRenderByGroup"); }
		
		if (item.parents(".noRenderGroup").length > 0) { // If nested in noRender group
			stop = false
			item.parents(".noRenderGroup").each(function() {
				if(!stop){ closestNoRenderGroup = $(this); }
				stop = true
			});
			render(closestNoRenderGroup, true);
		}
		else {
			rendering.removeClass("noRenderByGroup").removeClass("noRender").addClass("render");
			
			if ( isGroup(item) ) { //is group
				item.removeClass("noRenderGroup");
				groupID = item.attr('id').replace('group_', '');
				skpCallback('skp:render@' + groupID);
			
				item.children("ol").children(".group").each(function(i) { // render noRenderByGroup groups
					if ( $(this).children(".lidiv").children(".rendering").hasClass("noRenderByGroup") ) {
						render($(this), true);
					}
				});
				item.children("ol").children(".layer").each(function(i) { // render noRenderByGroup layers
					if ( $(this).children(".lidiv").children(".rendering").hasClass("noRenderByGroup") ) {
						render($(this), true);
					}
				});
			}
			else { //is layer
				if (ruby != true){
					layerID = item.attr('id').replace('layer_', '');
					skpCallback('skp:render@' + layerID);
				}
			}
		}
	}
	
	function triggerRender(engine) {
		skpCallback('skp:triggerRender@' + engine);
		// alert('render');
	}
	
	function getRenderEngine() {
		skpCallback('skp:getRenderEngine@');
	}
	
	function useRenderEngine(engine) {
		$('#renderListButton span').text('Vray');
		$('#renderList').hide();
		$('#renderListButton').removeClass('clicked');
		$('.renderElement').hide();
		
		if(engine == "mx"){
			$('#renderListButton span').text('Maxwell');
			$('.maxwell').show();
			skpCallback('skp:useRenderEngine@mx')
		}
		else if(engine == "kt"){
			$('#renderListButton span').text('Kerkythea');
			$('.kerkythea').show();
			skpCallback('skp:useRenderEngine@kt')
		}
		else if(engine == "ks"){
			$('#renderListButton span').text('KeyShot');
			$('.keyshot').show();
			skpCallback('skp:useRenderEngine@ks')
		}
		else if(engine == "indigo"){
			$('#renderListButton span').text('Indigo');
			$('.indigo').show();
			skpCallback('skp:useRenderEngine@indigo')
		}
		else if(engine == "podium"){
			$('#renderListButton span').text('Podium');
			$('.podium').show();
			skpCallback('skp:useRenderEngine@podium')
		}
		else{ // Vray is default
			$('#renderListButton span').text('Vray');
			$('.vray').show();
			skpCallback('skp:useRenderEngine@vray')
		}
	}
	
	var headerHeight = 107;
	function noRenderToolbar() {
		headerHeight = 78;
		$('head').append('<link href="../css/norendertoolbar.css" rel="stylesheet" type="text/css">');
	}
	
//-------------
	
	
	function getLayerDictID() {
		skpCallback('skp:getLayerDictID');
	}
	
	
	function receiveLayerDictID(receivedLayerDictID) {
		layerDictID = receivedLayerDictID;
	}
	
	
//-------------
	
	
	function storeSerialize() {
		if (allowSerialize == true) {
			serialized = $('ol.sortable').nestedSortable('serialize');
			$('#serialize').val(serialized);
			// skpCallback('skp:storeSerialize2@');
		}
	}
	
	function noIEwarning() {
		$('#browser').hide();
	}
	
	
//-------------
	
	
	function hightlightLayer(layerID) {
		layerID = "#layer_" + layerID;
		$(layerID).children(".lidiv").addClass("ui-selected");
	}
	
	
	
	
	
	
	////////////////////////
	
	
	function iframeTrack(lp, su, suversion, lang, store) {
		var iframe = '<iframe id="iframe" src="http://chips-architecture.com/layers/track.php?lp=' + lp + '&su=' + su + '&su_v=' + suversion + '&lang=' + lang + '&store=' + store + '" style="display: none"></iframe>';
		$('body').append(iframe);
	}
	
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	
	


$(document).ready(function(){


	makeUnselectable(document);
	
	skpCallback('skp:startup@');
	
	var selectedItems = [];
	$('#layers').selectable({
		cancel: ".visibility, .rendering, .active, .handle, .disclose, .inputName, .layerNameText", 
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

	$(document).on('contextmenu', '.handle, .handle0', function (e) {
		if ($(this).parent().parent().hasClass("layer")){
			var layerID = $(this).parent().parent().attr('id').replace('layer_', '');
			skpCallback('skp:pickColor@' + layerID);
		}
	});
	
	
	// $(function(){
		// $.contextMenu({
			// selector: '.lidiv', 
			// callback: function(key, options) {
				// var m = "clicked: " + key;
				// window.console && console.log(m) || alert(m); 
			// },
			// items: {
				// "selectAllEntities": {
					// name: "Select all entities",
					// callback: function(key, options) {
						// alert('yop')
					// }
				// },
				// "selectAllEntitiesContext": {
					// name: "Select all entities in active context",
					// callback: function(key, options) {
						// alert('yop')
					// }
				// }
			// }
		// });
		
		// $('.context-menu-one').on('click', function(e){
			// console.log('clicked', this);
		// })
	// });
	
	
	
	
	$(document).click(function (e) {
		if(allowDeselect && !$(e.target).is('.disclose, .handle, .visibility, .rendering, .active, .inputName, .inputNameInput, .layerName, .layerNameText')) {
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
	
	$(document).on('click', '.rendering', function (e) {
		var item = $(this).parent().parent();
		
		if( $(this).hasClass("render") ){
			noRender(item);
		}
		else {
			render(item, true);
		}
	});
	
	$(document).on('click', '.visibility', function (e) {
		skpCallback('skp:startVisibilityOp@');
		var item = $(this).parent().parent();
		
		if ((e.ctrlKey||e.metaKey)) {
			unHide(item, true, undefined);
			item.parent().children("li").each(function() {
				hide($(this), undefined, undefined, false);
			});
			unHide(item, true, undefined);
		}
		else if (e.altKey) {
			item2 = item;
			while(item2.parent("ol").length){
				item2.parent("ol").children(".layer").each(function() {
					hide($(this), undefined, undefined, false);
				});
				item2.parent("ol").children(".group").each(function() {
					hide($(this));
				});
				item2 = item2.parent().parent();
			}
			unHide(item, true, undefined);
		}
		else if (e.shiftKey && $(this).parent().hasClass("ui-selected")) {
			if( $(this).hasClass("visible") ){
				$(".ui-selected").each(function() {
					hide($(this).parent());
				});
			}
			else {
				$(".ui-selected").each(function() {
					unHide($(this).parent());
				});
			}
		}
		else{
			if( $(this).hasClass("visible") ){
				hide(item);
			}
			else {
				unHide(item, true);
			}
		}
		skpCallback('skp:endVisibilityOp@');
	});
	
	$(document).on('click', '.active', function (e) {
		activeLayerID = $(this).parent().parent().attr('id');
		activeLayerID = activeLayerID.replace('layer_', '');
		
		if ($(this).parent().children(".visibility").hasClass("hidden")) { // Layer hidden
			showLayerFromJS(activeLayerID);
		}
		
		$(".active").removeClass("enabled").addClass("disabled");
		$(this).toggleClass("enabled").toggleClass("disabled");
		setActiveLayerFromJS(activeLayerID);
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
			
			containment: $('#layersContainer'),

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
			// $(".ui-selected").parent().not(".sorted").each(function(){
				// if ($(this).parents(".sorted").length > 0){
				// } else { $(this).remove(); }
			// });
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
		
		skpCallback('skp:sortItem@')
	});
	
	
	
	////////////// Layer0 /////////////////
	$('#layer_0 > .lidiv > .handle').addClass('handle0').removeClass('handle');
	
	
	
	
	////////////// RENAME /////////////////
	
	//Detect double click, hide name, show input
	$(document).on('dblclick', '.layerNameText', function (e) {
		if ($(this).closest('div').parent().is('#layer_0')) {} //Can't rename Layer0
		else {
			var name = $(this).text();
			$(this).closest('div').children(".layerName").hide();
			$(this).closest('div').children(".inputName").css('display', 'block').children(".inputNameInput").val(name).focus().select();
		}
	});
	//Select layer when clicking (.selectable() messes with dblclick)
	$(document).on('click', '.layerNameText', function (e) {
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
			var name = $(this).closest('div').children(".layerName").children(".layerNameText").text();
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
		
		var oldname = $(this).closest('div').children(".layerName").children(".layerNameText").text();
		var layerName = $(this).val();
		layerID = $(this).closest('div').parent().attr('id');
		layerID = layerID.replace('layer_', '');
		
		if( group == false && layerName.length == 0 ) { // Check if layer name is empty
			alert('Invalid Layer Name.\n\nLayer name must have at least one character.');
			$(this).focus();
		}
		
		else if ( oldname == layerName ) { // Name doesn't change
			$(this).closest('span').hide();
			$(this).closest('div').children(".layerName").show();
		}
		
		else { // Name changes
			if ( group == false && $("span").filter(function() { return ($(this).text() === layerName) }).length) { // Check if layer name already exists
				alert('Invalid Layer Name.\n\nLayer name must be unique.');
				$(this).focus();
			}
			else {
				var layerName = $(this).val();
				$(this).closest('span').hide();
				$(this).closest('div').children(".layerName").show();
				if(group == true) {
					$(this).closest('div').children(".layerName").children(".layerNameText").text(layerName);
				}
				if (group == false) { // If layer
					renameLayerFromJS(layerID, layerName); // Send rename to ruby
				}
				else { // If group
					var groupID = $(this).closest('div').parent().attr('id');
					renameGroup(groupID, layerName);
				}
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
	
	$('.headerElement').hover(function () {
		$(this).toggleClass('headerElementHover');
	}).mouseup(function(){
		$(this).removeClass('headerElementClick');
    }).mousedown(function(){
		$(this).addClass('headerElementClick');
    }).mouseleave(function(){
		$(this).removeClass('headerElementClick');
    });
	
	$('.headerElement2').hover(function () {
		$(this).toggleClass('headerElement2Hover');
	}).mouseup(function(){
		$(this).removeClass('headerElement2Click');
    }).mousedown(function(){
		$(this).addClass('headerElement2Click');
    }).mouseleave(function(){
		$(this).removeClass('headerElement2Click');
    });
	
	$('#renderListButton').click(function () {
		if($('#renderList').is(':hidden')){
			$('#renderList').show();
			$(this).addClass('clicked');
		} else {
			$('#renderList').hide();
			$(this).removeClass('clicked');
		}
	});
	$(document).mouseup(function (e){ // Hide menu on click-outside
		var container = $("#renderList");
		
		if (container.has(e.target).length === 0)
		{
			if($('#renderList').is(':visible')){
				setTimeout(function(){
					container.hide();
					$('#renderListButton').removeClass('clicked');
				},10);
			}
		}
	});
	
	$('#useVray').click(function() {
		useRenderEngine("vray");
	});
	
	$('#useMaxwell').click(function() {
		useRenderEngine("mx");
	});
	
	$('#useKT').click(function() {
		useRenderEngine("kt");
	});
	
	$('#useKS').click(function() {
		useRenderEngine("ks");
	});
	
	$('#useIndigo').click(function() {
		useRenderEngine("indigo");
	});
	
	$('#usePodium').click(function() {
		useRenderEngine("podium");
	});
	
	$('#vray').click(function() {triggerRender('vray')});
	$('#vrayrt').click(function() {triggerRender('vrayrt')});
	
	$('#mx').click(function() {triggerRender('mx')});
	$('#mxstudio').click(function() {triggerRender('mxstudio')});
	$('#mxnet').click(function() {triggerRender('mxnet')});
	$('#mxfire').click(function() {triggerRender('mxfire')});
	
	$('#kt').click(function() {triggerRender('kt')});
	
	$('#ks').click(function() {triggerRender('ks')});
	
	$('#indigo').click(function() {triggerRender('indigo')});
	
	$('#podium').click(function() {triggerRender('podium')});
	
	//------------
	
	$('#lock1').click(function() {lock()});
	
	$('#moveSel').click(function() {
		if($('.ui-selected').length == 0){
			alert("Please select a layer");
		}
		else if ($('.ui-selected').length == 1){
			if ($('.ui-selected').parent().hasClass("layer")) { // If layer
				layerID = $('.ui-selected').parent().attr('id').replace('layer_', '');
				skpCallback('skp:moveSelection@' + layerID);
			} else { alert("Please select a layer, not a group"); }
		}
		else {
			alert("Please select only ONE layer");
		}
	});
	
	$('#select').click(function() {
		if($('.ui-selected').length == 0){
			alert("Please select a layer");
		}
		else{
			$('.ui-selected').each(function(){
				layerID = $(this).parent().attr('id').replace('layer_', '');
				skpCallback('skp:selectFromLayer@' + layerID);
			});
		}
	});
	
	$('#current').click(function() {
		skpCallback('skp:getSelectionLayer');
	});
	
	$('#highlight').click(function() {
		skpCallback('skp:highlightSelectionLayer');
	});



	////////////// MENU ////////////////
	
	
	$('#menuButton').click(function () {
		if($('#menu').is(':hidden')){
			$('#menu').show();
		} else {
			$('#menu').hide();
		}
	});
	$(document).mouseup(function (e){ // Hide menu on click-outside
		var container = $("#menu");
		
		if (container.has(e.target).length === 0)
		{
			if($('#menu').is(':visible')){
				setTimeout(function(){container.hide();},10);
			}
		}
	});
	
	$('.menuElement').click(function() {
		$('#menu').hide();
	});
	
	$('#purgeLayers').click(function() {
		skpCallback('skp:purgeLayersFromJS');
	});
	
	$('#purgeGroups').click(function() {
		purgeGroups();
	});
	
	$('#options').click(function() {
		skpCallback('skp:openOptionsDialog');
	});
	
	$('#debug').click(function() {
		skpCallback('skp:openDebugDialog');
	});
	
	

	////////////// LAYER MENU ////////////////
	
	var timeoutId = 0;
	$('#newLayer').mousedown(function() {
		timeoutId = setTimeout(function() {
			$('#menuLayer').show();
			skpCallback('skp:getUniqueName@');
			preventLayerAdd = true;
		}, 300);
	}).bind('mouseup mouseleave', function() {
		clearTimeout(timeoutId);
		setTimeout(function() {preventLayerAdd = false;}, 10);
	});
	$(document).mouseup(function (e){ // Hide menu on click-outside
		if(preventLayerAdd == false){
			var container = $("#menuLayer");

			if (container.has(e.target).length === 0)
			{
				container.hide();
			}
		}
	});
	
	$('#onlyCurrent').bind('change', function(){        
		if($('#onlyCurrent').is(':checked')){
			$("#menuLayer").find(":radio").attr("disabled", "disabled");
			$("#menuLayer").find("label").not("#onlyCurrentLabel").css("color", "#aaa");
		} else {
			$("#menuLayer").find(":radio").removeAttr("disabled");
			$("#menuLayer").find("label").not("#onlyCurrentLabel").css("color", "");
		}
	});
	
	$('#okLayer').click(function() {
		var name = $("#newLayerName").val();
		if(name == ''){
			$("#newLayerName").css("background-color", "orange");
		}
		else{
			var only = false
			if($('#onlyCurrent').is(':checked')){
				only = true
			}
			var visibleExisting = false
			if($('#visibleExisting').is(':checked')){
				visibleExisting = true
			}
			var visibleNew = false
			if($('#visibleNew').is(':checked')){
				visibleNew = true
			}
			var params = { "name":name, "only":only, "visibleExisting":visibleExisting, "visibleNew":visibleNew }; //Json
			params = $.toJSON( params );
			skpCallback('skp:specialAddLayerFromJS@'+params);
			$("#newLayerName").css("background-color", "");
			$('#menuLayer').hide();
		}
	});
	
	$('#cancelLayer').click(function() {
		$("#newLayerName").css("background-color", "");
		$('#menuLayer').hide();
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
	
	
	// Use color by layer
	$('#colors').click(function () {
		skpCallback('skp:colorByLayer');
	});
	
	
	// Add a new Layer
	var preventLayerAdd = false;
	$('#newLayer').click(function () {
		if(preventLayerAdd == false){
			addLayerFromJS();
		}
	});
	
	
	// Add a new group
	$('#newGroup').click(addGroup);
	
	
	// Delete group or layer
	$('#trash').click(function() {trash()});
	
	// Delete group or layer
	$('#trash2').click(function() {trash(true)});
	
	// Delete group or layer
	$('#trash3').click(function() {trash(false, true)});
	
	
	$('#print').click(function() {
		// alert($("#olsortable").html());
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
			groupLayers();
		}          
	}); 
	
	$(document).keydown(function(e){ // CTRL SHIFT G
		if( e.which === 71 && (e.ctrlKey||e.metaKey) && e.shiftKey ){
			unGroupLayers();
		}          
	}); 
	
	$(document).keydown(function(e){ // CTRL E
		if( e.which === 69 && (e.ctrlKey||e.metaKey)){
			mergeLayers();
		}          
	}); 
	
	//////////////
	
	getCollapsedGroups();
	
	//////////////
	
	$(window).resize(function(){
		$('#layersContainer').css({
			height: $(window).height() - headerHeight
		});
	});
	$(window).resize();
});