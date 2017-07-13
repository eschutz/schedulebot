// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require turbolinks
//= require_tree .

function onReady() {
  if (Cookies.get('first_visit') == "true") {
    let gettingStarted = $("#gettingStarted");
    gettingStarted.tooltip({ template: '<div class="tooltip" role="tooltip" ><div class="tooltip-arrow" ></div><div class="tooltip-inner getting-started-tooltip" ></div></div>' });
    gettingStarted.tooltip('show');
    $(document).on('click', () => gettingStarted.tooltip('hide'));
  }

  $('[data-toggle="tooltip"]').tooltip();
  $('[data-toggle="popover"]').popover();
}

$(document).ready(onReady);
$(document).on('turbolinks:load', onReady);
