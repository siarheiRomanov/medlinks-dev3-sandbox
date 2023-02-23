public with sharing class GoogleDriveSaveResult {
	public GoogleDriveSaveResult() {

	}
	/**
	*
	*/
	public class Label {
		public Boolean starred {get; set;}
		public Boolean hidden {get; set;}
		public Boolean trashed {get; set;}
		public Boolean restricted {get; set;}
		public Boolean viewed {get; set;}
	}

	/**
	*
	*/
	public class Parent {
		public String kind {get; set;}
		public String id {get; set;}
		public String selfLink {get; set;}
		public String parentLink {get; set;}
		public Boolean isRoot {get; set;}
	}

	/**
	*
	*/
	public class UserPermission {
		public String kind {get; set;}
		public String etag {get; set;}
		public String id {get; set;}
		public String selfLink {get; set;}
		public String role {get; set;}
		public String type {get; set;}
	}
	/**
	*
	*/
	public class User {
		public String kind {get; set;}
		public String displayName {get; set;}
		public String permissionId {get; set;}
		public String emailAddress {get; set;}
		public Boolean isAuthenticatedUser {get; set;}
	}



	public String kind {get; set;}
	public String id {get; set;}
	public String etag {get; set;}
	public String selfLink {get; set;}
	public String webContentLink {get; set;}
	public String alternateLink {get; set;}
	public String iconLink {get; set;}
	public String title {get; set;}
	public String mimeType {get; set;}

	public String version {get; set;}
	public String downloadUrl {get; set;}
	public String originalFilename {get; set;}
	public String fileExtension {get; set;}
	public String md5Checksum {get; set;}
	public String fileSize {get; set;}
	public String quotaBytesUsed {get; set;}
	public String headRevisionId {get; set;}
	public String spaces {get; set;}

	public String lastModifyingUserName {get; set;}

	public User lastModifyingUser {get; set;}
	public UserPermission userPermission {get; set;}

	public Boolean editable {get; set;}
	public Boolean copyable {get; set;}
	public Boolean writersCanShare {get; set;}
	public Boolean shared {get; set;}
	public Boolean explicitlyTrashed {get; set;}
	public Boolean appDataContents {get; set;}
	//Date fields
	public String createdDate {get; set;}
	public String modifiedDate {get; set;}
	public String modifiedByMeDate {get; set;}
	public String lastViewedByMeDate {get; set;}
	public String markedViewedByMeDate {get; set;}

	public Label[] labels {get; set;}
	public Parent[] parents {get; set;}
	public String[] ownerNames {get; set;}
	public User[] owners {get; set;}

}