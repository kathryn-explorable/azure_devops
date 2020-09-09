Before running this module, you need to:
0. Make sure you have an active Azure subscription
1. Install the Azure CLI. https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
2. create an agent pool in your Azure DevOps organization. self-hosted type. Called private-aci-pool in this example.
3. create a personal access token that it authorized to manage this agent pool.
4. Using terraform 0.12.29:
   terraform init
   az login
   terraform plan -out plan-name.txt
   terraform apply

(Use default pool called Azure Pipelines)
Create a personal access token that can "read/manage" Agent Pools: https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops#permissions

This module has 3 variables related to Azure DevOps:

    azure_devops_org_name: the name of your Azure DevOps organization (if you are connecting to https://dev.azure.com/helloworld, then helloworld is your organization name)
    azure_devops_personal_access_token: the personal access token that you have generated
    agent_pool_name: both in the linux_agents_configuration and windows_agents_configuration, it is the name of the agent pool that you have created in which the Linux or Windows agents must be deployed

