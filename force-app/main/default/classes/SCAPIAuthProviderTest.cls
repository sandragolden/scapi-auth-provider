/**
 * Created by Sandra Golden on 4/22/22.
 * forked from https://github.com/bobbywhitesfdc/ApigeeAuthProvider
 */

/**
  Custom Auth Provider for Salesforce Commerce API
  Implements the Client Credentials flow which is intended for server-to-server integrations.
**/

@IsTest(isParallel=true)
public class SCAPIAuthProviderTest {
    public static final String CONTENT_TYPE_HEADER = 'Content-Type';
    public static final String CONTENT_TYPE_JSON = 'application/json';
    private static final String ACCESS_TOKEN = 'gv6iCx48OaH76ufiGXBUlRTRTXxx';
    private static final String SCOPE = 'sfcc.customerlists.rw';
    private static final String EXPIRES_IN = '1799';
    private static final String STATE = 'mockState';
    private static final String TOKEN_TYPE = 'Bearer';
    private static final String PROVIDER_NAME = 'UnitTestProvider';
    private static final String KEY = 'testKey';
    private static final String SECRET = 'testSecret';
    private static final String STATE_TO_PROPOGATE = 'testState';
    private static final String ACCESS_TOKEN_URL = 'http://www.dummyhost.com/accessTokenUri';
    private static final String EMPTY_VALUE = '';

    private static final String jsonGoodToken = '{' +
            '  \"access_token\" : \"gv6iCx48OaH76ufiGXBUlRTRTXxx\",' +
            '  \"scope\" : \"sfcc.customerlists.rw\",' +
            '  \"token_type\" : \"Bearer\",' +
            '  \"expires_in\" : \"1799\"' +
            '}';
    private static final String jsonError1 = '{' +
            '  \"error_description\" : \"Grant type is not set\",' +
            '  \"error\" : \"invalid_request\"' +
            '}';

    private static Map<String,String> setupAuthProviderConfig () {
        final Map<String,String> authProviderConfiguration = new Map<String, String>();
        authProviderConfiguration.put(SCAPIAuthProvider.CMT_FIELD_PROVIDER_NAME, PROVIDER_NAME);
        authProviderConfiguration.put(SCAPIAuthProvider.CMT_FIELD_AUTHTOKEN_URL, ACCESS_TOKEN_URL);
        authProviderConfiguration.put(SCAPIAuthProvider.CMT_FIELD_CALLBACK_URL, EMPTY_VALUE);
        authProviderConfiguration.put(SCAPIAuthProvider.CMT_FIELD_CLIENT_ID, KEY);
        authProviderConfiguration.put(SCAPIAuthProvider.CMT_FIELD_CLIENT_SECRET, SECRET);
        authProviderConfiguration.put(SCAPIAuthProvider.CMT_FIELD_SCOPE, SCOPE);

        return authProviderConfiguration;
    }

