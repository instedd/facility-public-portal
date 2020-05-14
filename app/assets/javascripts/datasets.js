$(document).ready(function() {
  var elmDatasetsContainer = document.getElementById('elm-datasets');
  if (!elmDatasetsContainer) return;
  var app = Elm.MainDatasets.embed(elmDatasetsContainer, '/datasets/download/');

  window.App.cable.subscriptions.create({ channel: "DatasetsChannel" }, {
    received: function(data) {
      app.ports.datasetEvent.send(data);
    }
  });

  droppedFiles = {};

  app.ports.requestFileUpload.subscribe(function(args) {
    const [filename, fileUrl] = args;
    if (fileUrl) droppedFiles[filename] = { ...droppedFiles[filename], url: fileUrl, name: filename };
    uploadFile(droppedFiles[filename]);
  });

  app.ports.showModal.subscribe(function(msg) { alert(msg); });

  const fileInput = document.querySelector('#fileElem');
  fileInput.addEventListener('change', handleFiles(fileInput.files), false);

  const dropArea = document.querySelector('body.datasets');

  ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(function (eventName) {
    dropArea.addEventListener(eventName, preventDefaults, false);
  });

  ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(function (eventName) {
    dropArea.addEventListener(eventName, preventDefaults, false)
  });

  ['dragenter', 'dragover'].forEach(function (eventName) {
    dropArea.addEventListener(eventName, function (e) { highlight(e) }, false);
  });

  ['dragleave', 'drop'].forEach(function (eventName) {
    dropArea.addEventListener(eventName, function (e) { unhighlight(e) }, false);
  });

  dropArea.addEventListener('drop', function (e) { handleDrop(e) }, false);

  function handleFiles(files) {
    for (i = 0; i < files.length; i++) {
      var file = files[i];
      droppedFiles[file.name] = file;
      app.ports.droppedFileEvent.send(file.name);
    }
  }

  async function uploadFile(file) {
    var url = '/datasets/upload';
    var formData = new FormData()
    
    if (!file.url) {
      formData.append('file', file)
    } else {
      formData.append('url', file.url);
      formData.append('name', file.name);
    }

    app.ports.uploadingFile.send(file.name);

    let result = await fetch(url, {
      method: 'POST',
      body: formData,
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      }
    });
    result = await result.json()
    app.ports.uploadedFile.send([ file.name, result.error || null ]);
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
    var dt = e.dataTransfer;
    var files = dt.files;

    handleFiles(files);
  }
});
