$(document).ready(function() {
  var elmDatasetsContainer = document.getElementById('elm-datasets');
  if (!elmDatasetsContainer) return;
  var app = Elm.MainDatasets.embed(elmDatasetsContainer);

  window.App.cable.subscriptions.create({ channel: "DatasetsChannel" }, {
    received: function(data) {
      app.ports.datasetUpdated.send(data);
    }
  });
});
