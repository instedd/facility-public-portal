// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require leaflet
//= require leaflet.markercluster
//= require i18n
//= require i18n/translations
//= require_tree .

$(function(){
  // avoid opening the browser in mobile web app
  // mailto: and links to other domains will be handled as usual
  //
  // this makes the browser ignore rails' data-method attribute,
  // since that behaviour is achieved via jquery-ujs.
  // to make make a specific link work as usual, add the "ujs" class.
  $(document).on('click', 'a:not(.ujs)[href]', function(){
    var current = location.protocol + "//" + location.hostname;
    if (this.href.startsWith(current)) {
      event.preventDefault();
      window.location = this.href;
    }
  });
});
