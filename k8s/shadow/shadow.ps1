# Shadow Deployment Traffic Mirroring Script
# This script simulates traffic mirroring to shadow deployment

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('start','stop','status','test')]
    [string]$Action = 'status',
    
    [Parameter(Mandatory=$false)]
    [int]$Requests = 10
)

$NAMESPACE = "aceest-fitness"
$PROD_SERVICE = "aceest-fitness-shadow-prod"
$SHADOW_SERVICE = "aceest-fitness-shadow-internal"

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Shadow Deployment Manager" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

# Function to get service endpoints
function Get-ServiceEndpoint {
    param([string]$ServiceName)
    
    $clusterIP = kubectl get service $ServiceName -n $NAMESPACE -o jsonpath='{.spec.clusterIP}' 2>$null
    $port = kubectl get service $ServiceName -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}' 2>$null
    
    if ($clusterIP -and $port) {
        return "http://${clusterIP}:${port}"
    }
    return $null
}

# Function to test traffic mirroring
function Test-TrafficMirroring {
    param([int]$NumRequests)
    
    Write-Host "Testing traffic mirroring with $NumRequests requests..." -ForegroundColor Cyan
    Write-Host ""
    
    $prodEndpoint = Get-ServiceEndpoint -ServiceName $PROD_SERVICE
    $shadowEndpoint = Get-ServiceEndpoint -ServiceName $SHADOW_SERVICE
    
    if (-not $prodEndpoint) {
        Write-Host "Error: Production service not found" -ForegroundColor Red
        return
    }
    
    if (-not $shadowEndpoint) {
        Write-Host "Error: Shadow service not found" -ForegroundColor Red
        return
    }
    
    Write-Host "Production endpoint: $prodEndpoint" -ForegroundColor Green
    Write-Host "Shadow endpoint: $shadowEndpoint" -ForegroundColor Yellow
    Write-Host ""
    
    # Get a pod to run curl from
    $podName = kubectl get pods -n $NAMESPACE -l version=production -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if (-not $podName) {
        Write-Host "Error: No production pods found" -ForegroundColor Red
        return
    }
    
    Write-Host "Sending requests from pod: $podName" -ForegroundColor Cyan
    Write-Host ""
    
    $successProd = 0
    $successShadow = 0
    $failProd = 0
    $failShadow = 0
    
    for ($i = 1; $i -le $NumRequests; $i++) {
        Write-Host "Request $i of $NumRequests" -ForegroundColor Gray
        
        # Send to production (user-facing)
        $prodCmd = "python3 -c `"import urllib.request; r = urllib.request.urlopen('$prodEndpoint/health'); print(r.status)`""
        $prodResult = kubectl exec $podName -n $NAMESPACE -- sh -c $prodCmd 2>$null
        if ($prodResult -eq "200") {
            $successProd++
            Write-Host "  [PROD] Response: $prodResult - OK" -ForegroundColor Green
        } else {
            $failProd++
            Write-Host "  [PROD] Response: $prodResult - FAIL" -ForegroundColor Red
        }
        
        # Mirror to shadow (no user impact)
        $shadowCmd = "python3 -c `"import urllib.request; r = urllib.request.urlopen('$shadowEndpoint/health'); print(r.status)`""
        $shadowResult = kubectl exec $podName -n $NAMESPACE -- sh -c $shadowCmd 2>$null
        if ($shadowResult -eq "200") {
            $successShadow++
            Write-Host "  [SHADOW] Response: $shadowResult - OK (mirrored)" -ForegroundColor Yellow
        } else {
            $failShadow++
            Write-Host "  [SHADOW] Response: $shadowResult - FAIL (mirrored)" -ForegroundColor Red
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Traffic Mirroring Results" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Production:" -ForegroundColor Green
    Write-Host "  Success: $successProd / $NumRequests" -ForegroundColor Green
    Write-Host "  Failed: $failProd / $NumRequests" -ForegroundColor Red
    Write-Host ""
    Write-Host "Shadow (Mirrored):" -ForegroundColor Yellow
    Write-Host "  Success: $successShadow / $NumRequests" -ForegroundColor Yellow
    Write-Host "  Failed: $failShadow / $NumRequests" -ForegroundColor Red
    Write-Host ""
    
    if ($failShadow -gt 0) {
        Write-Host "WARNING: Shadow deployment has failures!" -ForegroundColor Red
        Write-Host "Do NOT promote shadow to production." -ForegroundColor Red
    } else {
        Write-Host "SUCCESS: Shadow deployment is stable!" -ForegroundColor Green
        Write-Host "Safe to promote to production." -ForegroundColor Green
    }
}

# Function to show status
function Show-Status {
    Write-Host "Current Status:" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Production Deployment:" -ForegroundColor Green
    kubectl get deployment aceest-fitness-production -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  Not deployed" }
    Write-Host ""
    
    Write-Host "Shadow Deployment:" -ForegroundColor Yellow
    kubectl get deployment aceest-fitness-shadow -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  Not deployed" }
    Write-Host ""
    
    Write-Host "Services:" -ForegroundColor Cyan
    kubectl get service -n $NAMESPACE -l app=aceest-fitness 2>$null | Select-String "shadow"
    Write-Host ""
    
    Write-Host "Pods:" -ForegroundColor Cyan
    kubectl get pods -n $NAMESPACE -l app=aceest-fitness --show-labels 2>$null | Select-String "production|shadow"
}

# Function to compare logs
function Compare-Logs {
    Write-Host "Comparing logs between Production and Shadow..." -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Production Logs (last 10 lines):" -ForegroundColor Green
    kubectl logs -n $NAMESPACE -l version=production --tail=10 2>$null
    Write-Host ""
    
    Write-Host "Shadow Logs (last 10 lines):" -ForegroundColor Yellow
    kubectl logs -n $NAMESPACE -l version=shadow --tail=10 2>$null
}

# Main logic
switch ($Action) {
    'start' {
        Write-Host "Starting shadow deployment..." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Note: In production, you would configure a service mesh (Istio/Linkerd)" -ForegroundColor Gray
        Write-Host "or ingress controller to automatically mirror traffic." -ForegroundColor Gray
        Write-Host ""
        Write-Host "For this demo, we'll manually send mirrored requests." -ForegroundColor Gray
        Write-Host ""
        Show-Status
    }
    'stop' {
        Write-Host "Stopping shadow deployment..." -ForegroundColor Cyan
        kubectl delete deployment aceest-fitness-shadow -n $NAMESPACE 2>$null
        Write-Host ""
        Show-Status
    }
    'test' {
        Test-TrafficMirroring -NumRequests $Requests
    }
    'status' {
        Show-Status
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Cyan
        Write-Host "  .\shadow.ps1 test -Requests 20  # Test with 20 mirrored requests" -ForegroundColor Gray
        Write-Host "  .\shadow.ps1 status             # Show deployment status" -ForegroundColor Gray
    }
}
