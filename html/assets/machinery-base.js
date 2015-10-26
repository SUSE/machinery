function highlightCurrentScope() {
  $(".scope-navigation a").removeClass("active");
  current = $('.over-the-top:last');
  if(current.length == 0) {
    current = $('.scope_logo_big:first');
  }
  $(".scope-navigation a[href='#" + current.attr("id") + "']").addClass("active");
}

function setCurrentScopeState(anchor) {
  var header_height =  $("#nav-bar").height() + 20;
  var pos = anchor.offset();
  var top_pos = $(this).scrollTop() + header_height;
  if(top_pos >= pos.top) {
    anchor.addClass("over-the-top");
  } else {
    anchor.removeClass("over-the-top");
  }
}
