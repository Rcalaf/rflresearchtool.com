

document.addEventListener("touchstart", function(){}, true);



$(document).ready(function(){


var cw = $('.project').width();
$('.project').css({'height':cw+'px'});


$(window).resize(function() {
    var cw = $('.project').width();
    $('.project').css({'height':cw+'px'});    
});


$('.side').click(function(){
	$(".secondary").addClass("show_secondary");
	$(".close").addClass("error").delay(700).queue(function(next){
	    $(this).addClass("show_close");
	    next();
	});
	
	$("body").addClass("overflow_hidden");
});  
 			    


});