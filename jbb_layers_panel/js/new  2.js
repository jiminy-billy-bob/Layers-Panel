	$(document).on('click', '.visibility', function (e) {
		
		var  goOn = true; 
		
		if ($(this).parent().parent().hasClass("group")) { // If this is group, item = group
			var group = $(this).parent().parent();
		}
		
		while ($(this).parents(".group").hasClass("hiddenGroup")) { // If nested in hidden group, click the hidden group
			goOn = false;
			if(group) {
				if(group[0] === $(this).parents(".hiddenGroup").last()[0]) {  // Go on if this group is highest hidden group
					goOn = true; 
					group.removeClass("hiddenGroup");
				}
				else { 
					$(this).parents(".hiddenGroup").last().removeClass("hiddenGroup").children(".lidiv").children(".visibility").click();
				}
			}
			else { 
				$(this).parents(".hiddenGroup").last().removeClass("hiddenGroup").children(".lidiv").children(".visibility").click();
			}
			
			if ($(this).hasClass("hidden")) { goOn = true; }
		}
		
	
		if (goOn) { // Not nested in hidden group
	
			if ($(this).parent().parent().hasClass("group")) { // If group
				if ($(this).is(".hidden, .hiddenByGroup")) { // Hidden
					$(this).addClass("visible").removeClass("hidden");
					$(this).parent().parent().children("ol").children(".layer").children(".lidiv").children(".hiddenByGroup").each(function(i) { // Show hiddenByGrouped layers
						layerID = $(this).parent().parent().attr('id');
						layerID = layerID.replace('layer_', '');
						showLayerFromJS(layerID);
						$(this).removeClass("hiddenByGroup");
					});
					$(this).parent().parent().children("ol").find(".group").children(".lidiv").children(".hiddenByGroup").each(function(i) { // Show hiddenByGrouped groups
						$(this).click();
						$(this).removeClass("hiddenByGroup");
					});
					$(this).removeClass("hiddenGroup");
				}
				else { // visible
					if ($(this).parent().parent().children("ol").find(".layer").children(".lidiv").children(".active").hasClass("enabled")) { // If active layer is nested in this group
						alert('You cannot hide the current layer.');
					}
					else {
						$(this).addClass("hidden").removeClass("visible");
						$(this).parent().parent().addClass("hiddenGroup");
						$(this).parent().parent().children("ol").find(".layer").find(".visible:not(.hiddenByGroup)").each(function(i) { // HideGroup nested visible layers
							layerID = $(this).parent().parent().attr('id');
							layerID = layerID.replace('layer_', '');
							hideLayerFromJS(layerID);
							$(this).addClass("hiddenByGroup");
						});
						$(this).parent().parent().children("ol").find(".group").find(".visible:not(.hiddenByGroup)").each(function(i) { // HideGroup nested visible groups
							$(this).addClass("hiddenByGroup");
						});
					}
				}
			}
			
			else { // If layer
			
				if ($(this).parent().children(".active").hasClass("enabled")) { // If active layer
					alert('You cannot hide the current layer.');
				}
				
				else {	// Not active layer
					layerID = $(this).parent().parent().attr('id');
					layerID = layerID.replace('layer_', '');
					if ($(this).hasClass("visible")) {
						hideLayerFromJS(layerID);
					}
					else {
						showLayerFromJS(layerID);
					}
					// $(this).toggleClass("hidden").toggleClass("visible");
				}
			}
		
		}
	});