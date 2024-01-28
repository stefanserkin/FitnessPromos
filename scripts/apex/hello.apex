// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents


TRecManualAdjustmentWrapper wrapper = new TRecManualAdjustmentWrapper();
wrapper.accountId = contact.AccountId;
wrapper.contactId = contact.Id;
wrapper.amount    = 29.00;
wrapper.glCode    = membershipTypeGlCode;
wrapper.type      = 'Credit';

TRecManualAdjustmentService service = new TRecManualAdjustmentService(
    new List<TRecManualAdjustmentWrapper>{ wrapper }
);
service.createAdjustments();


