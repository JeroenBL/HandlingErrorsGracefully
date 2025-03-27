## Download and run API

## Walkthrough swagger interface

## Errorhandling

### Difference Between PowerShell and Windows PowerShell

### ErrorDetails

When you receive an error or exception from an API, you can usually find it in `$_ .ErrorDetails.Message`. This object typically contains a JSON string with the error details. However, in **Windows PowerShell**, there's a bug that often causes this to be empty.

#### Workaround: `GetResponseStream`

### Different .NET Message

### Different Type of Error

- In **Windows PowerShell**: `System.Net.WebException`
- In **PowerShell (Core / 7+)**: `Microsoft.PowerShell.Commands.HttpResponseException`

### Walkthrough PowerShell calls