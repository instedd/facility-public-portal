$(document).ready(function() {
  var elmContainer = document.getElementById('elm-menu');
  if(!elmContainer) return;
  var elm = Elm.MainMenu.embed(elmContainer, FPP.settings);
});
