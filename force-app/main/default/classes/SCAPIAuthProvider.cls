/**
 * Created by Sandra Golden on 4/22/22.
 * forked from https://github.com/bobbywhitesfdc/ApigeeAuthProvider
 */

/**
  Custom Auth Provider for Salesforce Commerce API
  Implements the Client Credentials flow which is intended for server-to-server integrations.
**/
public class SCAPIAuthProvider extends Auth.AuthProviderPluginClass {
    public static final String RESOURCE_CALLBACK = '/services/authcallback/';
    public static final String ENCODING_XML = 'application/x-www-form-urlencoded;charset=UTF-8';
    public static final String DUMMY_CODE = '999';

    // This class is dependant on this Custom Metadata Type created to hold custom parameters
    public static final String CUSTOM_MDT_NAME = 'SCAPI_Auth_Provider__mdt';
    public static final String CMT_FIELD_CALLBACK_URL = 'Callback_URL__c';
    public static final String CMT_FIELD_PROVIDER_NAME = 'Auth_Provider_Name__c';
    public static final String CMT_FIELD_AUTHTOKEN_URL = 'Access_Token_URL__c';
    public static final String CMT_FIELD_CLIENT_ID = 'Client_Id__c';
    public static final String CMT_FIELD_CLIENT_SECRET = 'Client_Secret__c';
    public static final String CMT_FIELD_SCOPE = 'Scope__c';

    public static final String GRANT_TYPE_PARAM = 'grant_type';
    public static final String SCOPE_PARAM = 'scope';
    public static final String GRANT_TYPE_CLIENT_CREDS = 'client_credentials';

    /**
     * Added Constructor purely for debugging purposes to have visibility as to when the class is being instantiated.
     **/
    public SCAPIAuthProvider() {
        super();
        System.debug('Constructor called');
    }

    /**
     * Name of custom metadata type to store this auth provider configuration fields
     * This method is required by its abstract parent class.
     **/
    public String getCustomMetadataType() {
        return CUSTOM_MDT_NAME;
    }

    /**
     * Initiate callback. No End User authorization required in this flow so skip straight to the Token request.
     * The interface requires the callback url to be defined.
     * Eg: https://test.salesforce.com/services/authcallback/<authprovidername>
     **/
    public PageReference initiate(Map<String, String> config, String stateToPropagate) {
        System.debug('initiate');

        final PageReference pageRef = new PageReference(getCallbackUrl(config));
        pageRef.getParameters().put('state', stateToPropagate);
        pageRef.getParameters().put('code', DUMMY_CODE); // Empirically found this is required, but unused
        System.debug('callback url:' + pageRef.getUrl());
        return pageRef;
    }

    /**
     * This method composes the callback URL automatically UNLESS it has been overridden through Configuration.
     * Normally one should not override the callback URL, but it's there in case the generated URL doesn't work.
     **/
    private String getCallbackUrl(Map<String, String> config) {
        // https://{salesforce-hostname}/services/authcallback/{urlsuffix}
        final String overrideUrl = config.get(CMT_FIELD_CALLBACK_URL);
        final String generatedUrl = Url.getSalesforceBaseUrl().toExternalForm() + RESOURCE_CALLBACK + config.get(CMT_FIELD_PROVIDER_NAME);
        return String.isEmpty(overrideUrl) ? generatedUrl : overrideUrl;
    }

    /**
     * Handle callback (from initial loop back "code" step in the flow).
     * In the Client Credentials flow, this method retrieves the access token directly.
     * Required by parent class.
     **/
    public Auth.AuthProviderTokenResponse handleCallback(Map<String, String> config, Auth.AuthProviderCallbackState state ) {
        System.debug('handleCallback');
        final TokenResponse response = retrieveToken(config);
        return new Auth.AuthProviderTokenResponse(config.get(CMT_FIELD_PROVIDER_NAME),
                response.access_token,
                null, // No Refresh Token
                state.queryParameters.get('state'));
    }