    @IsTest
    static void testMetadataType() {
        final SCAPIAuthProvider provider = new SCAPIAuthProvider();
        final String actual = provider.getCustomMetadataType();
        final String expected = SCAPIAuthProvider.CUSTOM_MDT_NAME;
        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testInitiateMethod() {
        final Map<String, String> authProviderConfiguration = setupAuthProviderConfig();
        final SCAPIAuthProvider provider = new SCAPIAuthProvider();

        final PageReference expectedUrl = new PageReference(authProviderConfiguration.get('Callback_URL__c'));
        expectedUrl.getParameters().put('state', STATE_TO_PROPOGATE);

        final PageReference actualUrl = provider.initiate(authProviderConfiguration, STATE_TO_PROPOGATE);
        System.assertEquals(expectedUrl.getParameters().get('state'), actualUrl.getParameters().get('state'));
    }

    @IsTest
    static void testHandleCallback() {
        final Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        final SCAPIAuthProvider provider = new SCAPIAuthProvider();

        Test.setMock(HttpCalloutMock.class, new ScapiMockService(jsonGoodToken,200));

        final Map<String,String> queryParams = new Map<String, String>();
        queryParams.put('code', 'code');
        queryParams.put('state', STATE);

        final Auth.AuthProviderCallbackState cbState = new Auth.AuthProviderCallbackState(null,null,queryParams);
        final Auth.AuthProviderTokenResponse actualAuthProvResponse = provider.handleCallback(authProviderConfiguration, cbState);
        final Auth.AuthProviderTokenResponse expectedAuthProvResponse = new Auth.AuthProviderTokenResponse(PROVIDER_NAME, ACCESS_TOKEN, SECRET, STATE);

        System.assertEquals(expectedAuthProvResponse.provider, actualAuthProvResponse.provider);
        System.assertEquals(expectedAuthProvResponse.oauthToken, actualAuthProvResponse.oauthToken);
        System.assertEquals(expectedAuthProvResponse.state, actualAuthProvResponse.state);
    }

    @IsTest
    static void testRefresh() {
        final Map<String, String> config = setupAuthProviderConfig();
        final SCAPIAuthProvider provider = new SCAPIAuthProvider();

        Test.setMock(HttpCalloutMock.class, new ScapiMockService(jsonGoodToken,200));

        final Auth.OAuthRefreshResult actual = provider.refresh(config,'myUnusedRefreshToken');
        final Auth.OAuthRefreshResult expected = new Auth.OAuthRefreshResult(ACCESS_TOKEN, TOKEN_TYPE);

        System.assertEquals(expected.accessToken, actual.accessToken);
        System.assertEquals(expected.refreshToken, actual.refreshToken);
        System.assertEquals(expected.error, actual.error);
    }

    @IsTest
    static void testGetUserInfo() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        final SCAPIAuthProvider provider = new SCAPIAuthProvider();

        Test.setMock(HttpCalloutMock.class, new ScapiMockService(jsonGoodToken,200));

        Auth.AuthProviderTokenResponse response = new Auth.AuthProviderTokenResponse(PROVIDER_NAME, ACCESS_TOKEN ,'sampleOauthSecret', STATE);
        Auth.UserData actualUserData = provider.getUserInfo(authProviderConfiguration, response) ;

        Map<String,String> provMap = new Map<String,String>();
        provMap.put('key1', 'value1');
        provMap.put('key2', 'value2');

        final Auth.UserData expectedUserData = new Auth.UserData(
                null, // identifier
                null, // firstName
                null, // lastName
                null,  // fullName
                null, // email
                null, // link
                null, // userNAme
                null,  // locale
                PROVIDER_NAME,  // provider
                null, // siteLoginUrl
                new Map<String, String>());

        System.assertNotEquals(actualUserData, null);
        System.assertEquals(expectedUserData.firstName, actualUserData.firstName);
        System.assertEquals(expectedUserData.lastName, actualUserData.lastName);
        System.assertEquals(expectedUserData.fullName, actualUserData.fullName);
        System.assertEquals(expectedUserData.email, actualUserData.email);
        System.assertEquals(expectedUserData.username, actualUserData.username);
        System.assertEquals(expectedUserData.locale, actualUserData.locale);
        System.assertEquals(expectedUserData.provider, actualUserData.provider);
        System.assertEquals(expectedUserData.siteLoginUrl, actualUserData.siteLoginUrl);
    }

    @IsTest
    static void testTokenMembers() {
        SCAPIAuthProvider.TokenResponse resp = (SCAPIAuthProvider.TokenResponse) JSON.deserialize(jsonGoodToken, SCAPIAuthProvider.TokenResponse.class);

        System.AssertEquals('gv6iCx48OaH76ufiGXBUlRTRTXxx', resp.access_token);
        System.AssertEquals('sfcc.customerlists.rw', resp.scope);
        System.AssertEquals('Bearer', resp.token_type);
        System.AssertEquals('1799', resp.expires_in);
    }

    @IsTest
    static void testErrorBad() {
        SCAPIAuthProvider.TokenResponse resp = (SCAPIAuthProvider.TokenResponse) JSON.deserialize(jsonError1, SCAPIAuthProvider.TokenResponse.class);
        System.AssertEquals('Grant type is not set', resp.error_description);
        System.AssertEquals('invalid_request', resp.error);
    }

    // Implement a mock http response generator for Apigee.
    public class ScapiMockService implements HttpCalloutMock {
        String jsonResponse;
        Integer httpCode;

        public ScapiMockService(String json, Integer code) {
            this.jsonResponse = json;
            this.httpCode = code;
        }

        public HTTPResponse respond(HTTPRequest req) {
            // Create the response
            HttpResponse res = new HttpResponse();
            res.setHeader(CONTENT_TYPE_HEADER, CONTENT_TYPE_JSON);
            res.setBody(jsonResponse);
            res.setStatusCode(this.httpCode);
            return res;
        }
    }
}
