public with sharing class ePHIclass {
    
    private static string emsg = 'ePHI Settings Not Initialized';
    
    public static Boolean isInitialized(string dataset) {
        ephi__c Keys = ephi__c.getValues(dataset);
        if (Keys != null && Keys.xkey__c != null && Keys.xfill__c != null)
            return True;
        else
            return False;
    }   
    public static void Initialize(string dataset) {
        if (!ePHIclass.isInitialized(dataset)) {
            ephi__c Keys = ephi__c.getValues(dataset);
            if (Keys == null) {
            	Keys = new ephi__c(name = dataset);	// If no instance, create it...         
            }
            Blob key = Crypto.GenerateAESkey(128);
            Blob fill = Crypto.GenerateAESkey(128);
            Keys.xkey__c = EncodingUtil.Base64Encode(key);
            Keys.xfill__c = EncodingUtil.Base64Encode(fill);
            upsert Keys;    // Write it!
        }
    }
    public static string encrypt(string s, string dataset) {
        // system.assert(ePHIclass.isInitialized(dataset), emsg);                  
        ephi__c Keys = ephi__c.getValues(dataset);
        Blob b = Blob.valueof(s);
        Blob key = EncodingUtil.base64Decode(Keys.xkey__c);
        return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', key, b));        
    }
    public static string decrypt(string s, string dataset){
        // system.assert(ePHIclass.isInitialized(dataset), emsg);                  
        ephi__c Keys = ephi__c.getValues(dataset);          
        Blob key = EncodingUtil.base64Decode(Keys.xkey__c);
        Blob b = Crypto.decryptWithManagedIV('AES128', key, EncodingUtil.base64Decode(s));
        return b.tostring();
    }
    public static void genxs(string n, string[] x, string dataset){
        // system.assert(ePHIclass.isInitialized(dataset), emsg);                  
        ephi__c Keys = ephi__c.getValues(dataset);                  
        String alg = 'hmacSHA1';
        String filler = Keys.xfill__c;
        Blob k = Blob.valueof(Keys.xkey__c);        
        String n1 = n.substring(0,1).tolowercase() + filler.substring(1);
        String n2 = n.substring(0,2).tolowercase() + filler.substring(2);
        String n3 = n.substring(0,3).tolowercase() + filler.substring(3);
        String n4 = n.substring(0,4).tolowercase() + filler.substring(4);
        system.debug('n4 = ' + n4);
        Blob mac1 = Crypto.generateMac(alg, Blob.valueof(n1), k);
        Blob mac2 = Crypto.generateMac(alg, Blob.valueof(n2), k);
        Blob mac3 = Crypto.generateMac(alg, Blob.valueof(n3), k);
        Blob mac4 = Crypto.generateMac(alg, Blob.valueof(n4), k);
        x[0] = EncodingUtil.base64Encode(mac1);
        x[1] = EncodingUtil.base64Encode(mac2);
        x[2] = EncodingUtil.base64Encode(mac3);
        x[3] = EncodingUtil.base64Encode(mac4);
        system.debug('x4 = '+ x[3]);                    
    }
    public static void genx1(string n, string[] x1, integer len, string dataset){
        // system.assert(ePHIclass.isInitialized(dataset), emsg);                  
        ephi__c Keys = ephi__c.getValues(dataset);                  
        String alg = 'hmacSHA1';
        String filler = Keys.xfill__c;
        Blob k = Blob.valueof(Keys.xkey__c);        
        String n1 = n.substring(0,len).tolowercase() + filler.substring(len);
        Blob mac1 = Crypto.generateMac(alg, Blob.valueof(n1), k);
        x1[0] = EncodingUtil.base64Encode(mac1);
        system.debug('x1 = '+ x1[0]);       
    }       


    public static testMethod void ephiTest() {
        string dset = 'Test';
        // Confirm that the 'Test' custom settings object instance exists
        ephi__c Keys = ephi__c.getValues(dset);
        system.assert(Keys != null);
        // Reset the two fields to null
        Keys.XFill__c = null;
        Keys.XKey__c = null;
        update Keys;		// Update the instance (no commit)
        // Test isInitialized
        system.assert(!ePHIclass.isInitialized(dset));                  
        // Test Initialize and confirm
        ePHIclass.Initialize(dset);
        system.assert(ePHIclass.isInitialized(dset));                   
        // Test encrypt/decrypt
        string testname = 'Rice, Betty';
        string encoded = ePHIclass.encrypt(testname, dset);
        string decoded = ePHIclass.decrypt(encoded, dset);
        system.assert(decoded.equals(testname));
        // Test HMAC routines
        list<string> x = new string[4];
        list<string> x1 = new string[1];
        ePHIclass.genxs(testname, x, dset);
        system.assert(x[0].length() == 28);
        system.assert(x[1].length() == 28);
        system.assert(x[2].length() == 28);
        system.assert(x[3].length() == 28);
        system.assert(!x[0].equals(x[1]));  // Ensure they are different
        for (integer i = 1; i <= 4; i++ ) {
            ePHIclass.genx1(testname, x1, i, dset); // Generate each substring HMAC
            system.debug('i = ' + string.valueof(i)+ ' x1 = ' + x1[0]);
            system.assert(x[i-1].equals(x1[0]));        // Ensure they match the original
        }       
    }
}