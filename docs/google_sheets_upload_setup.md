# Upload files using Google Sheets Links

## Overview

Sometimes users won't upload files in the usual way (dropping CSV files on the boxes area), but by providing a Google Sheet link.
At server side, link is validated and its content fetched using `Google::Apis::SheetsV4::SheetsService`.
Finally, content of the sheet is written into a CSV file, which is stored same way as the other files (same directory and naming convention).
Therefore, uploading a file through a Google Sheet link yields the same result as downloading the contents of the sheet as CSV and uploading that file in the usual way.

At the moment, this functionality is only available for `data.csv` file. However, it can be easily enabled for any of the remaining files.

## Setup

Users only uploads links that belongs to public Google Sheets. Though [Google Sheets API v4](https://developers.google.com/sheets/api/guides/authorizing) doesn't require an `OAuth 2.0 token` to authorize the requests, it does demands an `API_KEY` as a means of authentication. Therefore, in the next subsection we'll review how to create a `GOOGLE_SHEET_API_KEY` in a Project.

### Obtaining a Google Sheet API KEY

1. Create a Google Project or get into an existing one
2. Navigate to `Credentials`
3. Create a new `API_KEY` or select an existing one

At this point we still have to enable our `API_KEY` obtained in step (3) to use `Google Sheets API v4`. Otherwise, if you attempt a request using the `API_KEY` to authenticate yourself (e.g try to read the content of a public spreadsheet), you'll obtain the following error:

```
{
  "error": {
    "code": 403,
    "message": "Google Sheets API has not been used in project {project-id} before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/sheets.googleapis.com/overview?project=project-id then retry"
    "status": "PERMISSION_DENIED",
    "details": [
      ...
    ]
  }
}
```

4. Navigate to https://console.developers.google.com/apis/api/sheets.googleapis.com/overview?project=#{project-id}, as pointed out by the error message. Don't forget to replace _project-id_ with the actual _id_ of the project.
5. Enable `Google Sheets API v4` in your project
6. Wait a few minutes until changes take effect

At this point your `API_KEY` will be ready to authenticate `Google Sheets API v4` requests.

### Setting `GOOGLE_SHEET_API_KEY`

For `DEVELOPMENT`, add `GOOGLE_SHEET_API_KEY` in `dev.env`.
For `PRODUCTION`, add `GOOGLE_SHEET_API_KEY` along with the other environment variables.
`GOOGLE_SHEET_API_KEY` is used by `SpreadsheetService` class to authenticate `Google Sheets API v4` requests.
 