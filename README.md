## SCAPIAuthProvider<br/>

Salesforce Commerce API custom auth provider

## Update the following values in the config values to match your Salesforce B2C Instance

### [customMetadata/SCAPI_Auth_Provider.Salesforce_Commerce_API.md-meta.xml](force-app/main/default/customMetadata/SCAPI_Auth_Provider.Salesforce_Commerce_API.md-meta.xml)
1. `Client_Id__c` - Your SCAPI Client ID
2. `Client_Secret__c` - Your SCAPI Client Secret
3. `Scope__c` - your SCAPI scopes. should start with `SALESFORCE_COMMERCE_API:abcd_001` is your tenant

### [namedCredentials/Salesforce_Commerce_API.namedCredential-meta.xml](force-app/main/default/namedCredentials/Salesforce_Commerce_API.namedCredential-meta.xml)
1. `endpoint` - Replace `{{short_code}}` with your Salesforce Commerce API Short Code

## Deploy to Scratch Org
1. `sfdx force:org:create -f config/project-scratch-def.json -a MyScratchOrg`
2. Replace `executionUser` in [authproviders/Salesforce_Commerce_API.authprovider-meta.xml](force-app/main/default/authproviders/Salesforce_Commerce_API.authprovider-meta.xml) with your scratch org username (for example: `test-rcjcv1fkpdd5@example.com`)
3. `sfdx force:source:push -u MyScratchOrg`
