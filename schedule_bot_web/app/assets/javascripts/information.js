// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function ready() {
  if (location.hash) {
    hashChange();
  }

  $('#featuresTable tr td').toArray().forEach(
    link => {
      $(link).on('click', () => {
        location.hash = link.getAttribute('href');
      });
    }
  );
}

$(document).ready(ready);
$(document).on('turbolinks:load', ready);

window.onhashchange = hashChange;

function hashChange() {
    let infoBox = $('#infoBox');
    infoBox.empty();
    infoBox.load(`${location.hash.substr(1)}.html`, () => {
      // Register tooltips and popovers once content has loaded.
      $('[data-toggle="tooltip"]').tooltip();
      $('[data-toggle="popover"]').popover();
    });
}
;