    /**
     * Refresh is required by the parent class and it's used if the original Access Token has expired.
     * In the Client Credentials flow, there is no Refresh token, so its implementation is exactly the
     * same as the Initiate() step.
     **/
    public override Auth.OAuthRefreshResult refresh(Map<String,String> config, String refreshToken) {
        System.debug('refresh');
        final TokenResponse response = retrieveToken(config);
        return new Auth.OAuthRefreshResult(response.access_token, response.token_type, null);
    }

    /**
     * getUserInfo is required by the Parent class, but not fully supported by this provider.
     * Effectively the Client Credentials flow is only useful for Server-to-Server API integrations
     * and cannot be used for other contexts such as a Registration Handler for Communities.
     **/
    public Auth.UserData getUserInfo(Map<String, String> config, Auth.AuthProviderTokenResponse response) {
        System.debug('getUserInfo');
        final Auth.UserData userData = new Auth.UserData(
                null, // identifier
                null, // firstName
                null, // lastName
                null, // fullName
                null, // email
                null, // link
                null, // userName
                null,  //locale
                config.get(CMT_FIELD_PROVIDER_NAME), //provider
                null, // siteLoginUrl
                new Map<String, String>());

        return userData;
    }

    /**
     * Private method that gets the Auth Token using the Client Credentials Flow.
     **/
    private TokenResponse retrieveToken(Map<String, String> config) {
        final HttpRequest req = new HttpRequest();

        final PageReference endpoint = new PageReference(config.get(CMT_FIELD_AUTHTOKEN_URL)); //NOSONAR -- Protected by RemoteSite Setting
        final String encoding = ENCODING_XML;
        final String encodedParams = encodeParameters(config);

        System.debug('Endpoint: ' + endpoint.getUrl());
        System.debug('Content-Type:' + encoding);

        req.setEndpoint(endpoint.getUrl());
        req.setHeader('Content-Type', encoding);

        // set authorization
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(Blob.valueOf(config.get(CMT_FIELD_CLIENT_ID) + ':' + config.get(CMT_FIELD_CLIENT_SECRET)));
        req.setHeader('Authorization', authorizationHeader);
        req.setMethod('POST');
        req.setBody(encodedParams);

        final HttpResponse res = new Http().send(req);

        System.debug('Token Response Status: ' + res.getStatus() + ' ' + res.getStatusCode());

        return deserializeToken(res.getBody());
    }

    // deserialize response and return token
    @TestVisible
    private TokenResponse deserializeToken(String responseBody) {
        // use default parsing for everything we can.
        TokenResponse parsedResponse = (TokenResponse) System.JSON.deserialize(responseBody, TokenResponse.class);
        return parsedResponse;
    }

    @TestVisible
    private String encodeParameters(Map<String, String> config) {
        // Pull out the subset of configured parameters that will be sent
        Map<String, String> params = new Map<String, String>();
        params.put(GRANT_TYPE_PARAM, GRANT_TYPE_CLIENT_CREDS);
        final String scope = config.get(CMT_FIELD_SCOPE);
        if (!String.isEmpty(scope)) {
            params.put(SCOPE_PARAM,scope);
        }
        return encodeAsURL(params);
    }

    private String encodeAsURL(Map<String, String> params) {
        String output = '';
        for (String key : params.keySet()) {
            output += (String.isEmpty(output) ? '' : '&');
            output += key + '=' + params.get(key);
        }
        return output;
    }

    /**
    OAuth Response is a JSON body like this on a Successful call
    {
      "access_token" : "kRxqmPr2b223uzTUGnndQhXWv8F4",
      "scope" : "",
      "token_type": "Bearer",
      "expires_in": 1799
    }

    On failure, the following structure
    {
      "error_description" : "Grant type is not set",
      "error" : "invalid_request"
    }
    **/

    public class TokenResponse {
        public String token_type {get;set;}
        public String access_token {get;set;}
        public String scope {get;set;}
        public String expires_in {get;set;}
        public String error_description {get;set;}
        public String error {get;set;}
    }
}
