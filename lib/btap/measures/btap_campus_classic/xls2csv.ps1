

    Function ExportWSToCSV ($excelFile, $csvLoc)
{
    $excelFile = "$PSScriptRoot\" + $excelFile
    $E = New-Object -ComObject Excel.Application
    $E.Visible = $false
    $E.DisplayAlerts = $false
    $wb = $E.Workbooks.Open($excelFile)
    foreach ($ws in $wb.Worksheets)
    {
        $n = $ws.Name
        $ws.SaveAs($csvLoc +$n + ".csv", 6)
    }
    $E.Quit()
    stop-process -processname EXCEL
}
ExportWSToCSV -excelFile ".\campus_modelling_assumptions.xlsx" -csvLoc "$PSScriptRoot\"
