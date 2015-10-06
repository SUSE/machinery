/*
 * text {String} - printing text
 * n {Number} - from what letter to start
 */


$(document).ready(function(){
  
  //Check to see if the window is top if not then display button
  $(window).scroll(function(){
    if ($(this).scrollTop() > 100) {
      $('.scrollToTop').fadeIn();
    } else {
      $('.scrollToTop').fadeOut();
    }
  });
  
  //Click event to scroll to top
  $('.scrollToTop').click(function(){
    $('html, body').animate({scrollTop : 0},800);
    return false;
  });
  
});

/* for the panel used for man */
$(document).ready(function() {
    $('#man').on('click', function() {
        $('div.panel').animate({
            'width': 'show'
        }, 1000, function() {
            $('div.home').fadeIn(500);
        });
    });



    $('span.close').on('click', function() {
        $('div.home').fadeOut(500, function() {
            $('div.panel').animate({
                'width': 'hide'
            }, 1000);
        });
    });
});


/* open close panel from cynthia */
$(document).on("ready", function() {
  initMenu(false);
}) 

function initMenu(status){

  if(!status){
    $('#menu-btn1').click(open_feedback);  
  }
  else {
    $('#menu-btn1').click(close_feedback);  
  }

}

function open_feedback() {
  /* when the user clics to open the menu */
  $('#menu').animate( {
    left: '0px' }, 
    500, function() {
    $('.all-container').animate( {
      padding: '0 0 0 270px ' },
      500, function(){
        $('#menu-btn1').unbind();
        initMenu(true);
      });
  });
};

function close_feedback() {
  /* When the user clics on the X to close the feedback form */
  $('#menu').animate( {
    left: '-=270px'}, 
    500, function() {
      $('.all-container').animate( {
        padding: '0' },
        500, function(){
          $('#menu-btn1').unbind();
          initMenu(false);
        });
  });
};

$(document).on("ready", function(){
  $(".showcase").on("click", function(){
    useCasesShowcase($(this));
  })
});

function useCasesShowcase(elem) {
  var newImage = "img/" + $(elem).attr("id") + ".png"
  var newText = "#" + $(elem).attr("id") + "-text"
  var newTextContent = $(newText).text()
  $("#img-usecase").fadeOut('slow', function() {
    $(this).empty();
    $(this).append("<img src='" + newImage + "' />").fadeIn("slow");
  });
  $("#textHolder").fadeOut('slow', function() {
    $(this).empty();
    $(this).html( newTextContent ).fadeIn("slow");
  });
}

$(function() {
  $('a[href*=#]:not([href=#])').click(function() {
    if (location.pathname.replace(/^\//,'') == this.pathname.replace(/^\//,'') && location.hostname == this.hostname) {
      var target = $(this.hash);
      target = target.length ? target : $('[name=' + this.hash.slice(1) +']');
      if (target.length) {
        $('html,body').animate({
          scrollTop: target.offset().top
        }, 1000);
        return false;
      }
    }
  });
});


/* scroll to the top */

/* Universal System Description - slide */
$(document).on("ready", function(){
  
  $(".USDbutton").on("click", function(){
    if($(".USDbutton").hasClass("USDactive")){
      $(".USDbutton").removeClass("USDactive")
    }
    $(this).addClass("USDactive");
  })

  $('.carousel').carousel({
    interval: false
  })
  
})




