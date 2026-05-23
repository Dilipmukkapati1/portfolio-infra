param location string
param namePrefix string
param uniqueSuffix string
param ownerEmail string

var batchAccountName = take('${namePrefix}batch${uniqueSuffix}', 24)

resource batchAccount 'Microsoft.Batch/batchAccounts@2024-02-01' = {
  name: batchAccountName
  location: location
  tags: {
    owner: ownerEmail
    project: 'portfolio'
  }
  properties: {
    poolAllocationMode: 'BatchService'
  }
}

// Pool scaffold: scale to zero when idle (configure autoscale in Portal or Phase 2)
resource pool 'Microsoft.Batch/batchAccounts/pools@2024-02-01' = {
  parent: batchAccount
  name: 'portfolio-pool'
  properties: {
    vmSize: 'Standard_D2s_v3'
    taskSlotsPerNode: 1
    deploymentConfiguration: {
      virtualMachineConfiguration: {
        imageReference: {
          publisher: 'microsoft-azure-batch'
          offer: 'ubuntu-server-container'
          sku: '20-04-lts'
        }
        nodeAgentSkuId: 'batch.node.ubuntu 20.04'
      }
    }
    scaleSettings: {
      autoScale: {
        formula: 'startingNumberOfVMs = 0; maxNumberofVMs = 1; $TargetDedicatedNodes = 0; $TargetLowPriorityNodes = min(1, max(0, maxNumberofVMs - startingNumberOfVMs));'
        evaluationInterval: 'PT5M'
      }
    }
  }
}

output batchAccountName string = batchAccount.name
