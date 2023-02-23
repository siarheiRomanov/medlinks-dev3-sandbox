public with sharing class AppealTokenWrapper {
    public static final String CRYPTO_KEY     = 'drFTpxI8kX+WFGQxYzLamrizxyRnLvSiL3tHVlW2E9k=';
    public static final String ALGORITHM_NAME = 'AES256';

    public Map<Id, String> contentVersionIdToHashMap {
        get {
            return contentVersionIdToHashMap;
        }
        private set {
            contentVersionIdToHashMap = value;
        }
    }

    public AppealTokenWrapper(Map<Id, String> contentVersionIdToHashMap) {
        this.contentVersionIdToHashMap = contentVersionIdToHashMap;
    }
}