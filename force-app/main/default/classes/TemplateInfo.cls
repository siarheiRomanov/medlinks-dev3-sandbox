public with sharing class TemplateInfo {
    @AuraEnabled
    public String id {get; set;}
    @AuraEnabled
    public String title {get; set;}
    @AuraEnabled
    public String createdDate {get; set;}
    @AuraEnabled
    public String docType {get; set;}
    @AuraEnabled
    public String docSize {get; set;}
    @AuraEnabled
    public String url {get; set;}
}