### Merge.gs

```
function onOpen() {
  const ui = SpreadsheetApp.getUi();
  const menu = ui.createMenu('Labmap');
  menu.addItem('Merge Sheets', 'showMergeForm');
  menu.addToUi();
}

function showMergeForm() {
  const template = HtmlService.createTemplateFromFile("mergeForm");
  const html = template.evaluate();
  SpreadsheetApp.getUi().showSidebar(html);
}

function mergeSheets(params) {
  const ss = SpreadsheetApp.getActiveSpreadsheet()
  const destinationFolderParam = params.destinationFolder
  const destinationFileParam = params.destinationFile
  const sheetsToMergeParams = params.sheetsToMerge
  const sheetsToMerge = sheetsToMergeParams.map(sheetName => ss.getSheetByName(sheetName))
  const columnFromParam = params.columnFrom
  const columnToParam = params.columnTo
    
  const columnStart = letterToColumn(columnFromParam)
  const columnEnd = letterToColumn(columnToParam)
  
  if (columnStart > columnEnd) {
    return {success: false, message: `Invalid range. End column has to be greater or equal than Start column`}
  }
  
  let mergeResult = []
  const headers = sheetsToMerge[0].getDataRange().getValues()[0]
  mergeResult.push(headers.slice(columnStart - 1, columnEnd))
  
  sheetsToMerge.forEach(sheet => {
    var lastRow = sheet.getDataRange().getLastRow(); 
    var data = sheet.getRange(2, columnStart, lastRow - 1, columnEnd - columnStart + 1).getValues();
    mergeResult = [...mergeResult, ...data ];
  })
  
  let folder = DriveApp.getFoldersByName(destinationFolderParam)
  if (folder.hasNext()) {
    folder = folder.next()
  } else {
    folder = DriveApp.createFolder(destinationFolderParam);
  }
  const folderId = folder.getId();
  const file = Drive.Files.insert({mimeType: MimeType.GOOGLE_SHEETS, title: destinationFileParam, parents: [{id: folderId}]});
  ssNew = SpreadsheetApp.openById(file.id)
  const ssNewSheet = ssNew.getActiveSheet();
  const range = ssNewSheet.getRange(1,1, mergeResult.length, columnEnd - columnStart + 1);
  range.setValues(mergeResult)
  
  return {success: true, message: 'Sheets succesfully merged'}
}

// From: https://stackoverflow.com/a/21231012/5745962
function letterToColumn(letter) {
  letter = letter.toUpperCase()
  let column = 0, length = letter.length;
  for (let i = 0; i < length; i++)
  {
    column += (letter.charCodeAt(i) - 64) * Math.pow(26, length - i - 1);
  }
  return column;
}

function getSheetsName() {
  return SpreadsheetApp.getActiveSpreadsheet().getSheets().map(s => s.getName())
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}
```

### mergeForm.html

