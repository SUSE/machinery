$(document).ready(function () {
  // Set up filter
  $(".filterable").searcher({
    inputSelector: "#filter"
  });
  $("#reset-filter").click(function() {
    $("#filter").val("").change()
  });

  // Align content below floating menu
  var header_height =  $("#nav-bar").height() + 20;
  $("#content_container, #angular-content").css("margin-top", header_height);
  $("a.scope_anchor").css("height", header_height);
  $("a.scope_anchor").css("margin-top", -header_height);

  $(".scope_logo_big").each(function(){
    var icon = $(this);
    $(window).scroll(function() {
      icon.removeClass("fixed");
      var pos = icon.offset();
      var top_pos = $(this).scrollTop() + header_height;
      if(top_pos >= pos.top && icon.css("position") == "static") {
        icon.addClass("fixed").css("top", header_height);
      } else if(top_pos <= pos.top && icon.hasClass("fixed")) {
        icon.removeClass("fixed");
      }
    })
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

  // Set up inspection details popover
  $("a.inspection_details").popover({
    template: "<div class='popover inspection-details-popover' role='tooltip'>\
      <div class='arrow'></div>\
      <div class='popover-header'>\
      <button type='button' class='close' onclick='$(\".inspection_details\").popover(\"hide\")'\
        aria-hidden='true'>&times;</button>\
      <h3 class='popover-title'></h3>\
      </div>\
      <div class='popover-content'></div>\
      </div>",
    trigger: "click",
    placement: "bottom",
    html: true,
    content: function() {
      return $("#inspection_details").html();
    },
    title: function() {
      return "Inspection details";
    }
  });
  $('.inspection-details-popover .close').click(function() { $(".inspection_details").popover("hide") });

  // Set up scope icon popovers
  $("a[data-toggle]").popover({
    trigger: "hover",
    html: true
  });

  // Set up file download links
  $(".file-download").click(function() {
    $("#file-modal-file-content").hide();
    $("#file-modal-error").hide();

    var file = $(this);
    var scope = file.parents(".scope").data("scope");
    var description = $("body").data("description");
    var url = encodeURI("/descriptions/" + description + "/files/" + scope + file.text().trim());

    $("#file-modal-download-link").attr("href", url);
    $.get(url, function(res) {
        if(res.length === 0) {
          $("#file-modal-error").html("File is empty.").show();
        } else {
          $("#file-modal-file-content").val(res).show();
          $("#file-modal-file-content").scrollTop(0);
        }
      }, "text").
      error(function(res) {
        if(res.readyState == 0) {
          $("#file-modal-error").html("Could not download file content. Is the web server still running?").show();
        } else if(res.status == 406) {
          $("#file-modal-error").html("File is binary.").show();
        } else {
          $("#file-modal-error").html("There was an unknown error downloading the file.").show();
        }
      });

    $("#file-modal-title").html(file.html());
    $("#file-modal").modal("show");

    return false;
  });
  // Set up config file diffs popovers
  var counter;
  $(".diff-toggle").popover({
    trigger: "mouseenter",
    html: true,
    template: "<div class='popover diff-popover' role='tooltip'><div class='arrow'></div><h3 class='popover-title'></h3><div class='popover-content'></div></div>",
    content: function() {
      file = $(this).data("config-file");
      return $("*[data-config-file-diff='" + file + "']").html();
    },
    title: function() {
      return "Changes for '" + $(this).data("config-file") + "'";
    }
  }).on("mouseenter",function () {
    clearTimeout(counter);
    var _this = this;
    $(".diff-toggle").not(_this).popover("hide");

    counter = setTimeout(function(){
      $(_this).popover("show");
      $(".diff-popover").on("mouseleave", function () {
        $(".diff-toggle").popover("hide");
      });
    }, 100);
  }).on("mouseleave", function () {
    counter = setTimeout(function(){
      if (!$(".diff-popover:hover").length) {
        $(".diff-toggle").popover("hide");
      }
    }, 500);
  });

  // Tooltips for service states
  $("td.systemd_enabled, td.systemd_enabled-runtime").attr("title", "Enabled through a symlink in .wants directory (permanently or just in /run).");
  $("td.systemd_linked, td.systemd_linked-runtime").attr("title", "Made available through a symlink to the unit file (permanently or just in /run).");
  $("td.systemd_masked, td.systemd_masked-runtime").attr("title", "Disabled entirely (permanently or just in /run).");
  $("td.systemd_static").attr("title", "Unit file is not enabled, and has no provisions for enabling in the \"[Install]\" section.");
  $("td.systemd_indirect").attr("title", "Unit file itself is not enabled, but it has a non-empty Also= setting in the \"[Install]\" section, listing other unit files that might be enabled.");
  $("td.systemd_disabled").attr("title", "Unit file is not enabled.");
  $("td.sysvinit_on").attr("title", "Service is enabled");
  $("td.sysvinit_off").attr("title", "Service is disabled");

  // Show title on cut-off table elements
  $('.scope td').bind('mouseenter', function(){
    var $this = $(this);

    if(this.offsetWidth < this.scrollWidth && !$this.attr('title')){
      $this.attr('title', $this.text());
    }
  });
});
