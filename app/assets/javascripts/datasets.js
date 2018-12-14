$(document).ready(function() {
  var elmDatasetsContainer = document.getElementById('elm-datasets');
  if (!elmDatasetsContainer) return;
  var app = Elm.MainDatasets.embed(elmDatasetsContainer);

  window.App.cable.subscriptions.create({ channel: "DatasetsChannel" }, {
    received: function(data) {
      app.ports.datasetEvent.send(data);
    }
  });

  droppedFiles = {};

  app.ports.requestFileUpload.subscribe(function(filename) {
    uploadFile(droppedFiles[filename]);
  });

  app.ports.showModal.subscribe(function(msg) { alert(msg); });

  const fileInput = document.querySelector('#fileElem');
  fileInput.addEventListener('change', handleFiles(fileInput.files), false);

  const dropArea = document.querySelector('body.datasets');

  ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
    dropArea.addEventListener(eventName, preventDefaults, false);
  });

  ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
    dropArea.addEventListener(eventName, preventDefaults, false)
  });

  ['dragenter', 'dragover'].forEach(eventName => {
    dropArea.addEventListener(eventName, (e) => highlight(e), false);
  });

  ['dragleave', 'drop'].forEach(eventName => {
    dropArea.addEventListener(eventName, (e) => unhighlight(e), false);
  });

  dropArea.addEventListener('drop', (e) => handleDrop(e), false);

  function handleFiles(files) {
    ([...files]).forEach(file => {
      droppedFiles[file.name] = file;
      app.ports.droppedFileEvent.send(file.name);
    });
  }

  function uploadFile(file) {
    let url = '/datasets/upload';
    let formData = new FormData()

    formData.append('file', file)

    app.ports.uploadingFile.send(file.name);

    fetch(url, {
      method: 'POST',
      body: formData,
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      }
    })
    .then(() => { app.ports.uploadedFile.send(file.name) })
    .catch(() => { /* Error. Inform the user */ })
  }

  function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  function highlight(e) {
    dropArea.classList.add('highlight');
  }

  function unhighlight(e) {
    dropArea.classList.remove('highlight')
  }

  function handleDrop(e) {
    let dt = e.dataTransfer;
    let files = dt.files;

    handleFiles(files);
  }
});
