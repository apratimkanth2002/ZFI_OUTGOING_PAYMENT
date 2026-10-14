@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View Vendor Payment Posting'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZCDS_Vendor_PaymentRAP as select from zvendor_payment

{
  key payment_ref_no as PaymentRefNo,
  key bene_id as BeneId,
  key bene_acc_no as BeneAccNo,
  key login_id as LoginId,
  key input_gcif as InputGcif,
  transfer_type_desc as TransferTypeDesc,
  bene_bank as BeneBank,
  input_debit_amount as InputDebitAmount,
  input_value_date as InputValueDate,
  transaction_type as TransactionType,
  input_debit_org_acc_no as InputDebitOrgAccNo,
  input_business_prod as InputBusinessProd,
  bene_acc_name as BeneAccName,
  bene_type as BeneType,
  bene_branch as BeneBranch,
  bene_idn_code as BeneIdnCode,
  cbx_api_ref_no as CbxApiRefNo,
  transaction_status as TransactionStatus,
  status as Status,
  paymentrunid,
   case status
     when 'S' then 3   
     when 'E' then 1   
     else 2            
   end as StatusCriticality,
  message as Message,
  local_last_changed_at as LocalLastChangedAt   
   
}
