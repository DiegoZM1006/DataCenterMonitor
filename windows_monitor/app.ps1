# app.ps1

function Get-ProcessTable {
    # Genera una tabla HTML con los procesos activos
    $processes = Get-Process | Select-Object Id, ProcessName, CPU, WorkingSet
    $html = "<table><tr><th>PID</th><th>Nombre</th><th>CPU</th><th>Memoria</th><th>Accion</th></tr>"

    foreach ($process in $processes) {
        $html += "<tr><td>$($process.Id)</td><td>$($process.ProcessName)</td><td>$($process.CPU)</td><td>$([math]::round($process.WorkingSet / 1KB, 2))</td>"
        $html += "<td><button class='terminate-btn' onclick='terminateProcess($($process.Id))'>Terminar</button></td></tr>"
    }

    $html += "</table>"
    return $html
}

function Terminate-ProcessById {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ProcessId
    )

    try {
        $process = Get-Process -Id $ProcessId -ErrorAction Stop
        
        # Verificación adicional de seguridad
        if ($process.ProcessName -in @("System", "Idle", "svchost", "lsass")) {
            throw "No se permite terminar procesos críticos del sistema"
        }

        Stop-Process -Id $ProcessId -Force -ErrorAction Stop
        Write-Output "Proceso $ProcessId terminado exitosamente"
        return $true
    }
    catch {
        Write-Error "Error al terminar el proceso $ProcessId : $_"
        throw
    }
}

# Export-ModuleMember -Function Get-ProcessTable, Terminate-ProcessById
