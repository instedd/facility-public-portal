$(document).ready(function() {
  var elmDatasetsContainer = document.getElementById('elm-datasets');
  if (!elmDatasetsContainer) return;
  var app = Elm.MainDatasets.embed(elmDatasetsContainer);

  window.App.cable.subscriptions.create({ channel: "DatasetsChannel" }, {
    received: function(data) {
      app.ports.datasetUpdated.send(data);
    }
  });

  app.ports.watchImport.subscribe(function (pid) {
    window.App.cable.subscriptions.create({ channel: "ImportChannel", pid: pid }, {
      received: function(data) {
        console.log(data)
        app.ports.importProgress.send({ processId: pid, log: data.log })
      }
    })
  })
});
