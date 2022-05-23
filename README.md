## SCAPIAuthProvider<br/>

Salesforce Commerce API custom auth provider

## Update the following values in the config values to match your Salesforce B2C Instance

### [customMetadata/SCAPI_Auth_Provider.Salesforce_Commerce_API.md-meta.xml](force-app/main/default/customMetadata/SCAPI_Auth_Provider.B2C.md-meta.xml)
1. `Client_Id__c` - Your SCAPI Client ID
2. `Client_Secret__c` - Your SCAPI Secret Key
3. `Scope__c` - Replace `{{tenantId}}` with your Tenant ID (e.g.: abcd_001). Add any additional scopes.

### [namedCredentials/Salesforce_Commerce_API.namedCredential-meta.xml](force-app/main/default/namedCredentials/B2C_Commerce_Customer_API.namedCredential-meta.xml)
1. `endpoint` - Replace `{{shortCode}}` with your Salesforce Commerce API Short Code
2. `oauthScope` - Replace `{{tenantId}}` with your Tenant ID (e.g.: abcd_001)

## Deploy to Scratch Org
1. `sfdx force:org:create -f config/project-scratch-def.json -a MyScratchOrg`
2. Replace `executionUser` in [authproviders/B2C.authprovider-meta.xml](force-app/main/default/authproviders/B2C.authprovider-meta.xml) with your scratch org username (for example: `test-rcjcv1fkpdd5@example.com`)
3. `sfdx force:source:push -u MyScratchOrg`

## Additional Resources
1. Authorization for Admin APIs: [Create a Commerce API Client ID and Secret Key](https://developer.salesforce.com/docs/commerce/commerce-api/guide/authorization-for-admin-apis.html)
2. [Commerce API Configuration Values](https://developer.salesforce.com/docs/commerce/commerce-api/guide/commerce-api-configuration-values.html)
