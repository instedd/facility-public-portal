$(document).ready(function() {
  var elmContainer = document.getElementById('elm');
  var elm = Elm.Main.embed(elmContainer, FPP.settings);

  FPP.mapSettings = {
    maxZoom: 18,
    minZoom: 5,
    id: 'mapbox/streets-v9',
    accessToken: 'pk.eyJ1IjoibWZyIiwiYSI6ImNpdDBieTFhdzBsZ3gyemtoMmlpODAzYTEifQ.S9MV3eZjN39ZXh_G5_2gWQ'
  };

  FPP.commands = {
    initializeMap: function(o) {
      var latLng = [o.lat, o.lng];
      FPP.map = L.map('map', {
        zoomControl: false,
        attributionControl: false
      });
      FPP._fitContentUsingPadding = false;

      var tileUrl = 'https://api.mapbox.com/styles/v1/{id}/tiles/256/{z}/{x}/{y}?access_token={accessToken}';

      L.tileLayer(tileUrl, FPP.mapSettings).addTo(FPP.map);

      FPP.facilityClusterGroup = L.markerClusterGroup({
        animate: false,
        showCoverageOnHover: false,
        zoomToBoundsOnClick: false,
        disableClusteringAtZoom: FPP.mapSettings.maxZoom,
        spiderfyOnMaxZoom: false,
        removeOutsideVisibleBounds: true,
        singleMarkerMode: true,
        iconCreateFunction: FPP._createClusterIcon,
        maxClusterRadius: function(zoom) {
          var table = {
            5: 15,
            6: 15,
            7: 10,
            8: 10,
            9: 10,
            10: 10,
            11: 3,
            12: 3,
            13: 3,
            14: 3,
            15: 3,
            16: 3,
            17: 1,
            18: 1
          };
          return table[zoom];
        }
      }).on('clusterclick', FPP._clusterClick)
        .on('click', FPP._facilityClick)
        .addTo(FPP.map);

      FPP.userMarker = null;
      FPP.highlightedFacilityMarker = null;

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
          className: 'userMarker-outer'
        }),
        L.circleMarker(latLng, {
          radius: 10,
          className: 'userMarker'
        }).bindPopup(popup),
      ]);

      FPP.userMarker.addTo(FPP.map);
      FPP._userMarkerToFront();
      popup.openOn(FPP.map);
    },

    addFacilityMarker: function(facility) {
      var latLng = [facility.position.lat, facility.position.lng];

      // TODO should avoid adding multiple markers (when user is panning this might happen)
      var facilityMarker = L.marker(latLng, { facility: facility });

      FPP.facilityClusterGroup.addLayer(facilityMarker);

      FPP._userMarkerToFront();
    },


    addFacilityMarkers: function(facilities) {
      var markers = $.map(facilities, function(facility) {
        var latLng = [facility.position.lat, facility.position.lng];
        // TODO should avoid adding multiple markers (when user is panning this might happen)
        return L.marker(latLng, { facility: facility });
      });

      FPP.facilityClusterGroup.addLayers(markers);

      FPP._userMarkerToFront();
    },

    clearFacilityMarkers: function() {
      FPP.facilityClusterGroup.clearLayers();
    },

    setHighlightedFacilityMarker: function(facility) {
      if (FPP.highlightedFacilityMarker) {
        FPP.facilityClusterGroup.removeLayer(FPP.highlightedFacilityMarker);
      }

      $("#map").addClass("grey-facilities");

      var latLng = [facility.position.lat, facility.position.lng];
      FPP.highlightedFacilityMarker =  L.marker(latLng, { facility: facility });

      FPP.facilityClusterGroup.addLayer(FPP.highlightedFacilityMarker);

      FPP._userMarkerToFront();
    },

    removeHighlightedFacilityMarker: function () {
      $("#map").removeClass("grey-facilities");
      if (FPP.highlightedFacilityMarker) {
        FPP.map.removeLayer(FPP.highlightedFacilityMarker);
      }
    },

    fitContent: function() {
      var w = Math.max(document.documentElement.clientWidth, window.innerWidth || 0);
      var mapControl = document.getElementById("map-control");
      var isMobile = w <= 992; // same media query as application.css
      var paddingLeft = !isMobile && FPP._fitContentUsingPadding ? 340 : 0; // only perform padding if desktop
      var group;

      if (FPP.highlightedFacilityMarker == null) {
        group = L.featureGroup(FPP.facilityClusterGroup.getLayers());
      } else {
        group = L.featureGroup([FPP.highlightedFacilityMarker]);
      }
      var fitBoundsOptions = { paddingTopLeft: [paddingLeft,0] };

      if (FPP.userMarker) {
        group.addLayer(FPP.userMarker.getLayers()[0]);
      }

      // bounds are invalid when there are no elements
      if (group.getBounds().isValid()) {
        FPP.map.fitBounds(group.getBounds(), fitBoundsOptions);
      }
    },

    fitContentUsingPadding: function(padded) {
      FPP._fitContentUsingPadding = padded;
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
  };

  FPP._userMarkerToFront = function() {
    if (FPP.userMarker) {
      FPP.userMarker.eachLayer(function(layer){
        layer.bringToFront();
      });
    }
  };

  FPP._createClusterIcon = function(cluster) {
    var classes = ['clusterMarker'];
    var representative = FPP._clusterRepresentative(cluster);

    if (FPP._isHighlightedFacility(representative)) {
      classes.push('highlighted');
    } else if (representative.facilityType === "Health Center") {
      classes.push('small');
    }

    return L.divIcon({className: classes.join(' ')});
  } ;

  FPP._clusterRepresentative = function(cluster) {
    if ($.inArray(FPP.highlightedFacilityMarker, cluster.getAllChildMarkers()) >= 0) {
      return FPP.highlightedFacilityMarker.options.facility;
    } else {
      return cluster.getAllChildMarkers()[0].options.facility;
    }
  };

  FPP._isHighlightedFacility = function(facility) {
    if (!FPP.highlightedFacilityMarker) {
      return false;
    }

    return FPP.highlightedFacilityMarker.options.facility.id == facility.id;
  };

  FPP._facilityClick = function(target) {
    var facility = target.layer.options.facility;
    elm.ports.facilityMarkerClicked.send(facility.id);
  };

  FPP._clusterClick = function(target) {
    var facility = FPP._clusterRepresentative(target.layer);
    elm.ports.facilityMarkerClicked.send(facility.id);
  };

  elm.ports.jsCommand.subscribe(function(msg) {
    FPP.commands[msg[0]](msg[1]);
  });
});
