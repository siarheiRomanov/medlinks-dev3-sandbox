import {LightningElement, api} from 'lwc';

export default class ProgressContainer extends LightningElement {
    @api stepNumber;

    progressSteps = [
        {stepNumber: 1, stepName: '1. DOCX initialization',},
        {stepNumber: 2, stepName: '2. Fill in DOCX',},
        {stepNumber: 3, stepName: '3. Create attach',},
        {stepNumber: 4, stepName: '4. Convert to PDF',},
        {stepNumber: 5, stepName: '5. Save PDF',},
    ];

}