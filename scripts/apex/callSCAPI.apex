HttpRequest req = new HttpRequest();
String orgId = 'f_ecom_abcd_001';
String siteId = 'RefArch';
String customerNo = '00000001';
req.setEndpoint('callout:Salesforce_Commerce_API/customer/customers/v1/organizations/' + orgId + '/customer-lists/' + siteId + '/customers/' + customerNo);
req.setMethod('GET');
Http http = new Http();
HTTPResponse res = http.send(req);
System.debug(res.getBody());
