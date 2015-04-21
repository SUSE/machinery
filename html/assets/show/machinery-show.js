angular.module("machinery-show", ["ngSanitize"]);

angular.module("machinery-show")
  .config(function($locationProvider) {
    $locationProvider.html5Mode({enabled: true, requireBase: false});
  })
  .controller("showController", function($scope) {
    $scope.description = getDescription();


    $scope.description.meta_info = {};
    angular.forEach($scope.description, function(index, scope) {
      if($scope.description.meta[scope]) {
        $scope.description.meta_info[scope] = " (" +
        "inspected host: '" + $scope.description.meta[scope].hostname + "', " +
        "at: " + new Date($scope.description.meta[scope].modified).toLocaleString() + ")";
      }
    });
  })
  .directive("scopeHeader", function(){
    return {
      restrict: "E",
      scope: {
        summary: "=summary",
        logo: "=logo",
        singular: "=singular",
        plural: "=plural",
        title: "=title",
        meta: "=meta",
        count: "=count",
        additionalSummary: "=additionalSummary"
      },
      template:
      "<div class='row'>" +
        "<div class='col-xs-1'>" +
          "<img class='over scope_logo_big' data-content='<p>{{summary}}</p>' data-toggle='popover' src='{{logo}}' title='' data-original-title='{{title}}' style='top: 125px;'>" +
          "<span class='toggle' title='Collapse/Expand'></span>" +
        "</div>" +
        "<div class='col-xs-11'>" +
          "<h2>" +
            "{{title}}" +
            "&nbsp;<div class='scope-summary'>" +
              "{{additionalSummary}}" +
              "<ng-pluralize count='count' when=\"{'1': '1 {{singular}}', 'other': '{} {{plural}}'}\"></ng-pluralize>" +
              " (" +
              "inspected host: '{{meta.hostname}}', " +
              "at: {{meta.modified | date:'medium'}}" +
              ")" +
            "</div>" +
          "</h2>" +
        "</div>" +
      "</div>"
    }
  })
  .directive("metaInfo", function(){
    return {
      restrict: "E",
      scope: { meta: "=data"},
      template:
        " (" +
          "inspected host: '{{meta.hostname}}', " +
          "at: {{meta.modified | date:'medium'}}" +
        ")"
    }
  });
