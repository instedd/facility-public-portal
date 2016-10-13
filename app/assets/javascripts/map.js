$(document).ready(function() {
  var elmContainer = document.getElementById('elm');
  var elm = Elm.Main.embed(elmContainer, FPP.settings);

  FPP.mapSettings = {
    maxZoom: 18,
    minZoom: 8,
    id: 'mapbox/streets-v9',
    accessToken: 'pk.eyJ1IjoibWZyIiwiYSI6ImNpdDBieTFhdzBsZ3gyemtoMmlpODAzYTEifQ.S9MV3eZjN39ZXh_G5_2gWQ'
  };

  FPP.commands = {
    initializeMap: function(o) {
      var latLng = [o.lat, o.lng];
      FPP.map = L.map('map', {
        zoomControl: false,
        attributionControl: false,
        bounceAtZoomLimits: false
      });
      FPP._fitContentUsingPadding = false;

      L.tileLayer('https://api.mapbox.com/styles/v1/{id}/tiles/256/{z}/{x}/{y}?access_token={accessToken}', FPP.mapSettings).addTo(FPP.map);

      FPP.facilityClusterGroup = FPP._createClusterLayer().addTo(FPP.map);
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

    resetFacilityMarkers: function(facilities) {
      FPP.commands.clearFacilityMarkers();
      FPP.commands.addFacilityMarkers(facilities);
    },

    addFacilityMarkers: function(facilities) {
      var markers = $.map(facilities, function(facility) {
        var latLng = [facility.position.lat, facility.position.lng];
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

        // remove previous highlight
        var highlightedCluster = FPP.facilityClusterGroup.getVisibleParent(FPP.highlightedFacilityMarker);
        FPP.highlightedFacilityMarker = null;
        FPP.facilityClusterGroup.refreshClusters(highlightedCluster);
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
        FPP.facilityClusterGroup.refreshClusters();
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

  FPP._createClusterLayer = function() {
    return L.markerClusterGroup({
      animate: false,
      showCoverageOnHover: false,
      zoomToBoundsOnClick: false,
      spiderfyOnMaxZoom: false,
      disableClusteringAtZoom: 14,
      removeOutsideVisibleBounds: false, // clusters and markers too far from the viewport are removed for performance
      singleMarkerMode: true,  // draw single facilities as if they were a 1-point cluster
      chunkedLoading: true, // allow other tasks to be performed by the browser in the middle of cluster calculation
      iconCreateFunction: function(cluster) {
        var classes = ['clusterMarker'];
        var representative = FPP._clusterRepresentative(cluster);

        if (FPP._isHighlightedFacility(representative)) {
          classes.push('highlighted');
        }

        if (representative.facilityType === "Health Center") {
          classes.push('small');
        }

        return L.divIcon({className: classes.join(' ')});
      },
      maxClusterRadius: function(zoom) {
        if (zoom < 7) {
          return 15;
        } else if (zoom < 11) {
          return 10;
        } else {
          return 3;
        }
      }
    }).on('clusterclick', FPP._clusterClick)
      .on('click', FPP._facilityClick);
  };

  FPP._clusterRepresentative = function(cluster) {
    // TODO
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
