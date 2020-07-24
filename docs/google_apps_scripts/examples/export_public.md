### ExportPublic.gs

```
// Activate Resources -> Drive Api V2 before running the script

function showExportPublicForm() {
  const template = HtmlService.createTemplateFromFile("exportPublicForm");
  const html = template.evaluate();
  SpreadsheetApp.getUi().showSidebar(html);
}

function exportPublic(params) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  
  const dataSheetParam = params.dataSheet
  const columnsToExportParam = params.columnsToExport
  const destinationFolderParam = params.destinationFolder
  const destinationFileParam = params.destinationFile
  
  const dataSheet = ss.getSheetByName(dataSheetParam);
  const columnsToExportSheet = ss.getSheetByName(columnsToExportParam);
  
  if (!dataSheet) {
    return {success: false, message: `There is no sheet with name '${dataSheetParam}'`}
  }
  
  if (!columnsToExportSheet) {
    return {success: false, message: `There is no sheet with name '${columnsToExportParam}'`}
  }
  
  let folder = DriveApp.getFoldersByName(destinationFolderParam)
  if (folder.hasNext()) {
    folder = folder.next()
  } else {
    folder = DriveApp.createFolder(destinationFolderParam);
  }
  
  const folderId = folder.getId();
  const file = Drive.Files.insert({mimeType: MimeType.GOOGLE_SHEETS, title: destinationFileParam, parents: [{id: folderId}]});
  DriveApp.getFileById(file.id).setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  const ssNew = SpreadsheetApp.openById(file.id);
  const ssNewSheet = ssNew.getActiveSheet();
  
  const sheetCopy = dataSheet.copyTo(ssNew);
  const content = transpose(getColumnsContent(sheetCopy, columnsToExportSheet));
  const rowsLength = content.length;
  const columnsLength = (content[0] || []).length;
  ssNew.deleteSheet(sheetCopy);
  ssNewSheet.getRange(1,1, rowsLength, columnsLength).setValues(content);
  
  return {success: true, message: `Data succesfully exported to '${destinationFolderParam}\/${destinationFileParam}'`}
}

function getColumnsContent(dataSheet, columnsToExportSheet) {
  const dataRange = dataSheet.getDataRange();
  // Numeric fields as plain: https://stackoverflow.com/a/19545263
  dataRange.setNumberFormat('@STRING@');
  const values = dataRange.getValues();
  const headers = values[0]
  
  const columnsDataRange = columnsToExportSheet.getDataRange();
  const columnsToExport = columnsToExportSheet.getDataRange().getValues().map(row => row[0]);
  
  const columnsContent = []
  for ( i = 0; i < headers.length; i++) {
    if (columnsToExport.includes(headers[i])) {
      columnsContent.push(getColumnValuesAtIndex(values, i));
    }
  }
  
  return columnsContent
}

function getColumnValuesAtIndex(values, index) {
  const nRows = values.length
  const columnValues = []
  
  for ( r = 0; r < nRows; r++ ) {
    columnValues.push(values[r][index])
  }
  
  return columnValues
}

function transpose(array) {
  return (array[0] || []).map((_, colIndex) => array.map(row => row[colIndex]));
}
```

### exportPublicForm.html

