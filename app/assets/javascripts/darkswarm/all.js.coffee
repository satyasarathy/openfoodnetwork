#= require jquery
#= require jquery_ujs
#= require jquery.ui.all
#= require spin
#
#= require angular
#= require angular-cookies
#= require angular-sanitize
#= require angular-animate
#= require angular-resource
#= require lodash.underscore.js
# bluebird.js is a dependency of angular-google-maps.js 2.0.0
#= require bluebird.js
#= require angular-scroll.min.js
#= require angular-google-maps.min.js
#= require ../shared/mm-foundation-tpls-0.9.0-20180826174721.min.js
#= require ../shared/ng-infinite-scroll.min.js
#= require ../shared/angular-local-storage.js
#= require ../shared/angular-slideables.js
#= require angularjs-file-upload
#= require i18n/translations

#= require angular-rails-templates
#= require_tree ../templates
#
#= require angular-backstretch.js
#= require angular-flash.min.js
#
#= require moment
#= require moment/de.js
#= require moment/en-gb.js
#= require moment/es.js
#= require moment/fr.js
#= require moment/it.js
#= require moment/nb.js
#= require moment/pt-br.js
#= require moment/pt.js
#= require moment/sv.js
#
#= require modernizr
#
#= require foundation
#= require ./darkswarm
#= require ./overrides
#= require_tree ./mixins
#= require_tree ./directives
#= require_tree .

$ ->
  # Hacky fix for issue - http://foundation.zurb.com/forum/posts/2112-foundation-5100-syntax-error-in-js
  Foundation.set_namespace ""
  $(document).foundation()
