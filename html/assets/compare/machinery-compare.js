angular.module("machinery-compare", []);

angular.module("machinery-compare")
  .config(function($locationProvider) {
    $locationProvider.html5Mode({enabled: true, requireBase: false});
  })
  .controller("compareController", function($scope) {
    $scope.diff = getDiff();
  })
  .directive("onlyInA", function() {
    return {
      template: "<h3>Only in '{{diff.meta.description_a}}':</h3>"
    };
  })
  .directive("onlyInB", function() {
    return {
      template: "<h3>Only in '{{diff.meta.description_b}}':</h3>"
    };
  })
  .directive("inBoth", function() {
    return {
      template: "<h3>In both descriptions:</h3>"
    };
  })
  .directive("renderTemplate", function() {
    return {
      restrict: "E",
      scope: {
        object: "=object"
      },
      link: function(scope, element, attrs) {
        scope.templateUrl = attrs.template;
      },
      template: '<div ng-include="templateUrl"></div>'
    };
  });