```
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <?!= include("css-exportPublicForm"); ?>
  </head>
  <body>
    <div class="container">
      <div id="runningContainer">
        <div id="running">Running...</div>
        <i class="material-icons spin">sync</i>
      </div>
      <h6 class="form-title">Export to Public Sheet</h6>
      <div class="row">
        <form class="col s12" onkeydown="preventSubmitOnEnter(event)">
          <div class="row">
            <div class="input-field col s12">
              <input placeholder="lab_aslm_survey_" id="dataSheet" value="lab_aslm_survey_" type="text">
              <label for="dataSheet">Data Sheet</label>
              <span class="helper-text" data-error="Missing 'Data' sheet">Sheet containing the data to be processed</span>
            </div>
          </div>
          <div class="row">
            <div class="input-field col s12">
              <input placeholder="columnsToExport" id="columnsToExport" type="text" value="columnsToExport">
              <label for="columnsFilter">Columns to be Exported</label>
              <span class="helper-text" data-error="Missing 'Columns to Export' sheet">Sheet containing the list of columns to be exported</span>
            </div>
          </div>
          <div class="row">
            <div class="input-field col s12">
              <input placeholder="Destination Folder" id="destinationFolder" type="text">
              <label for="destinationFolder">Destination Folder</label>
              <span class="helper-text" data-error="Missing Destination Folder">If destination folder doesn't exist, it creates one</span>
            </div>
          </div>
          <div class="row">
            <div class="input-field col s12">
              <input placeholder="Destination File" id="destinationFile" type="text">
              <label for="destinationFile">Destination File</label>
              <span class="helper-text" data-error="Missing Destination File">Destination File Name</span>
            </div>
          </div>
          <div class="row">
            <button id="btn-export" class="waves-effect waves-light btn-small disabled">
              Export
              <i class="material-icons right">send</i>
            </button>
          </div>
        </form>
      </div>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
      <script>
        document.getElementById('btn-export').addEventListener('click', (event) => submit(event))
        
        function preventSubmitOnEnter(e) {
          if (e.key === "Enter") {
            e.preventDefault();
          }
        }
        
        var inputFields = ['dataSheet', 'columnsToExport', 'destinationFolder', 'destinationFile'];
        inputFields.forEach((input) => {
          var element = document.getElementById(input);
          element.addEventListener("keyup", (event) => onInputKeyUp(event, input));
        })
        
        function onInputKeyUp(event, input) {
          var element = document.getElementById(input);
          var button = document.getElementById('btn-export');
          
          if (element.value.length === 0) {
            element.classList.add('invalid');
          } else {
            element.classList.remove('invalid');
          }
          
          if (inputFields.map((input) => document.getElementById(input)).every((element) => (element.value.length > 0))) {
            button.classList.remove('disabled');
          } else {
            button.classList.add('disabled');
          }
        }
        
        function submit(event) {
          event.preventDefault();
          var button = document.getElementById('btn-export');
          var runningContainer = document.getElementById('runningContainer');
          const DISPLAY_LENGTH_START = 3000;
          const DISPLAY_LENGTH_RESULT = 5000;
          var dataSheet = document.getElementById('dataSheet').value;
          var columnsToExport = document.getElementById('columnsToExport').value;
          var destinationFolder = document.getElementById('destinationFolder').value;
          var destinationFile = document.getElementById('destinationFile').value;
          
          var params = {
            dataSheet: dataSheet,
            columnsToExport: columnsToExport,
            destinationFolder: destinationFolder,
            destinationFile: destinationFile
          }
          
          button.classList.add('disabled');
          runningContainer.style.display = "flex";
          M.toast({html: 'Script started. Please wait until it finishes', displayLength: DISPLAY_LENGTH_START});
         
          google.script.run
          .withFailureHandler((error) => { 
            M.toast({html: `Error while running the script: ${error}`, classes: 'error', displayLength: DISPLAY_LENGTH_RESULT});
            button.classList.remove('disabled');
            runningContainer.style.display = "none";
          })
          .withSuccessHandler((result) => {
            if(result.success) {
              M.toast({html: result.message, classes: 'green', displayLength: DISPLAY_LENGTH_RESULT});
            } else {
              M.toast({html: result.message, classes: 'error', displayLength: DISPLAY_LENGTH_RESULT});
            }
            button.classList.remove('disabled');
            runningContainer.style.display = "none";
          })
          .exportPublic(params);
        }
      </script>
    </div>
  </body>
</html>
```

### css-exportPublicForm.html

```
<!DOCTYPE html>
<style>
  #toast-container {
    top: 0 !important;
    right: 0 !important;
  }
  
  .error {
    background-color: #F44336;
  }
  
  .green {
    background-color: #26a69a;
  }
  
  .form-title {
    margin-top: 15px;
    margin-bottom: 15px;
  }

  input {
    font-size: 14px !important;
  }
  
  #runningContainer {
    display: none;
    position: sticky;
    top: 10px;
    float: right;
    margin-right: 15px;
    align-items: center;
  }
  
  .spin {
    animation-name: spin;
    animation-duration: 2s;
    animation-iteration-count: infinite;
    animation-timing-function: linear;
    transform: rotate(360deg);
  }

  @keyframes spin {
    from {
      transform: rotate(360deg); 
    }
    to {
      transform: rotate(0deg); 
    } 
  }
</style>
```
