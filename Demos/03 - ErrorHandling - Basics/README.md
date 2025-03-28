When you receive an error or exception from an API, you can usually find it in `$_ .ErrorDetails.Message`. This object typically contains a JSON string with the error details. However, in **Windows PowerShell**, there's a bug that often causes this object to be empty.

### Workaround: `GetResponseStream`

```powershell
$([System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream()).ReadToEnd())"
```

### Different type of exception

- In **Windows PowerShell**: `System.Net.WebException`
- In **PowerShell (Core / 7+)**: `Microsoft.PowerShell.Commands.HttpResponseException`