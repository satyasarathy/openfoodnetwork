Darkswarm.directive "tabsetCtrl", (Tabsets, $location) ->
  restrict: "C"
  scope:
    id: "@"
    selected: "@"
    navigate: "="
    prefix: "@?"
    alwaysopen: "="
  controller: ($scope, $element) ->
    if $scope.navigate
      path = $location.path()?.match(/^\/\w+$/)?[0]
      $scope.selected = path[1..] if path

    this.toggle = (name) ->
      state = if $scope.alwaysopen then 'open' else null
      Tabsets.toggle($scope.id, name, state)

    this.select = (selection) ->
      $scope.$broadcast("selection:changed", selection)
      $element.toggleClass("expanded", selection?)
      $location.path(selection) if $scope.navigate

    this.registerSelectionListener = (callback) ->
      $scope.$on "selection:changed", (event, selection) ->
        callback($scope.prefix, selection)

    this

  link: (scope, element, attrs, ctrl) ->
    Tabsets.register(ctrl, scope.id, scope.selected)
