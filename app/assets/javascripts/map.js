$(document).ready(function() {
  var elmContainer = document.getElementById('elm');
  var elm = Elm.Main.embed(elmContainer, FPP.settings);

  FPP.commands = {
    initializeMap: function(o) {
      var latLng = [o.lat, o.lng];
      FPP.map = L.map('map', {
        zoomControl: false
      });

      var tileUrl = 'https://api.mapbox.com/styles/v1/{id}/tiles/256/{z}/{x}/{y}?access_token={accessToken}';

      L.tileLayer(tileUrl, {
        maxZoom: 18,
        id: 'mapbox/streets-v9',
        accessToken: 'pk.eyJ1IjoibWZyIiwiYSI6ImNpdDBieTFhdzBsZ3gyemtoMmlpODAzYTEifQ.S9MV3eZjN39ZXh_G5_2gWQ'
      }).addTo(FPP.map);

      FPP.facilityLayerGroup = L.layerGroup().addTo(FPP.map);

      FPP.map.on('moveend', function(){
        elm.ports.mapViewportChanged.send(FPP.getMapViewport());
      });

      FPP.map.setView(latLng, 13);
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
      var latLng = [o.position.lat, o.position.lng];
      var id = o.id;

      // TODO should avoid adding multiple markers (when user is panning this might happen)
      var facilityMarker =
        L.circleMarker(latLng, {
          radius: 8,
          weight: 2,
          color: 'white',
          fillColor: '#0F47AF',
          opacity: 1,
          fillOpacity: 1
        }).on('click', function(){
          elm.ports.facilityMarkerClicked.send(id);
        });

      FPP.facilityLayerGroup.addLayer(facilityMarker);
    },

    clearFacilityMarkers: function() {
      FPP.facilityLayerGroup.clearLayers();
    },

    fitContent: function() {
      var controlWidth = document.getElementById("map-control").offsetWidth; // TODO: review for mobile
      var group = L.featureGroup(FPP.facilityLayerGroup.getLayers());

      if (FPP.userMarker) {
        group.addLayer(FPP.userMarker.getLayers()[0]);
      }

      // bounds are invalid when there are no elements
      if (group.getBounds().isValid()) {
        FPP.map.fitBounds(group.getBounds(), { paddingTopLeft: [controlWidth, 0] });
      }
    }
  };

  FPP.getMapViewport = function() {
    var bounds = FPP.map.getBounds();
    var center = bounds.getCenter();
    return {
      center: [ center.lat, center.lng ], // LatLng is a ( Float, Float ).
      bounds: {
        north: bounds.getNorth(),
        south: bounds.getSouth(),
        east: bounds.getEast(),
        west: bounds.getWest()
      }
    };
  }

  elm.ports.jsCommand.subscribe(function(msg) {
    FPP.commands[msg[0]](msg[1]);
  });
});
