@isTest
public class MapcontainerControllerTest {
    @isTest
    static void getAccountDetails(){
        Account accRec = UtilityTest.createAccRec('TestName');
        Account acc = new Account();
        acc.id = accRec.Id;
        acc.BillingStreet='Panduranga Nagar';
        acc.BillingCity ='Banglore';
        acc.BillingState = 'KA';
        acc.BillingPostalCode = '560076';
        acc.BillingCountry = 'IN';
        update acc;
        Test.startTest();
        MapcontainerController.getAccountDetails(acc.Id);
        MapcontainerController.mytest();
        Test.stopTest();
    }
    
    @isTest
    static void testGoogleMapReverseGeocodeCallout(){
        Test.startTest();
        // Test.setMock(HttpCalloutMock.class, new GoogleMapReverseGeocodeMock());
        String testlat = '37.7749';
        String testlng = '-122.4194';
        MapcontainerController.GoogleMapReverseGeocodeCallout(testLat, testLng);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String result = MapcontainerController.GoogleMapReverseGeocodeCallout(testlat, testlng);
        
        Test.stopTest();
    }
    
    // Mock HTTP response generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"results": [{"formatted_address": "Expected Address"}]}');
            return response;
        }
    }
}