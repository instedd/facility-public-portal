$(document).ready(function() {
  var elmContainer = document.getElementById('elm');

  var elm = Elm.Main.embed(elmContainer, FPP.settings);

  var map = L.map('map', {
    zoomControl: false
  }).setView(FPP.settings.initialPosition, 13);

  var tileUrl = 'https://api.mapbox.com/styles/v1/{id}/tiles/256/{z}/{x}/{y}?access_token={accessToken}';

  L.tileLayer(tileUrl, {
    maxZoom: 18,
    id: 'mapbox/streets-v9',
    accessToken: 'pk.eyJ1IjoibWZyIiwiYSI6ImNpdDBieTFhdzBsZ3gyemtoMmlpODAzYTEifQ.S9MV3eZjN39ZXh_G5_2gWQ'
  }).addTo(map);

  var commands = {
    displayUserLocation: function (o) {
      var latLng = [o.lat, o.lng];
      map.panTo(latLng);
      map.setZoom(14);

      var popup = L.popup({closeButton: false})
                   .setLatLng(latLng)
                   .setContent('You are here');

      var userMarker = L.layerGroup([
        L.circleMarker(latLng, {
          radius: 20,
          opacity: 0,
          fillOpacity: 0.3,
          fillColor: '#333333'
        }),
        L.circleMarker(latLng, {
          radius: 10,
          weight: 2,
          color: 'white',
          fillColor: '#F44336',
          opacity: 1,
          fillOpacity: 1
        }).bindPopup(popup),
      ]);

      userMarker.addTo(map);
      popup.openOn(map);
    }
  };

  elm.ports.jsCommand.subscribe(function(msg) {
    commands[msg[0]](msg[1]);
  });
});
