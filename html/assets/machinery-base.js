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

$(document).ready(function () {
  $(".dismiss").click(function(){
    $(this).closest(".scope").hide();
  });

  $(".btn-reset").click(function(){
    $("#filter").val("").change();
  });
})

$(document).on("click", ".open-description-selector", function () {
  if ($(this).hasClass("show")) {
    $(".description-selector-action").text("show");
    $("a.show-description").show();
    $("a.compare-description").hide();
  }else{
    $(".description-selector-action").text("compare");
    $("a.show-description").hide();
    $("a.compare-description").show();
  }
});

$(window).load(function(){
  if (window.location.pathname == "/") {
    descriptionSelector = $('#description-selector')
    descriptionSelector.modal({backdrop: 'static', keyboard: false});
    descriptionSelector.find("button[data-dismiss='modal']").attr("disabled", true)

  }
});
