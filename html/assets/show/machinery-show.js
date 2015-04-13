angular.module("machinery-show", ["ngSanitize"]);

angular.module("machinery-show")
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
