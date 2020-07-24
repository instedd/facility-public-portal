### DataCuration.gs

```
function onOpen() {
  const ui = SpreadsheetApp.getUi();
  const menu = ui.createMenu('Labmap');
  menu.addItem('Data Curation', 'showDataCurationForm');
  menu.addItem('Export', 'showExportPublicForm');
  menu.addToUi();
}

function showDataCurationForm() {
  const template = HtmlService.createTemplateFromFile("dataCurationForm");
  SpreadsheetApp.getUi().showSidebar(template.evaluate());
}

function cleanSheet(params) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  
  const columnsFilterParam = params.columnsFilter
  const replacementDictionaryParam = params.replacementDictionary
  const dataSheetParam = params.dataSheet
  const columnsFilterSheet = ss.getSheetByName(columnsFilterParam);
  const replacementsSheet = ss.getSheetByName(replacementDictionaryParam);
  const sheet = ss.getSheetByName(dataSheetParam);
  
  if (!sheet) {
    return {success: false, message: `There is no sheet with name '${dataSheetParam}'`}
  }
  
  if (!columnsFilterSheet) {
    return {success: false, message: `There is no sheet with name '${columnsFilterParam}'`}
  }
    
  if (!replacementsSheet) {
    return {success: false, message: `There is no sheet with name '${replacementDictionaryParam}'`}
  }
    
  const columnsFilter = columnsFilterSheet.getDataRange().getValues().map(row => row[0]);
  filterColumns(sheet, columnsFilter);

  const rangeData = sheet.getDataRange();
  const lastColumn = rangeData.getLastColumn();
  const lastRow = rangeData.getLastRow();
  const rangeValues = rangeData.getValues();
  
  const replacements = {};
  const replacementsArray = replacementsSheet.getDataRange().getValues();
  
  replacementsArray.forEach((row) => {
    if (!!row[0] && !!row[1]) {
      replacements[row[0].toString()] = row[1].toString();
    }
  });
  
  const sRegExp = new RegExp(/section[0-9]+\//g);
  const tRegExp = new RegExp(/\....[\+\-]../g);
  for (var i = 0; i < lastColumn; i++){
    for (var j = 0; j < lastRow; j++){
      var prevString = ""+rangeValues[j][i];
      var newString = prevString;
      // Clean all the "section*/" prefixes        
      if (prevString.match(sRegExp)) {
        newString = prevString.toString().replace(/(section[0-9]+(\.[0-9]+)*\/)+/,"");
      }
      // Replace TRUE for yes and FALSE for no
      if (prevString =="true") {
        newString = prevString.toString().replace("true","yes");
      } else if (prevString =="false") {
        newString = prevString.toString().replace("false","no");
      }
      // Clean miliseconds and timezone from date time cells
      if (prevString.match(tRegExp)) {
        newString = prevString.toString().replace(tRegExp,"");
      }
      // Compute str according to replacementDict
      Object.keys(replacements).forEach((replacement) => {
        // Matching by 'substring' may lead to problems if Spreadsheet is too big
        // if (newString.includes(word)) {
        if (newString === replacement) {
          newString = newString.toString().replace(replacement, replacements[replacement]);
        }
      });
    
      if (prevString !== newString) {
        // Update value if any word was replaced using the replacementDict
        rangeValues[j][i] = newString;
      }
    }
  }
  
  rangeData.setValues(rangeValues);
  
  // check script correctness
  const success = checkCorrectness(sheet, columnsFilter, replacements, sRegExp, tRegExp)
  if (!success) {
    return {success: false, message: 'Some errors occurred and were displayed'}
  } else {
    return {success: true, message: 'Data Curation performed successfully'}
  }
}

function filterColumns(sheet, columnsToFilter) {
  const headers = sheet.getDataRange().getValues()[0];
  
  for ( var i = headers.length; i > 0; i-- ) {
    if (columnsToFilter.includes(headers[i-1])) {
      sheet.deleteColumn(i);
    }
  }
}

function checkCorrectness(sheet, columnsFilter, replacements, sRegExp, tRegExp) {
  const rangeData = sheet.getDataRange();
  const lastColumn = rangeData.getLastColumn();
  const lastRow = rangeData.getLastRow();
  const rangeValues = rangeData.getValues();
  const headers = rangeValues[0];
  
  const errors = []
  headers.forEach(h => {
    if(columnsFilter.includes(h)) {
      errors.push(`Header ${h} not filtered`)  
    }
  })
  
  for (i = 0; i < lastColumn; i++){
    for (j = 0 ; j < lastRow; j++){
      const value = ""+rangeValues[j][i];
      if (value.match(sRegExp)) {
        errors.push(`Cell in row ${j+1}, column ${i+1}: ${value} still contains word 'section'.`)
      }
      if (value =="true") {
        errors.push(`Cell in row ${j+1}, column ${i+1}: ${value} still equals 'true'.`)
      }
      if (value =="false") {
        errors.push(`Cell in row ${j+1}, column ${i+1}: ${value} still equals 'false'.`)
      }
      if (value.match(tRegExp)) {
        errors.push(`Cell in row ${j+1}, column ${i+1}: ${value} still contains miliseconds and timezone.`)
      }
      Object.keys(replacements).forEach((replacement) => {
        // Matching by 'substring' may lead to problems if Spreadsheet is too big
        // if (value.includes(word) && !value.includes(replacements[word])) {
        if (value === replacement) {
          errors.push(`${replacement} not replaced with ${replacements[replacement]} in row ${j+1}, column ${i+1}: ${value}.`)
        }
      })
    }
  }
  
  if (errors.length !== 0) {
    Browser.msgBox(errors.join('\n'))
    return false
  } else {
    return true
  }
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}
```

