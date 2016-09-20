$(document).ready(function() {
  var elmContainer = document.getElementById('elm');
  var elm = Elm.Main.embed(elmContainer, FPP.settings);

  var commands = {
    initializeMap: function(o) {
      var latLng = [o.lat, o.lng];
      FPP.map = L.map('map', {
        zoomControl: false
      }).setView(latLng, 13);

      var tileUrl = 'https://api.mapbox.com/styles/v1/{id}/tiles/256/{z}/{x}/{y}?access_token={accessToken}';

      L.tileLayer(tileUrl, {
        maxZoom: 18,
        id: 'mapbox/streets-v9',
        accessToken: 'pk.eyJ1IjoibWZyIiwiYSI6ImNpdDBieTFhdzBsZ3gyemtoMmlpODAzYTEifQ.S9MV3eZjN39ZXh_G5_2gWQ'
      }).addTo(FPP.map);

      FPP.facilityLayerGroup = L.layerGroup().addTo(FPP.map);
    },

    addUserMarker: function (o) {
      var latLng = [o.lat, o.lng];

      var popup = L.popup({closeButton: false})
                   .setLatLng(latLng)
                   .setContent('You are here');

      FPP.userMarker = L.layerGroup([
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

      FPP.userMarker.addTo(FPP.map);
      popup.openOn(FPP.map);
    },

    addFacilityMarker: function(o) {
      console.log("addFacilityMarker");
      var latLng = [o.position.lat, o.position.lng];

      var facilityMarker =
        L.circleMarker(latLng, {
          radius: 8,
          weight: 2,
          color: 'white',
          fillColor: '#0F47AF',
          opacity: 1,
          fillOpacity: 1
        });

      FPP.facilityLayerGroup.addLayer(facilityMarker);
    },

    clearFacilityMarkers: function() {
      console.log("clearFacilityMarkers");
      FPP.facilityLayerGroup.clearLayers();
    },

    fitContent: function() {
      var controlWidth = document.getElementById("map-control").offsetWidth; // TODO: review for mobile
      var group = L.featureGroup(FPP.facilityLayerGroup.getLayers());

      if (FPP.userMarker) {
        group.addLayer(FPP.userMarker.getLayers()[0]);
      }

      FPP.map.fitBounds(group.getBounds(), { paddingTopLeft: [controlWidth, 0] });
    }
  };

  window.commands = commands;

  elm.ports.jsCommand.subscribe(function(msg) {
    commands[msg[0]](msg[1]);
  });
});
