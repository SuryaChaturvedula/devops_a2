# Rolling Update Deployment Script for ACEest Fitness
# Demonstrates Kubernetes native rolling update mechanism

# Configuration
$NAMESPACE = "aceest-fitness"
$DEPLOYMENT = "aceest-fitness-rolling"

function Show-Help {
    Write-Host "`n=== Rolling Update Management ===" -ForegroundColor Cyan
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "  .\rolling-update.ps1 status               - Show current deployment status"
    Write-Host "  .\rolling-update.ps1 update <image>       - Update to new image version"
    Write-Host "  .\rolling-update.ps1 rollback             - Rollback to previous version"
    Write-Host "  .\rolling-update.ps1 pause                - Pause ongoing rollout"
    Write-Host "  .\rolling-update.ps1 resume               - Resume paused rollout"
    Write-Host "  .\rolling-update.ps1 history              - Show rollout history"
    Write-Host "  .\rolling-update.ps1 restart              - Restart all pods (rolling)"
    Write-Host "`nExamples:" -ForegroundColor Yellow
    Write-Host "  .\rolling-update.ps1 update suryachaturvedula/aceest-fitness:v2.0"
    Write-Host "  .\rolling-update.ps1 update suryachaturvedula/aceest-fitness:latest"
    Write-Host ""
}

function Get-RollingStatus {
    Write-Host "`n=== Rolling Update Status ===" -ForegroundColor Cyan
    
    # Get deployment details
    Write-Host "`nDeployment Details:" -ForegroundColor Yellow
    kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o wide
    
    # Get rollout status
    Write-Host "`nRollout Status:" -ForegroundColor Yellow
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5s
    
    # Get replica sets (shows old and new versions during rollout)
    Write-Host "`nReplicaSets:" -ForegroundColor Yellow
    kubectl get rs -n $NAMESPACE -l app=aceest-fitness,deployment=rolling
    
    # Get pods
    Write-Host "`nPods:" -ForegroundColor Yellow
    kubectl get pods -n $NAMESPACE -l app=aceest-fitness,deployment=rolling -o wide
    
    # Get current image
    Write-Host "`nCurrent Image:" -ForegroundColor Yellow
    kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}'
    Write-Host ""
    
    # Get rolling update configuration
    Write-Host "`nRolling Update Configuration:" -ForegroundColor Yellow
    Write-Host "  Max Unavailable: $(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}')"
    Write-Host "  Max Surge: $(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}')"
    Write-Host "  Replicas: $(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}')"
}

function Update-Image {
    param([string]$NewImage)
    
    if (-not $NewImage) {
        Write-Host "Error: Image name required" -ForegroundColor Red
        Write-Host "Usage: .\rolling-update.ps1 update <image>" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n=== Starting Rolling Update ===" -ForegroundColor Cyan
    Write-Host "New Image: $NewImage" -ForegroundColor Yellow
    
    # Get current image
    $currentImage = kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}'
    Write-Host "Current Image: $currentImage" -ForegroundColor Yellow
    
    # Update the image
    Write-Host "`nUpdating deployment..." -ForegroundColor Yellow
    kubectl set image deployment/$DEPLOYMENT -n $NAMESPACE aceest-fitness=$NewImage --record
    
    # Watch the rollout
    Write-Host "`nWatching rollout progress..." -ForegroundColor Yellow
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE
    
    Write-Host "`nRolling update completed!" -ForegroundColor Green
    Get-RollingStatus
}

function Rollback-Deployment {
    Write-Host "`n=== Rolling Back Deployment ===" -ForegroundColor Cyan
    
    # Show current status
    Write-Host "Current status:" -ForegroundColor Yellow
    kubectl get deployment $DEPLOYMENT -n $NAMESPACE
    
    # Perform rollback
    Write-Host "`nPerforming rollback to previous version..." -ForegroundColor Yellow
    kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE
    
    # Watch the rollback
    Write-Host "`nWatching rollback progress..." -ForegroundColor Yellow
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE
    
    Write-Host "`nRollback completed!" -ForegroundColor Green
    Get-RollingStatus
}

function Pause-Rollout {
    Write-Host "`n=== Pausing Rollout ===" -ForegroundColor Cyan
    kubectl rollout pause deployment/$DEPLOYMENT -n $NAMESPACE
    Write-Host "Rollout paused. Use 'resume' to continue." -ForegroundColor Yellow
    Get-RollingStatus
}

function Resume-Rollout {
    Write-Host "`n=== Resuming Rollout ===" -ForegroundColor Cyan
    kubectl rollout resume deployment/$DEPLOYMENT -n $NAMESPACE
    Write-Host "Rollout resumed." -ForegroundColor Yellow
    
    # Watch the rollout
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE
    Get-RollingStatus
}

function Get-RolloutHistory {
    Write-Host "`n=== Rollout History ===" -ForegroundColor Cyan
    kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE
    
    Write-Host "`nTo see details of a specific revision:" -ForegroundColor Yellow
    Write-Host "  kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE --revision=<number>"
}

function Restart-Deployment {
    Write-Host "`n=== Restarting Deployment ===" -ForegroundColor Cyan
    Write-Host "This will perform a rolling restart of all pods..." -ForegroundColor Yellow
    
    kubectl rollout restart deployment/$DEPLOYMENT -n $NAMESPACE
    
    # Watch the restart
    Write-Host "`nWatching restart progress..." -ForegroundColor Yellow
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE
    
    Write-Host "`nRestart completed!" -ForegroundColor Green
    Get-RollingStatus
}

# Main script logic
switch ($args[0]) {
    "status" { Get-RollingStatus }
    "update" { Update-Image -NewImage $args[1] }
    "rollback" { Rollback-Deployment }
    "pause" { Pause-Rollout }
    "resume" { Resume-Rollout }
    "history" { Get-RolloutHistory }
    "restart" { Restart-Deployment }
    default { Show-Help }
}
