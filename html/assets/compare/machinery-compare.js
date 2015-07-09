angular.module("machinery-compare", []);

angular.module("machinery-compare")
  .config(function($locationProvider) {
    $locationProvider.html5Mode({enabled: true, requireBase: false});
  })
  .controller("compareController", function($scope, $http, $timeout, $anchorScroll) {
    $http.get("/compare/" + $("body").data("description-a") + "/" + $("body").data("description-b") + ".json").then(function(result) {
      // Scroll to desired scope when rendering is done
      $timeout(function() {
        $anchorScroll();
      }, 0);
      $scope.diff = result.data;
    });
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
  .directive("changed", function() {
    return {
      template: "<h3>In both with different attributes:</h3>"
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


// Scope specific directives
angular.module("machinery-compare")
  .directive("changedPackages", function() {
    return {
      restrict: "E",
      link: function(scope, element, attrs) {
        scope.$watch("diff", function(){
          if(scope.diff.packages == undefined) {
            return;
          }
          var elements = [];

          angular.forEach(scope.diff.packages.changed, function(value) {
            var changes = [];
            var relevant_attributes = ["version", "vendor", "arch"];

            if(value[0].version == value[1].version) {
              relevant_attributes.push("release");
              if(value[0].version == value[1].version) {
                relevant_attributes.push("checksum");
              }
            }

            angular.forEach(relevant_attributes, function(attribute) {
              if(value[0][attribute] != value[1][attribute]) {
                changes.push(attribute + ": " + value[0][attribute] + " ↔ " + value[1][attribute]);
              }
            });

            elements.push(value[0].name + " (" + changes.join(", ") + ")");
          });

          scope.changed_elements = elements;
        });
      },
      templateUrl: "scope_packages_changed_partial"
    };
  });
