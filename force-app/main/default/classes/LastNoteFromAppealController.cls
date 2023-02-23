public with sharing class LastNoteFromAppealController {
    public String currentAppealId { get; set; }

    public LastNoteFromAppealController() { }

    public List<Note> getNotes() {
        return [
            SELECT   Title, Body, CreatedDate
            FROM     Note
            WHERE    ParentId = :currentAppealId
            ORDER BY CreatedDate DESC
            LIMIT    1
        ];
    }
}