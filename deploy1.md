{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "prefixName": {
      "type": "string",
      "defaultValue": "",
      "minLength": 3,
      "maxLength": 10,
      "metadata": {
        "description": "Name prefix between 3-6 characters with only characters and numbers"
      }
    }, 
    "office365DisplayName": {
      "type": "string",
      "defaultValue": "",
      "metadata": {
        "description": "Office 365 Email Address"
      }
    },
    "AllowAll": {
      "type": "string",
      "allowedValues": [
          "true",
          "false"
      ],
      "defaultValue": "false"
    }
  },
  "variables": {
    "subscriptionId": "[subscription().subscriptionId]",
    "location": "[resourceGroup().location]",
    "rgId": "[resourceGroup().id]",
    "rgName": "[resourceGroup().name]",
    "tenantId": "[subscription().tenantId]",
    "paramName": "[parameters('prefixName')]",
    "storageContainer": "data",
    "uniqueName": "[substring(uniqueString(variables('rgId')),3,4)]",
    "synapseWorkspaceName": "[concat('synapse-ws-',variables('paramName'))]",
    "storageName": "[replace(replace(toLower(concat(concat('synapsestrg',variables('paramName')),variables('uniqueName'))),'-',''),'_','')]",
    "machinelearningName": "[concat('ml-', variables('paramName'))]",
    "storageMLname": "[replace(replace(toLower(concat(concat('mlstrg',variables('paramName')),variables('uniqueName'))),'-',''),'_','')]",
    "appinsightsname": "[concat(variables('machinelearningName'), 'ai')]",
    "keyvaultname": "[replace(replace(toLower(concat(concat('keyvault',variables('paramName')),variables('uniqueName'))),'-',''),'_','')]",
    "cosmosdbname": "[replace(replace(toLower(concat(concat('cosmosdb',variables('paramName')),variables('uniqueName'))),'-',''),'_','')]",
    "textanalyticsname": "[replace(replace(toLower(concat(concat('textanalytics',variables('paramName')),variables('uniqueName'))),'-',''),'_','')]",
    "searchservicename": "[replace(replace(toLower(concat(concat('search',variables('paramName')),variables('uniqueName'))),'-',''),'_','')]",
    "logicappname": "[replace(replace(toLower(concat(concat('logicapp',variables('paramName')),variables('uniqueName'))),'-',''),'_','')]",
    "functionAppName": "[replace(replace(toLower(concat(concat('functionapp',variables('paramName')),variables('uniqueName'))),'-',''),'_','')]",
    "StorageBlobDataContributor": "ba92f5b4-2d11-453d-a403-e96b0029c9fe"
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2019-06-01",
      "name": "[variables('storageName')]",
      "location": "[variables('location')]",
      "sku": {
        "name": "Standard_LRS",
        "tier": "Standard"
      },
      "kind": "StorageV2",
      "properties": {
        "isHnsEnabled": true,
        "networkAcls": {
          "bypass": "AzureServices",
          "virtualNetworkRules": [],
          "ipRules": [],
          "defaultAction": "Allow"
        },
        "supportsHttpsTrafficOnly": true,
        "encryption": {
          "services": {
            "file": {
              "enabled": true
            },
            "blob": {
              "enabled": true
            }
          },
          "keySource": "Microsoft.Storage"
        },
        "accessTier": "Hot"
      }
    },
    {
      "type": "Microsoft.Storage/storageAccounts/blobServices",
      "apiVersion": "2019-06-01",
      "name": "[concat(variables('storageName'), '/default')]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', variables('storageName'))]"
      ],
      "properties": {
        "cors": {
          "corsRules": []
        },
        "deleteRetentionPolicy": {
          "enabled": false
        }
      }
    },
    {
      "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
      "apiVersion": "2019-06-01",
      "name": "[concat(variables('storageName'), '/default/', variables('storageContainer'))]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts/blobServices', variables('storageName'), 'default')]",
        "[resourceId('Microsoft.Storage/storageAccounts', variables('storageName'))]"
      ],
      "properties": {
        "publicAccess": "None"
      }
    },
    {
      "type": "Microsoft.Synapse/workspaces",
      "apiVersion": "2020-12-01",
      "name": "[variables('synapseWorkspaceName')]",
      "location": "[variables('location')]",
      "identity": {
        "type": "SystemAssigned"
      },
      "properties": {
        "defaultDataLakeStorage": {
          "accountUrl": "[concat('https://', variables('storageName') , '.dfs.core.windows.net')]",
          "filesystem": "[variables('storageContainer')]"
        },
        "virtualNetworkProfile": {
          "computeSubnetId": ""
        },
        "sqlAdministratorLogin": "sqladminuser"
      },
      "resources": [
        {
          "condition": "[equals(parameters('AllowAll'),'true')]",
          "type": "firewallrules",
          "apiVersion": "2019-06-01-preview",
          "name": "allowAll",
          "location": "[variables('location')]",
          "dependsOn": [ "[variables('synapseWorkspaceName')]" ],
          "properties": {
            "startIpAddress": "0.0.0.0",
            "endIpAddress": "255.255.255.255"
          }
        }
      ]
    },
    {
      "type": "Microsoft.Synapse/workspaces/bigDataPools",
      "apiVersion": "2020-12-01",
      "name": "[concat(variables('synapseWorkspaceName'), '/spark1')]",
      "location": "[variables('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Synapse/workspaces', variables('synapseWorkspaceName'))]"
      ],
      "properties": {
		"sparkVersion": "3.1",
        "nodeCount": 10,
        "nodeSize": "Medium",
        "nodeSizeFamily": "MemoryOptimized",
        "autoScale": {
          "enabled": true,
          "minNodeCount": 3,
          "maxNodeCount": 10
        },
        "autoPause": {
          "enabled": true,
          "delayInMinutes": 15
        },
        "isComputeIsolationEnabled": false,
        "sessionLevelPackagesEnabled": false,
        "cacheSize": 0,
        "dynamicExecutorAllocation": {
          "enabled": true
        },
        "provisioningState": "Succeeded"
      }
    },
    {
      "type": "microsoft.insights/components",
      "apiVersion": "2020-02-02-preview",
      "name": "[variables('appinsightsName')]",
      "location": "[variables('location')]",
      "kind": "web",
      "properties": {
        "Application_Type": "web",
        "IngestionMode": "ApplicationInsights",
        "publicNetworkAccessForIngestion": "Enabled",
        "publicNetworkAccessForQuery": "Enabled"
      }
    },
    {
      "type": "Microsoft.KeyVault/vaults",
      "apiVersion": "2020-04-01-preview",
      "name": "[variables('keyvaultName')]",
      "location": "[variables('location')]",
      "properties": {
        "sku": {
          "family": "A",
          "name": "standard"
        },
        "tenantId": "[variables('tenantId')]",
        "accessPolicies": [],
        "enabledForDeployment": false,
        "enableSoftDelete": false,
        "vaultUri": "[concat('https://', variables('keyvaultName'), '.vault.azure.net/')]",
        "provisioningState": "Succeeded"
      }
    },
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2021-01-01",
      "name": "[variables('storageMLName')]",
      "location": "[variables('location')]",
      "sku": {
        "name": "Standard_LRS",
        "tier": "Standard"
      },
      "kind": "StorageV2",
      "properties": {
        "networkAcls": {
          "bypass": "AzureServices",
          "virtualNetworkRules": [],
          "ipRules": [],
          "defaultAction": "Allow"
        },
        "supportsHttpsTrafficOnly": true,
        "encryption": {
          "services": {
            "file": {
              "keyType": "Account",
              "enabled": true
            },
            "blob": {
              "keyType": "Account",
              "enabled": true
            }
          },
          "keySource": "Microsoft.Storage"
        },
        "accessTier": "Hot"
      }
    },
    {
      "type": "Microsoft.MachineLearningServices/workspaces",
      "apiVersion": "2021-01-01",
      "name": "[variables('machinelearningName')]",
      "location": "[variables('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', variables('storageMLname'))]",
        "[resourceId('Microsoft.KeyVault/vaults', variables('keyvaultname'))]",
        "[resourceId('microsoft.insights/components', variables('appinsightsname'))]"
      ],
      "sku": {
        "name": "Basic",
        "tier": "Basic"
      },
      "identity": {
        "type": "SystemAssigned"
      },
      "properties": {
        "friendlyName": "[variables('machinelearningName')]",
        "storageAccount": "[resourceId('Microsoft.Storage/storageAccounts', variables('storageMLname'))]",
        "keyVault": "[resourceId('Microsoft.KeyVault/vaults', variables('keyvaultname'))]",
        "applicationInsights": "[resourceId('microsoft.insights/components', variables('appinsightsname'))]",
        "hbiWorkspace": false,
        "allowPublicAccessWhenBehindVnet": false
      }
    },
    {
      "name": "[variables('cosmosdbname')]",
      "type": "Microsoft.DocumentDB/databaseAccounts",
      "apiVersion": "2019-12-12",
      "location": "[variables('location')]",
      "tags": {},
      "kind": "GlobalDocumentDB",
      "properties": {
        "consistencyPolicy": {
          "defaultConsistencyLevel": "Session",
          "maxStalenessPrefix": 1,
          "maxIntervalInSeconds": 5
        },
        "locations": [
          {
            "locationName": "[variables('location')]",
            "failoverPriority": 0
          }
        ],
        "databaseAccountOfferType": "Standard",
        "enableAutomaticFailover": false
      }
    },
    {
      "type": "Microsoft.DocumentDB/databaseAccounts/sqlDatabases",
      "name": "[concat(variables('cosmosdbname'), '/', 'customercomplaints')]",
      "apiVersion": "2021-04-15",
      "dependsOn": [
        "[resourceId('Microsoft.DocumentDB/databaseAccounts/', variables('cosmosdbname'))]"
      ],
      "properties": {
        "resource": {
          "id": "customercomplaints"
        },
        "options": {
          "autoscaleSettings": {
            "maxThroughput": 4000
          }
        }
      }
    },
    {
      "type": "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers",
      "name": "[concat(variables('cosmosdbname'), '/', 'customercomplaints', '/', 'complaints')]",
      "apiVersion": "2021-04-15",
      "dependsOn": [
        "[resourceId('Microsoft.DocumentDB/databaseAccounts/sqlDatabases', variables('cosmosdbname'), 'customercomplaints')]"
      ],
      "properties": {
        "resource": {
          "id": "complaints",
          "partitionKey": {
            "paths": [
              "/Class1"
            ],
            "kind": "hash"
          },
          "indexingPolicy": {
            "indexingMode": "consistent",
            "includedPaths": [
              {
                "path": "/*",
                "indexes": [
                  {
                    "kind": "Hash",
                    "dataType": "String",
                    "precision": -1
                  }
                ]
              }
            ],
            "excludedPaths": [
              {
                "path": "/\"_etag\"/?"
              }
            ]
          }
        },
        "options": {}
      }
    },
    {
      "type": "Microsoft.DocumentDb/databaseAccounts/sqlDatabases/containers",
      "name": "[concat(variables('cosmosdbname'), '/', 'customercomplaints', '/', 'responses')]",
      "apiVersion": "2021-04-15",
      "dependsOn": [
        "[resourceId('Microsoft.DocumentDB/databaseAccounts/sqlDatabases', variables('cosmosdbname'), 'customercomplaints')]"
      ],
      "properties": {
        "resource": {
          "id": "responses",
          "partitionKey": {
            "paths": [
              "/SupportAgent"
            ],
            "kind": "hash"
          },
          "indexingPolicy": {
            "indexingMode": "consistent",
            "includedPaths": [
              {
                "path": "/*",
                "indexes": [
                  {
                    "kind": "Hash",
                    "dataType": "String",
                    "precision": -1
                  }
                ]
              }
            ],
            "excludedPaths": [
              {
                "path": "/\"_etag\"/?"
              }
            ]
          }
        },
        "options": {}
      }
    },
    {
      "type": "Microsoft.DocumentDb/databaseAccounts/sqlDatabases/containers",
      "name": "[concat(variables('cosmosdbname'), '/', 'customercomplaints', '/', 'employees')]",
      "apiVersion": "2021-04-15",
      "dependsOn": [
        "[resourceId('Microsoft.DocumentDB/databaseAccounts/sqlDatabases', variables('cosmosdbname'), 'customercomplaints')]"
      ],
      "properties": {
        "resource": {
          "id": "employees",
          "partitionKey": {
            "paths": [
              "/department"
            ],
            "kind": "hash"
          },
          "indexingPolicy": {
            "indexingMode": "consistent",
            "includedPaths": [
              {
                "path": "/*",
                "indexes": [
                  {
                    "kind": "Hash",
                    "dataType": "String",
                    "precision": -1
                  }
                ]
              }
            ],
            "excludedPaths": [
              {
                "path": "/\"_etag\"/?"
              }
            ]
          }
        },
        "options": {}
      }
    },
    {
      "type": "Microsoft.CognitiveServices/accounts",
      "apiVersion": "2017-04-18",
      "name": "[variables('textanalyticsname')]",
      "location": "[variables('location')]",
      "sku": {
        "name": "S"
      },
      "kind": "TextAnalytics",
      "properties": {
        "statisticsEnabled": false,
        "enableSoftDelete": false
      }
    },
    {
      "name": "[variables('searchservicename')]",
      "type": "Microsoft.Search/searchServices",
      "apiVersion": "2020-08-01",
      "tags": {},
      "location": "[variables('location')]",
      "properties": {
        "replicaCount": 1,
        "partitionCount": 1,
        "publicNetworkAccess": "enabled",
        "enableSoftDelete": false
      },
      "sku": {
        "name": "basic"
      },
      "identity": {
        "type": "None"
      }
    },
    {
      "type": "MICROSOFT.WEB/CONNECTIONS",
      "apiVersion": "2018-07-01-preview",
      "name": "azureblob",
      "location": "[variables('location')]",
      "properties": {
        "api": {
          "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', variables('location'), '/managedApis/', 'azureblob')]"
        },
        "displayName": "blob connection",
        "parameterValues": {
          "accountName": "[variables('storageName')]",
          "accessKey": "[listKeys(variables('storageName'),'2019-06-01').keys[0].value]",
          "authType": "basic",
          "privacySetting": "None"
        }
      }
    },
    {
      "type": "MICROSOFT.WEB/CONNECTIONS",
      "apiVersion": "2018-07-01-preview",
      "name": "documentdb",
      "location": "[variables('location')]",
      "properties": {
        "api": {
          "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', variables('location'), '/managedApis/', 'documentdb')]"
        },
        "displayName": "ccmcosmosdb",
        "parameterValues": {
          "databaseAccount": "[variables('cosmosdbname')]",
          "accessKey": "[listKeys(variables('cosmosdbname'),'2019-12-12').primaryMasterKey]"
        }
      }
    },
    {
      "type": "MICROSOFT.WEB/CONNECTIONS",
      "apiVersion": "2018-07-01-preview",
      "name": "conversionservice",
      "location": "[variables('location')]",
      "properties": {
        "api": {
          "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', variables('location'), '/managedApis/', 'conversionservice')]"
        },
        "displayName": "Content Conversion"
      }
    },
    {
      "type": "MICROSOFT.WEB/CONNECTIONS",
      "apiVersion": "2018-07-01-preview",
      "name": "office365-1",
      "location": "[variables('location')]",
      "properties": {
        "api": {
          "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', variables('location'), '/managedApis/', 'office365')]"
        },
        "displayName": "[parameters('office365DisplayName')]"
      }
    },
    {
      "type": "MICROSOFT.WEB/CONNECTIONS",
      "apiVersion": "2018-07-01-preview",
      "name": "cognitiveservicestextanalytics-1",
      "location": "[variables('location')]",
      "properties": {
        "api": {
          "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', variables('location'), '/managedApis/', 'cognitiveservicestextanalytics')]"
        },
        "displayName": "ccmtextanalytics",
        "parameterValues": {
          "apiKey": "[listKeys(variables('textanalyticsname'),'2021-04-30').key1]",
          "siteUrl": "[reference(variables('textanalyticsname'),'2021-04-30').endpoint]"
        }
      }
    },
    {
      "properties": {
        "state": "Enabled",
        "definition": {
          "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
          "actions": {
            "ClassifyComplaint": {
              "type": "Http",
              "inputs": {
                "method": "POST",
                "uri": "http://e7a61c74-3483-4fa0-9728-fe6764a4e8ab.westus.azurecontainer.io/score",
                "headers": {
                  "Content-Type": "application/json"
                },
                "body": [
                  {
                    "complaint": "@{variables('TrimComplaintText')}"
                  }
                ]
              },
              "runAfter": {
                "Set_TrimComplaintText": [
                  "Succeeded"
                ]
              }
            },
            "Email_Body_Html_to_Text": {
              "type": "ApiConnection",
              "inputs": {
                "host": {
                  "connection": {
                    "name": "@parameters('$connections')['conversionservice']['connectionId']"
                  }
                },
                "method": "post",
                "body": "<p>@{variables('ComplaintText')}</p>",
                "path": "/html2text"
              },
              "runAfter": {
                "Set_ComplaintText": [
                  "Succeeded"
                ]
              }
            },
            "For_each": {
              "type": "Foreach",
              "foreach": "@body('Sentiment_(V3.0)')['documents']",
              "actions": {
                "Compose": {
                  "type": "Compose",
                  "inputs": [
                    {
                      "Class1": "@{body('Parse_ClassifyComplaint')?['predictions']?['class1']}",
                      "Class2": "@{body('Parse_ClassifyComplaint')?['predictions']?['class2']}",
                      "Class3": "@{body('Parse_ClassifyComplaint')?['predictions']?['class3']}",
                      "Class4": "@{body('Parse_ClassifyComplaint')?['predictions']?['class4']}",
                      "Class5": "@{body('Parse_ClassifyComplaint')?['predictions']?['class5']}",
                      "ComplaintDate": "@{triggerBody()?['receivedDateTime']}",
                      "ComplaintFullText": "@{decodeUriComponent(replace(encodeUriComponent(trim(variables('TrimComplaintText'))),'%0A',encodeUriComponent(' ')))}",
                      "ComplaintId": "@variables('ComplaintId')",
                      "ComplaintSentiment": "@{items('For_each')['sentiment']}",
                      "ComplaintSentimentScore": "@{body('Parse_JSON_SentimentScore')?[variables('Sentiment')]}",
                      "ComplaintSubject": "@{triggerBody()?['subject']}",
                      "ComplaintTextSummary": "@{variables('SumComplaint')}",
                      "ComplaintTextSummaryOutlook": "@{variables('SumComplaint')}",
                      "CustomerEmail": "@{variables('CustomerEmailAddress')}",
                      "CustomerId": "@{rand(100000,999999)}",
                      "CustomerName": "@{split(variables('CustomerEmailAddress'),'@')[0]}",
                      "Department": "@{body('Parse_ClassifyComplaint')?['predictions']?['class1']}",
                      "ResolvedDate": "",
                      "Response": "",
                      "Status": "New",
                      "SubClass1": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass1']}",
                      "SubClass1Score": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass1_score']}",
                      "SubClass2": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass2']}",
                      "SubClass2Score": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass2_score']}",
                      "SubClass3": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass3']}",
                      "SubClass3Score": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass3_score']}",
                      "SubClass4": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass4']}",
                      "SubClass4Score": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass4_score']}",
                      "SubClass5": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass5']}",
                      "SubClass5Score": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass5_score']}",
                      "SupportAgent": "",
                      "id": "@{guid()}"
                    }
                  ],
                  "runAfter": {
                    "Parse_JSON_SentimentScore": [
                      "Succeeded"
                    ]
                  }
                },
                "Create_CSV_from_full_JSON": {
                  "type": "Table",
                  "inputs": {
                    "from": "@outputs('Compose')",
                    "format": "CSV"
                  },
                  "runAfter": {
                    "Compose": [
                      "Succeeded"
                    ]
                  }
                },
                "Create_or_update_document_(V2)": {
                  "type": "ApiConnection",
                  "inputs": {
                    "host": {
                      "connection": {
                        "name": "@parameters('$connections')['documentdb']['connectionId']"
                      }
                    },
                    "method": "post",
                    "body": {
                      "Class1": "@{body('Parse_ClassifyComplaint')?['predictions']?['class1']}",
                      "Class2": "@{body('Parse_ClassifyComplaint')?['predictions']?['class2']}",
                      "Class3": "@{body('Parse_ClassifyComplaint')?['predictions']?['class3']}",
                      "Class4": "@{body('Parse_ClassifyComplaint')?['predictions']?['class4']}",
                      "Class5": "@{body('Parse_ClassifyComplaint')?['predictions']?['class5']}",
                      "ComplaintDate": "@{formatDateTime(variables('ReceivedDateTime'),'yyyy/MM/dd HH:mm:s')}",
                      "ComplaintFullText": "@{decodeUriComponent(replace(encodeUriComponent(trim(variables('TrimComplaintText'))),'%0A',encodeUriComponent(' ')))}",
                      "ComplaintId": "@variables('ComplaintId')",
                      "ComplaintSentiment": "@{items('For_each')['sentiment']}",
                      "ComplaintSentimentScore": "@{body('Parse_JSON_SentimentScore')?[variables('Sentiment')]}",
                      "ComplaintSubject": "@{triggerBody()?['subject']}",
                      "ComplaintTextSummary": "@{variables('SumComplaint')}",
                      "ComplaintTextSummaryOutlook": "@{variables('SumComplaint')}",
                      "CustomerEmail": "@{variables('CustomerEmailAddress')}",
                      "CustomerId": "@{rand(100000,999999)}",
                      "CustomerName": "@{split(variables('CustomerEmailAddress'),'@')[0]}",
                      "Department": "@{body('Parse_ClassifyComplaint')?['predictions']?['class1']}",
                      "ResolvedDate": "",
                      "Response": "",
                      "Status": "New",
                      "SubClass1": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass1']}",
                      "SubClass1Score": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass1_score']}",
                      "SubClass2": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass2']}",
                      "SubClass2Score": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass2_score']}",
                      "SubClass3": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass3']}",
                      "SubClass3Score": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass3_score']}",
                      "SubClass4": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass4']}",
                      "SubClass4Score": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass4_score']}",
                      "SubClass5": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass5']}",
                      "SubClass5Score": "@{body('Parse_ClassifyComplaint')?['predictions']?['subclass5_score']}",
                      "SupportAgent": "",
                      "id": "@{guid()}"
                    },
                    "path": "/v3/dbs/@{encodeURIComponent('customercomplaints')}/colls/@{encodeURIComponent('complaints')}/docs"
                  },
                  "runAfter": {
                    "Create_CSV_from_full_JSON": [
                      "Succeeded"
                    ]
                  }
                },
                "Parse_JSON_SentimentScore": {
                  "type": "ParseJson",
                  "inputs": {
                    "content": "@variables('SentimentScores')",
                    "schema": {
                      "properties": {
                        "negative": {
                          "type": "number"
                        },
                        "neutral": {
                          "type": "number"
                        },
                        "positive": {
                          "type": "number"
                        }
                      },
                      "type": "object"
                    }
                  },
                  "runAfter": {
                    "Set_Sentiment": [
                      "Succeeded"
                    ]
                  }
                },
                "Set_Sentiment": {
                  "type": "SetVariable",
                  "inputs": {
                    "name": "Sentiment",
                    "value": "@items('For_each')['sentiment']"
                  },
                  "runAfter": {
                    "Set_SentimentScore": [
                      "Succeeded"
                    ]
                  }
                },
                "Set_SentimentScore": {
                  "type": "SetVariable",
                  "inputs": {
                    "name": "SentimentScores",
                    "value": "@{items('For_each')['confidenceScores']}"
                  },
                  "runAfter": {}
                }
              },
              "runAfter": {
                "Sentiment_(V3.0)": [
                  "Succeeded"
                ]
              }
            },
            "Initialize_ComplaintId": {
              "type": "InitializeVariable",
              "inputs": {
                "variables": [
                  {
                    "name": "ComplaintId",
                    "type": "string",
                    "value": "@{guid()}"
                  }
                ]
              },
              "runAfter": {
                "Initialize_Sentiment": [
                  "Succeeded"
                ]
              }
            },
            "Initialize_ComplaintText": {
              "type": "InitializeVariable",
              "inputs": {
                "variables": [
                  {
                    "name": "ComplaintText",
                    "type": "string"
                  }
                ]
              },
              "runAfter": {
                "Initialize_CustomerEmailAddress": [
                  "Succeeded"
                ]
              }
            },
            "Initialize_CustomerEmailAddress": {
              "type": "InitializeVariable",
              "inputs": {
                "variables": [
                  {
                    "name": "CustomerEmailAddress",
                    "type": "string"
                  }
                ]
              },
              "runAfter": {}
            },
            "Initialize_Sentiment": {
              "type": "InitializeVariable",
              "inputs": {
                "variables": [
                  {
                    "name": "Sentiment",
                    "type": "string"
                  }
                ]
              },
              "runAfter": {
                "Initialize_SentimentScores": [
                  "Succeeded"
                ]
              }
            },
            "Initialize_SentimentScores": {
              "type": "InitializeVariable",
              "inputs": {
                "variables": [
                  {
                    "name": "SentimentScores",
                    "type": "string"
                  }
                ]
              },
              "runAfter": {
                "Initialize_TrimComplaintText": [
                  "Succeeded"
                ]
              }
            },
            "Initialize_SumComplaint": {
              "type": "InitializeVariable",
              "inputs": {
                "variables": [
                  {
                    "name": "SumComplaint",
                    "type": "string"
                  }
                ]
              },
              "runAfter": {
                "Initialize_ComplaintText": [
                  "Succeeded"
                ]
              }
            },
            "Initialize_TrimComplaintText": {
              "type": "InitializeVariable",
              "inputs": {
                "variables": [
                  {
                    "name": "TrimComplaintText",
                    "type": "string"
                  }
                ]
              },
              "runAfter": {
                "Initialize_SumComplaint": [
                  "Succeeded"
                ]
              }
            },
            "Initialize_variable": {
              "type": "InitializeVariable",
              "inputs": {
                "variables": [
                  {
                    "name": "ReceivedDateTime",
                    "type": "string",
                    "value": "@triggerBody()?['receivedDateTime']"
                  }
                ]
              },
              "runAfter": {
                "Initialize_ComplaintId": [
                  "Succeeded"
                ]
              }
            },
            "Parse_ClassifyComplaint": {
              "type": "ParseJson",
              "inputs": {
                "content": "@body('ClassifyComplaint')",
                "schema": {
                  "properties": {
                    "predictions": {
                      "properties": {
                        "class1": {
                          "type": "string"
                        },
                        "class2": {
                          "type": "string"
                        },
                        "class3": {
                          "type": "string"
                        },
                        "class4": {
                          "type": "string"
                        },
                        "class5": {
                          "type": "string"
                        },
                        "subclass1": {
                          "type": "string"
                        },
                        "subclass1_score": {
                          "type": "string"
                        },
                        "subclass2": {
                          "type": "string"
                        },
                        "subclass2_score": {
                          "type": "string"
                        },
                        "subclass3": {
                          "type": "string"
                        },
                        "subclass3_score": {
                          "type": "string"
                        },
                        "subclass4": {
                          "type": "string"
                        },
                        "subclass4_score": {
                          "type": "string"
                        },
                        "subclass5": {
                          "type": "string"
                        },
                        "subclass5_score": {
                          "type": "string"
                        }
                      },
                      "type": "object"
                    }
                  },
                  "type": "object"
                }
              },
              "runAfter": {
                "ClassifyComplaint": [
                  "Succeeded"
                ]
              }
            },
            "Sentiment_(V3.0)": {
              "type": "ApiConnection",
              "inputs": {
                "host": {
                  "connection": {
                    "name": "@parameters('$connections')['cognitiveservicestextanalytics_1']['connectionId']"
                  }
                },
                "method": "post",
                "body": {
                  "documents": [
                    {
                      "id": "@{guid()}",
                      "text": "@{decodeUriComponent(replace(encodeUriComponent(trim(variables('TrimComplaintText'))),'%0A',encodeUriComponent(' ')))}"
                    }
                  ]
                },
                "path": "/text/analytics/v3.0/sentiment"
              },
              "runAfter": {
                "Parse_ClassifyComplaint": [
                  "Succeeded"
                ]
              }
            },
            "Set_ComplaintText": {
              "type": "SetVariable",
              "inputs": {
                "name": "ComplaintText",
                "value": "@triggerBody()?['body']"
              },
              "runAfter": {
                "Set_SumComplaint": [
                  "Succeeded"
                ]
              }
            },
            "Set_CustomerEmailAddress": {
              "type": "SetVariable",
              "inputs": {
                "name": "CustomerEmailAddress",
                "value": "@triggerBody()?['from']"
              },
              "runAfter": {
                "Initialize_variable": [
                  "Succeeded"
                ]
              }
            },
            "Set_SumComplaint": {
              "type": "SetVariable",
              "inputs": {
                "name": "SumComplaint",
                "value": "@triggerBody()?['bodyPreview']"
              },
              "runAfter": {
                "Set_CustomerEmailAddress": [
                  "Succeeded"
                ]
              }
            },
            "Set_TrimComplaintText": {
              "type": "SetVariable",
              "inputs": {
                "name": "TrimComplaintText",
                "value": "@body('Email_Body_Html_to_Text')"
              },
              "runAfter": {
                "Email_Body_Html_to_Text": [
                  "Succeeded"
                ]
              }
            }
          },
          "parameters": {
            "$connections": {
              "defaultValue": {},
              "type": "Object"
            }
          },
          "triggers": {
            "When_a_new_email_arrives_(V3)": {
              "type": "ApiConnectionNotification",
              "inputs": {
                "host": {
                  "connection": {
                    "name": "@parameters('$connections')['office365_1']['connectionId']"
                  }
                },
                "fetch": {
                  "queries": {
                    "folderPath": "Inbox",
                    "importance": "Any",
                    "fetchOnlyWithAttachment": false,
                    "includeAttachments": false,
                    "subjectFilter": "Complaint:"
                  },
                  "pathTemplate": {
                    "template": "/v3/Mail/OnNewEmail"
                  },
                  "method": "get"
                },
                "subscribe": {
                  "queries": {
                    "folderPath": "Inbox",
                    "importance": "Any",
                    "fetchOnlyWithAttachment": false
                  },
                  "body": {
                    "NotificationUrl": "@{listCallbackUrl()}"
                  },
                  "pathTemplate": {
                    "template": "/GraphMailSubscriptionPoke/$subscriptions"
                  },
                  "method": "post"
                }
              },
              "splitOn": "@triggerBody()?['value']"
            }
          },
          "contentVersion": "1.0.0.0",
          "outputs": {}
        },
        "parameters": {
          "$connections": {
            "value": {
              "conversionservice": {
                "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', variables('location'), '/managedApis/', 'conversionservice')]",
                "connectionId": "[resourceId('Microsoft.Web/connections', 'conversionservice')]",
                "connectionName": "conversionservice"
              },
              "azureblob": {
                "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', variables('location'), '/managedApis/', 'azureblob')]",
                "connectionId": "[resourceId('Microsoft.Web/connections', 'azureblob')]",
                "connectionName": "azureblob"
              },
              "documentdb": {
                "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', variables('location'), '/managedApis/', 'documentdb')]",
                "connectionId": "[resourceId('Microsoft.Web/connections', 'documentdb')]",
                "connectionName": "documentdb"
              },
              "cognitiveservicestextanalytics_1": {
                "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', variables('location'), '/managedApis/', 'cognitiveservicestextanalytics')]",
                "connectionId": "[resourceId('Microsoft.Web/connections', 'cognitiveservicestextanalytics-1')]",
                "connectionName": "cognitiveservicestextanalytics-1"
              },
              "office365_1": {
                "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', variables('location'), '/managedApis/', 'office365')]",
                "connectionId": "[resourceId('Microsoft.Web/connections', 'office365-1')]",
                "connectionName": "office365-1"
              }
            }
          }
        }
      },
      "name": "[variables('logicappname')]",
      "type": "Microsoft.Logic/workflows",
      "location": "[variables('location')]",
      "tags": {
        "displayName": "LogicApp"
      },
      "apiVersion": "2016-06-01",
      "dependsOn": [
        "[resourceId('Microsoft.Web/connections', 'conversionservice')]",
        "[resourceId('Microsoft.Web/connections', 'azureblob')]",
        "[resourceId('Microsoft.Web/connections', 'documentdb')]",
        "[resourceId('Microsoft.Web/connections', 'cognitiveservicestextanalytics-1')]",
        "[resourceId('Microsoft.Web/connections', 'office365-1')]"
      ]
    },
    {
      "apiVersion": "2020-12-01",
      "type": "Microsoft.Web/sites",
      "name": "[variables('functionAppName')]",
      "location": "[resourceGroup().location]",
      "kind": "functionapp,linux",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', variables('storageName'))]",
        "[resourceId('microsoft.insights/components', variables('appinsightsname'))]"
      ],
      "properties": {
        "siteConfig": {
          "appSettings": [
            {
              "name": "AzureWebJobsStorage",
              "value": "[concat('DefaultEndpointsProtocol=https;AccountName=', variables('storageName'), ';AccountKey=', listKeys(variables('storageName'),'2019-06-01').keys[0].value)]"
            },
            {
              "name": "FUNCTIONS_WORKER_RUNTIME",
              "value": "python"
            },
            {
              "name": "FUNCTIONS_EXTENSION_VERSION",
              "value": "~3"
            }
          ]
        },
        "reserved": true
      }
    },
    {
      "scope": "[concat('Microsoft.Storage/storageAccounts/', variables('storageName'))]",
      "type": "Microsoft.Authorization/roleAssignments",
      "apiVersion": "2020-04-01-preview",
      "name": "[guid(uniqueString(variables('storageName')))]",
      "location": "[variables('location')]",
      "dependsOn": [
        "[variables('synapseWorkspaceName')]"
      ],
      "properties": {
        "roleDefinitionId": "[resourceId('Microsoft.Authorization/roleDefinitions', variables('StorageBlobDataContributor'))]",
        "principalId": "[reference(resourceId('Microsoft.Synapse/workspaces', variables('synapseWorkspaceName')), '2019-06-01-preview', 'Full').identity.principalId]",
        "principalType": "ServicePrincipal"
      }
    },
    {
      "apiVersion": "2020-10-01",
      "name": "pid-7ce88463-b78a-5332-b3b0-dc94b30104eb",
      "type": "Microsoft.Resources/deployments",
      "properties": {
        "mode": "Incremental",
        "template": {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "resources": []
        }
      }
    }
  ]
}
