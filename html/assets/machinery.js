$(document).ready(function () {
  // Render the system description
  var description = getDescription()

  templates = {}
  scopes = [
    "os",
    "changed_managed_files",
    "config_files",
    "unmanaged_files",
    "groups",
    "users",
    "packages",
    "patterns",
    "repositories",
    "services"
  ]


  // Enrich description with meta information summaries
  description.meta_info = {}
  $.each(scopes, function(index, scope) {
    if(description.meta[scope]) {
      description.meta_info[scope] = " (" +
        "inspected host: '" + description.meta[scope].hostname + "', " +
        "at: " + new Date(description.meta[scope].modified).toLocaleString() + ")"
    }
  })

  $.each(scopes, function(index, scope) {
    templates[scope] = Hogan.compile($("#scope_" + scope).html())
  })
  template = Hogan.compile($('#content').html())
  $("#content_container").html(
    template.render(description, templates)
  )

  // Implement filter functionality
  var run_when_done_typing = (function(){
    var timer = 0;
    return function(callback, timeout){
      clearTimeout(timer);
      timer = setTimeout(callback, timeout);
      };
  })()

  var filterdocument = (function() {
    window.scrollTo(0, 0)
    var rows = $("body").find("tr");
    if($("#filter").val() == "") {
      rows.show();
      return;
    }

    var filters = $("#filter").val().split(" ");

    rows
      .hide()
      .filter(function() {
        var $t = $(this);
        for(var i = 0; i < filters.length; ++i) {
          if($t.is(":contains('" + filters[i] + "')")) {
            return true;
          }
        }
        return false;
      })
      .show();
  })

  $("#filter").keyup(function() {
    run_when_done_typing(function() {
      filterdocument()
    }, 500)
  })

  clearFilter = function() {
    $("#filter").val("");
    filterdocument()
  }

  // Align content below floating menu
  var header_height =  $("#nav-bar").height() + 20
  $("#content_container").css("margin-top", header_height)
  $("a.scope_anchor").css("height", header_height)
  $("a.scope_anchor").css("margin-top", -header_height)

  $('.scope_logo_big').each(function(){
    var icon = $(this)
    $(window).scroll(function() {
      icon.removeClass('fixed');
      var pos = icon.offset()
      var top_pos = $(this).scrollTop() + header_height;
      console.log(pos, top_pos)
      if(top_pos >= pos.top && icon.css('position') == 'static') {
        icon.addClass('fixed').css("top", header_height);
      } else if(top_pos <= pos.top && icon.hasClass('fixed')) {
        icon.removeClass('fixed');
      }
    })
  })

  // Hook up the toggle links
  $('.toggle').click(function(){
    $(this).closest('.scope').find('.scope_content').collapse('toggle')
    $(this).toggleClass("collapsed")
  })

  $("#collapse-all").click(function(){
    $(".scope_content").collapse('hide')
    $(".toggle").addClass("collapsed")
    $(this).hide()
    $("#expand-all").show()
  })

  $("#expand-all").click(function(){
    $(".scope_content").collapse('show')
    $(".toggle").removeClass("collapsed")
    $(this).hide()
    $("#collapse-all").show()
  })

  $("img").popover({
    trigger: "hover",
    html: true
  });
  var counter;
  $(".diff-toggle").popover({
    trigger: "mouseenter",
    html: true,
    template: '<div class="popover diff-popover" role="tooltip"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>',
    content: function() {
      file = $(this).data("config-file")
      return $('*[data-config-file-diff="' + file + '"]').html()
    },
    title: function() {
      return "Changes for '" + $(this).data("config-file") + "'"
    }
  }).on("mouseenter",function () {
    clearTimeout(counter);
    var _this = this;
    $('.diff-toggle').not(_this).popover('hide');

    counter = setTimeout(function(){
      $(_this).popover("show");
      $(".diff-popover").on("mouseleave", function () {
          $('.diff-toggle').popover('hide');
      });
    }, 100);
  }).on("mouseleave", function () {
    counter = setTimeout(function(){
      if (!$(".diff-popover:hover").length) {
        $('.diff-toggle').popover('hide');
      }
    }, 500);
  });
})
