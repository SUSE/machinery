$(document).ready(function () {
  // Render the diff
  var diff = getDiff();

  // Align content below floating menu
  var header_height =  $("#nav-bar").height() + 20;
  $("#content_container").css("margin-top", header_height);
  $("a.scope_anchor, a.both_anchor").css("height", header_height);
  $("a.scope_anchor, a.both_anchor").css("margin-top", -header_height);

  $('.scope_logo_big').each(function(){
    var icon = $(this);
    $(window).scroll(function() {
      icon.removeClass('fixed');
      var pos = icon.offset();
      var top_pos = $(this).scrollTop() + header_height;
      if(top_pos >= pos.top && icon.css('position') == 'static') {
        icon.addClass('fixed').css("top", header_height);
      } else if(top_pos <= pos.top && icon.hasClass('fixed')) {
        icon.removeClass('fixed');
      }
    })
  });

  // Show title on cut-off table elements
  $('.scope td').bind('mouseenter', function(){
    var $this = $(this);

    if(this.offsetWidth < this.scrollWidth && !$this.attr('title')){
        $this.attr('title', $this.text());
    }
  });

  // Hook up the toggle links
  $(".toggle").click(function(){
    $(this).closest(".scope").find(".scope_content").collapse("toggle");
    $(this).toggleClass("collapsed");
  });

  $("#collapse-all").click(function(){
    $(".scope_content").collapse("hide");
    $(".toggle").addClass("collapsed");
    $(this).hide();
    $("#expand-all").show();
  });

  $("#expand-all").click(function(){
    $(".scope_content").collapse("show");
    $(".toggle").removeClass("collapsed");
    $(this).hide();
    $("#collapse-all").show();
  });
});
