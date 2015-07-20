$(document).ready(function () {
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

  $(".dismiss").click(function(){
    $(this).closest(".scope").hide();
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

  // Show or hide elements which are common in scope
  $(".show-common-elements").click(function(){
    $scope = $(this).closest(".scope");
    $scope.find(".scope_common_content").collapse("show");
    $scope.find(".scope_content").find(".show-common-elements").hide();
    $scope.find(".hide-common-elements").show();
    if ($(this).attr("href")){
      $('html,body').animate({scrollTop: $($(this).attr("href")).offset().top}, 'slow');
    }
    return false;
  });

  $(".hide-common-elements").click(function(){
    $scope = $(this).closest(".scope");
    $scope.find(".scope_common_content").collapse("hide");
    $(this).hide();
    $scope.find(".show-common-elements").show();
    return false;
  });

  // Unmanaged files diffs
  $("#diff-unmanaged-files-file").change(function(){
    $("#diff-unmanaged-files-content").hide();
    $("#diff-unmanaged-files-error").hide();
    $("#diff-unmanaged-files-spinner").show();
  });

    var description1 = $("body").data("description-a");
    var description2 = $("body").data("description-b");
    var url = "/compare/" + description1 + "/" + description2 + "/files/unmanaged_files" + $(this).val();
    $.get(url, function(res) {
      $("#diff-unmanaged-files-spinner").hide();
        if(res.length === 0) {
          $("#diff-unmanaged-files-error").html("Files are equal.").show();
        } else {
          $("#diff-unmanaged-files-diff").html(res);
          $("#diff-unmanaged-files-content").show();
        }
      }, "text").
      error(function(res) {
        $("#diff-unmanaged-files-spinner").hide();
        if(res.readyState == 0) {
          $("#diff-unmanaged-files-error").html("Could not download file content. Is the web server still running?").show();
        } else if(res.status == 406) {
          $("#diff-unmanaged-files-error").html("Can't generate diff, the files are binary.").show();
        } else {
          $("#diff-unmanaged-files-error").html("There was an unknown error downloading the file.").show();
        }
      });
});