### dataCurationForm.html
```
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <?!= include("css-dataCurationForm"); ?>
  </head>
  <body>
    <div class="container">
      <div id="runningContainer">
        <div id="running">Running...</div>
        <i class="material-icons spin">sync</i>
      </div>
      <h6 class="form-title">Data Curation</h6>
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
              <input placeholder="columnsFilter" id="columnsFilter" type="text" value="columnsFilter">
              <label for="columnsFilter">Columns Filters Sheet</label>
              <span class="helper-text" data-error="Missing 'Columns Filter' sheet">Sheet containing the list of columns to be filtered</span>
            </div>
          </div>
          <div class="row">
            <div class="input-field col s12">
              <input placeholder="replacementDictionary" id="replacementDictionary" type="text" value="replacementDictionary">
              <label for="replacementDictionary">Replacement Dictionary Sheet'</label>
              <span class="helper-text" data-error="Missing 'Replacement Dictionary' sheet">Sheet containing the Replacement Dictionary</span>
            </div>
          </div>
          <div class="row">
            <button id="btn-data-curation" class="waves-effect waves-light btn-small">
              Curate Data
              <i class="material-icons right">send</i>
            </button>
          </div>
        </form>
      </div>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
      <script>
        document.getElementById('btn-data-curation').addEventListener('click', (event) => submit(event))
        
        function preventSubmitOnEnter(e) {
          if (e.key === "Enter") {
            e.preventDefault()
          }
        }
        
        var inputFields = ['dataSheet', 'columnsFilter', 'replacementDictionary'];
        inputFields.forEach((input) => {
          var element = document.getElementById(input) 
          element.addEventListener("keyup", (event) => onInputKeyUp(event, input))
        })
        
        function onInputKeyUp(event, input) {
          var element = document.getElementById(input)
          var button = document.getElementById('btn-data-curation')
          
          if (element.value.length === 0) {
            element.classList.add('invalid')
          } else {
            element.classList.remove('invalid')
          }
          
          if (inputFields.map((input) => document.getElementById(input)).every((element) => (element.value.length > 0))) {
            button.classList.remove('disabled')
          } else {
            button.classList.add('disabled')
          }
        }
        
        function submit(event) {
          event.preventDefault();
          var button = document.getElementById('btn-data-curation');
          var runningContainer = document.getElementById('runningContainer');
          const DISPLAY_LENGTH_START = 3000;
          const DISPLAY_LENGTH_RESULT = 5000;
          var dataSheet = document.getElementById('dataSheet').value;
          var columnsFilter = document.getElementById('columnsFilter').value;
          var replacementDictionary = document.getElementById('replacementDictionary').value;
          
          var params = {
            dataSheet: dataSheet,
            columnsFilter: columnsFilter,
            replacementDictionary: replacementDictionary
          }
          
          button.classList.add('disabled');
          runningContainer.style.display = "flex";
          M.toast({html: 'Script started', displayLength: DISPLAY_LENGTH_START});
         
          google.script.run
          .withFailureHandler(() => { 
            M.toast({html: 'Error while running the script', classes: 'error', displayLength: DISPLAY_LENGTH_RESULT})
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
          .cleanSheet(params);
        }
      </script>
    </div>
  </body>
</html>
```

### css-dataCurationForm.html

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
