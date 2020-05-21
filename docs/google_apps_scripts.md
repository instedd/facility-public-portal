# Google Spreadsheet Curation

Probably, before uploading data to LabMap you would like to perform a content curation process on the Spreadsheet containing the information. Also, you may want to move that curated content to a different Spreadsheet to make it public so you are able to submit the link.
For those cases and similar ones, `Google Apps Scripts` is a great tool that can help you with automation. Here we include two examples of scripts that achieved the aforementioned tasks.

## Data curation

```
ss = SpreadsheetApp.getActiveSpreadsheet();
var sheet = ss.getActiveSheet();
var columnsFilterSheet = ss.getSheetByName('columnsFilter');

var headers = sheet.getDataRange().getValues()[0]
var columnsFilter = columnsFilterSheet.getDataRange().getValues().map(row => row[0]);

for ( i = headers.length; i > 0; i-- ) {
  if (columnsFilter.includes(headers[i-1])) {
    sheet.deleteColumn(i);
  }
}

function cleanSheet() {
  var rangeData = sheet.getDataRange();
  var lastColumn = rangeData.getLastColumn();
  var lastRow = rangeData.getLastRow();
  var searchRange = sheet.getRange(1,1, lastRow, lastColumn);
  var rangeValues = searchRange.getValues();
  
  var replacementsSheet = ss.getSheetByName('replacementDictionary');
  var replacements = {};
  var replacementsArray = replacementsSheet.getRange(1,1, lastRow-1, 2).getValues();
  
  replacementsArray.forEach((row) => {
    if (!!row[0] && !!row[1]) {
      replacements[row[0].toString()] = row[1].toString();
    }
  });

  var sRegExp = new RegExp(/section[0-9]+\//g);
  var tRegExp = new RegExp(/\....\+../g);
    for ( i = 0; i < lastColumn-1; i++){
      for ( j = 0 ; j < lastRow-1; j++){
        var str = ""+rangeValues[j][i];
        // Clean all the "section*/" prefixes        
        if (str.match(sRegExp)) {
          var newStr = str.toString().replace(/(section[0-9]+(\.[0-9]+)*\/)+/,"");
          sheet.getRange(j+1,i+1).setValue(newStr);
        }
        // Replace TRUE for yes and FALSE for no
        if (str=="true") {
          newStr = str.toString().replace("true","yes");
          sheet.getRange(j+1,i+1).setValue(newStr);
        } else if (str=="false") {
          newStr = str.toString().replace("false","no");
          sheet.getRange(j+1,i+1).setValue(newStr);
        }
        // Clean miliseconds and timezone from date time cells
        if (str.match(tRegExp)) {
          var newStr = str.toString().replace(/\....\+../g,"");
          sheet.getRange(j+1,i+1).setValue(newStr);
        }
        // Replace fields based on replacement sheet
        Object.keys(replacements).forEach((word) => {
          if (str.includes(word)) {
            let newStr = str.toString().replace(word, replacements[word]);
            sheet.getRange(j+1,i+1).setValue(newStr);
          }
        });
      }
   }
}
```

## Creating and Copying into Public File

```
// Activate Resources -> Drive Api V2 before running the script

var ss = SpreadsheetApp.getActiveSpreadsheet();
var sheet = ss.getActiveSheet();
var dataRange = sheet.getDataRange();
var values = dataRange.getValues();

// rowsLength and columnsLength determine the range to be exported
// Currently, they are set to export the whole sheet
var rowsLength = dataRange.getLastRow();
var columnsLength = dataRange.getLastColumn();

// ADD destination folder and filename
var destFolderName = '';
var destFileName = '';

function exportPublic() {
  var folderId = DriveApp.getFoldersByName(destFolderName).next().getId();
  var file = Drive.Files.insert({mimeType: MimeType.GOOGLE_SHEETS, title: destFileName, parents: [{id: folderId}]});
  DriveApp.getFileById(file.id).setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  ssNew = SpreadsheetApp.openById(file.id)
  var ssNewSheet = ssNew.getActiveSheet();
  var range = ssNewSheet.getRange(1,1, rowsLength, columnsLength);
  range.setValues(values);
}
```
