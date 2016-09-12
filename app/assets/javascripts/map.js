$( document ).ready(function() {
  Elm.Main.embed(document.getElementById('elm'));

  var map = L.map('map', {
    zoomControl: false
  }).setView([51.505, -0.09], 13);

  var tileUrl = 'https://api.mapbox.com/styles/v1/{id}/tiles/256/{z}/{x}/{y}?access_token={accessToken}';

  L.tileLayer(tileUrl, {
    maxZoom: 18,
    id: 'mfr/cit0bzmcg007e2xr0r2b0m1b5',
    accessToken: 'pk.eyJ1IjoibWZyIiwiYSI6ImNpdDBieTFhdzBsZ3gyemtoMmlpODAzYTEifQ.S9MV3eZjN39ZXh_G5_2gWQ'
  }).addTo(map);
});
