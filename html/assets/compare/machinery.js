$(document).ready(function () {
  // Render the system description
  var diff = getDiff();

  templates = {};
  scopes = [
    "os",
    "os_partial",
    "changed_managed_files",
    "changed_managed_files_partial",
    "config_files",
    "config_files_partial",
    "unmanaged_files",
    "groups",
    "users",
    "packages",
    "packages_partial",
    "patterns",
    "repositories",
    "repositories_partial",
    "services"
  ];

  $.each(scopes, function(index, scope) {
    templates[scope] = Hogan.compile($("#scope_" + scope).html());
  });

  other_templates = [
    "description_a",
    "description_b",
    "both_descriptions"
  ];
  $.each(other_templates, function(index, template) {
    templates[template] = Hogan.compile($("#" + template + "_partial").html());
  });
  template = Hogan.compile($('#content').html());
  $("#content_container").html(
    template.render(diff, templates)
  );

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
});
