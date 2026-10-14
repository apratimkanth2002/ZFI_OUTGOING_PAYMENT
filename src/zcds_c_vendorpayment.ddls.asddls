//  @AbapCatalog.viewEnhancementCategory: [#NONE]
//    @EndUserText.label: 'Projection View for Vendor Payment'
//    @AccessControl.authorizationCheck: #NOT_REQUIRED
//    @Metadata.allowExtensions: true
//    @UI.headerInfo: {
//        typeName: 'Vendor Payment',
//        typeNamePlural: 'Vendor Payments',
//        title: { type: #STANDARD, value: 'PaymentRefNo' },
//        description: { type: #STANDARD, value: 'PaymentRefNo' }
//    }
//   
//define root view entity ZCDS_C_VENDORPAYMENT as projection on  ZCDS_Vendor_PaymentRAP
//{
//@UI.lineItem: [{ position: 1, label: 'Login ID' }]
//key LoginId,
//
//@UI.lineItem: [{ position: 10, label: 'Company Code' }]
//key InputGcif,
//
//@UI.lineItem: [{ position: 20, label: 'Transfer Type' }]
//TransferTypeDesc,
//
//@UI.lineItem: [{ position: 30, label: 'Beneficiary Bank' }]
//BeneBank,
//
//@UI.lineItem: [{ position: 40, label: 'Debit Amount' }]
//InputDebitAmount,
//
//@UI.lineItem: [{ position: 50, label: 'Value Date' }]
//InputValueDate,
//
//@UI.lineItem: [{ position: 60, label: 'Transaction Type' }]
//TransactionType,
//
//@UI.lineItem: [{ position: 70, label: 'Debit Account No.' }]
//InputDebitOrgAccNo,
//
//@UI.lineItem: [{ position: 80, label: 'Business Product' }]
//InputBusinessProd,
//
//@UI.lineItem: [{ position: 90, label: 'Beneficiary ID' }]
//BeneId,
//
//@UI.lineItem: [{ position: 100, label: 'Beneficiary Account Name' }]
//BeneAccName,
//
//@UI.lineItem: [{ position: 110, label: 'Beneficiary Account No.' }]
//BeneAccNo,
//
//@UI.lineItem: [{ position: 120, label: 'Beneficiary Type' }]
//BeneType,
//
//@UI.lineItem: [{ position: 130, label: 'Beneficiary Branch' }]
//BeneBranch,
//
//@UI.lineItem: [{ position: 140, label: 'Beneficiary IFSC/IDN Code' }]
//BeneIdnCode,
//
//@UI.lineItem: [{ position: 150, label: 'Payment Reference No.' }]
//PaymentRefNo,
//
//@UI.lineItem: [{ position: 160, label: 'Response API.' }]
//CbxApiRefNo,
//@UI.lineItem: [{ position: 170, label: 'Transaction Status' }]
//TransactionStatus,
//@UI.lineItem: [{ position: 180, label: 'Status' }]
//Status,
//@UI.lineItem: [{ position: 190, label: 'Message' }]
//Message,
//@UI.lineItem: [{ position: 200, label: 'Local Last Changed At' }]
//LocalLastChangedAt
//   
//}




@EndUserText.label: 'Vendor Payment Proposals'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@UI: {
  headerInfo: {
    typeName: 'Vendor Payment',
    typeNamePlural: 'Vendor Payments',
    title: { type: #STANDARD, value: 'BeneAccName' }
  },
  presentationVariant: [{ sortOrder: [{ by: 'PaymentRefNo', direction: #DESC }] }]
}
define root view entity ZCDS_C_VENDORPAYMENT
  provider contract transactional_query
  as projection on ZCDS_Vendor_PaymentRAP as VendorPayment
{


   key PaymentRefNo,
   key BeneId,
   key BeneAccNo,
   key LoginId,
   key InputGcif,
   TransferTypeDesc,
   BeneBank,
   InputDebitAmount,
   InputValueDate,
   TransactionType,
   InputDebitOrgAccNo,
   InputBusinessProd,
   BeneAccName,
   BeneType,
   BeneBranch,
   BeneIdnCode,
   CbxApiRefNo,
   TransactionStatus,
   paymentrunid,
   Status,
   StatusCriticality,
   Message,
   LocalLastChangedAt
//  @UI.lineItem: [{hidden: true}]
//   key      LoginId,
//   @UI.lineItem: [{hidden: true}]
//   key     InputGcif,
//     @UI.lineItem: [ { position: 10 } ]
//     PaymentRefNo,
//
//      @UI.lineItem: [ { position: 20 } ]
//      BeneAccName,
//
//      @UI.lineItem: [ { position: 30 } ]
//      BeneAccNo,
//
//      @UI.lineItem: [ { position: 40 } ]
//      InputDebitAmount,
//
//      @UI.lineItem: [ { position: 50 } ]
//      InputValueDate,
//
//      @UI.lineItem: [ { position: 60, criticality: 'Status' } ]
//     
//      Status,
//
//      @UI.lineItem: [ { position: 70 } ]
//      TransactionStatus,
//
//      @UI.lineItem: [ { position: 80 } ]
//      CbxApiRefNo,
//
//      @UI.lineItem: [ { position: 130, type: #FOR_ACTION, dataAction: 'VendorPayment.proceed', label: 'Proceed' } ]
//      @UI.hidden: true
//
////      case Status
////        when 'S' then 3  
////        when 'E' then 1  
////        else 2           
////      end as statusCriticality,
//
//  //    login_id,
//  //    input_gcif,
//      TransferTypeDesc,
//      BeneBank,
//      TransactionType,
//      InputDebitOrgAccNo,
//      InputBusinessProd,
//      BeneId,
//      BeneType,
//      BeneBranch,
//      BeneIdnCode,
//      Message,
//      LocalLastChangedAt
}