```
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <?!= include("css-mergeForm"); ?>
  </head>
  <body>
    <div class="container">
      <div id="runningContainer">
        <div id="running">Running...</div>
        <i class="material-icons spin">sync</i>
      </div>
      <h6 class="form-title">Merge Sheets</h6>
      <div class="row" id="mainRow">
        <form class="col s12" onkeydown="preventSubmitOnEnter(event)">
          <h8 id="optionsTitle">To be merged:</h8>
          <div class="row">
            <div class="input-field col s12" id="sheet-options">
            </div>
          </div>
          <div class="row">
            <div class="input-field col s6">
              <input placeholder="Column From" id="columnFrom" type="text" value="">
              <label for="columnFrom">Start Column (incl)</label>
              <span class="helper-text" id="helperColumnFrom" data-error="Missing Starting column">Letter notation: A, AA</span>
            </div>
            <div class="input-field col s6">
              <input placeholder="Column To" id="columnTo" type="text">
              <label for="columnTo">End Column (incl)</label>
              <span class="helper-text" id="helperColumnTo" data-error="Missing End column">Letter notation: A, AA</span>
            </div>
          </div>
          <div class="row">
            <div class="input-field col s12">
              <input placeholder="Destination Folder" id="destinationFolder" type="text" value="">
              <label for="destinationFolder">Destination Folder</label>
              <span class="helper-text" data-error="Missing Destination Folder">If destination folder doesn't exist, it creates one</span>
            </div>
          </div>
          <div class="row">
            <div class="input-field col s12">
              <input placeholder="Destination File" id="destinationFile" type="text" value="">
              <label for="destinationFile">Destination File</label>
              <span class="helper-text" data-error="Missing Destination File">Destination File Name</span>
            </div>
          </div>
          <div class="row">
            <button id="btn-merge" class="waves-effect waves-light btn-small disabled">
              Merge
              <i class="material-icons right">send</i>
            </button>
          </div>
        </form>
      </div>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
      <script>
        document.getElementById('btn-merge').addEventListener('click', (event) => submit(event))

        function preventSubmitOnEnter(e) {
          if (e.key === "Enter") {
            e.preventDefault()
          }
        }
        
        var inputFields = ['columnFrom', 'columnTo', 'destinationFolder', 'destinationFile'];
        inputFields.forEach((input) => {
          var element = document.getElementById(input) 
          element.addEventListener("keyup", (event) => onInputKeyUp(event, input))
        })
        
        function onInputKeyUp(event, input) {
          var element = document.getElementById(input)
          var button = document.getElementById('btn-merge')
          const lettersRegex = /^[a-zA-Z]*$/g
          
          if (input === 'columnFrom') {
            if (element.value.length === 0) {
              element.classList.add('invalid')
              document.getElementById('helperColumnFrom').setAttribute('data-error', 'Missing Starting column')
            } else if (!element.value.match(lettersRegex)) {
              element.classList.add('invalid')
              document.getElementById('helperColumnFrom').setAttribute('data-error', 'Only Letters allowed')
            } else {
              element.classList.remove('invalid')
            }
          }
          
          if (input === 'columnTo') {
            if (element.value.length === 0) {
              element.classList.add('invalid')
              document.getElementById('helperColumnTo').setAttribute('data-error', 'Missing End column')
            } else if (!element.value.match(lettersRegex)) {
              element.classList.add('invalid')
              document.getElementById('helperColumnTo').setAttribute('data-error', 'Only Letters allowed')
            } else {
              element.classList.remove('invalid')
            }
          }
          
          if (['destinationFolder', 'destinationFile'].includes(input)) {
            if (element.value.length === 0) {
              element.classList.add('invalid')
            } else {
              element.classList.remove('invalid')
            }
          }
          
          if (inputFields.map((input) => document.getElementById(input)).every((element) => (element.className.split(" ").indexOf("invalid") === -1))) {
            button.classList.remove('disabled')
          } else {
            button.classList.add('disabled')
          }
        }
        
        google.script.run
        .withSuccessHandler((sheetNames) => {
          const optionsContainer = document.getElementById("sheet-options")
          const options = sheetNames.forEach(sheetName => {
            const p = document.createElement("p")
            const label = document.createElement("label")
            const input = document.createElement("input")
            input.setAttribute("type", "checkbox")
            input.setAttribute("checked", "checked")
            input.setAttribute("name", "options")
            input.setAttribute("value", sheetName)
            input.className = "filled-in"
            const span = document.createElement("span")
            span.appendChild(document.createTextNode(sheetName));
            
            label.appendChild(input)
            label.appendChild(span)
            p.appendChild(label)
            optionsContainer.appendChild(p)
          })
        })
        .getSheetsName();
        
        function submit(event) {
          event.preventDefault();
          var button = document.getElementById('btn-merge');
          var runningContainer = document.getElementById('runningContainer');
          const DISPLAY_LENGTH_START = 3000;
          const DISPLAY_LENGTH_RESULT = 5000;
          var columnFrom = document.getElementById('columnFrom').value;
          var columnTo = document.getElementById('columnTo').value;
          var destinationFolder = document.getElementById('destinationFolder').value;
          var destinationFile = document.getElementById('destinationFile').value;
          
          var sheetsToMerge = []
          document.getElementsByName('options').forEach(op => {
            if (op.checked) {
              sheetsToMerge.push(op.value)
            }
          })
          
          var params = {
            columnFrom: columnFrom,
            columnTo: columnTo,
            destinationFolder: destinationFolder,
            destinationFile: destinationFile,
            sheetsToMerge: sheetsToMerge
          }
          
          button.classList.add('disabled');
          runningContainer.style.display = "flex";
          M.toast({html: 'Script started', displayLength: DISPLAY_LENGTH_START});
         
          google.script.run
          .withFailureHandler((error) => { 
            M.toast({html: `Error while running the script: ${error}`, classes: 'error', displayLength: DISPLAY_LENGTH_RESULT})
            button.classList.remove('disabled')
            runningContainer.style.display = "none"
          })
          .withSuccessHandler((result) => {
            button.classList.remove('disabled')
            runningContainer.style.display = "none"          
            if(result.success) {
              M.toast({html: result.message, classes: 'green', displayLength: DISPLAY_LENGTH_RESULT})
            } else {
              M.toast({html: result.message, classes: 'error', displayLength: DISPLAY_LENGTH_RESULT})
            }  
          })
          .mergeSheets(params);
       }
      </script>
    </div>
  </body>
</html>
```

### css-mergeForm.html

```
<!DOCTYPE html>
<style>
  .form-title {
    margin-top: 15px;
    margin-bottom: 15px;
  }
  
  #mainRow {
    margin-top: 20px;
  }
  
  #sheet-options {
    margin-top: 7px;
    margin-bottom: 7px;
  }
  
  input {
    font-size: 14px !important;
  }
  
  #toast-container {
    top: 0 !important;
    right: 0 !important;
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
    
  .error {
    background-color: #F44336;
  }
  
  .green {
    background-color: #26a69a;
  }
</style>
```
