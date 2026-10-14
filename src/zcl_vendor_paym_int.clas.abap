CLASS zcl_vendor_paym_int DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES: if_oo_adt_classrun,
                if_apj_dt_exec_object,
                if_apj_rt_exec_object.


  PROTECTED SECTION.
  PRIVATE SECTION.


    METHODS:
      process_payment_proposal
        RAISING cx_static_check .


ENDCLASS.



CLASS ZCL_VENDOR_PAYM_INT IMPLEMENTATION.


  METHOD process_payment_proposal.

    DATA(lv_date) = sy-datum.

    SELECT * FROM i_paymentproposalpayment
      WHERE postingdate = @lv_date AND PaymentRunIsProposal <> 'X'
      INTO TABLE @DATA(lt_paym) .

    DATA: lt_log TYPE STANDARD TABLE OF zvendor_payment,
          ls_log TYPE zvendor_payment.

    SELECT * FROM zvendor_payment INTO TABLE @DATA(lt_existing).

    LOOP AT lt_paym INTO DATA(ls_paym).

      " --- field mapping (per your table comments) ---
      DATA(lv_amt) = |{ ls_paym-paytamountincocodecurrency }|.          " TODO verify field name
      DATA(lv_date_fmt) =
        |{ ls_paym-postingdate+6(2) }/{ ls_paym-postingdate+4(2) }/{ ls_paym-postingdate+0(4) }|.

      DATA(lv_street) = |{ ls_paym-payeestreet } { ls_paym-streetaddressname }|. " TODO verify - may need address assoc.

*      DATA(lv_json) = |\{| &&
*        |"LOGIN_ID":"{ gc_login_id }",| &&
*        |"INPUT_GCIF":"{ gc_input_gcif }",| &&
*        |"TRANSFER_TYPE_DESC":"NEFT",| &&
*        |"BENE_BANK":"{ ls_paym-payeebankkey }",| &&
*        |"INPUT_DEBIT_AMOUNT":"{ lv_amt }",| &&
*        |"INPUT_VALUE_DATE":"{ lv_date_fmt }",| &&
*        |"TRANSACTION_TYPE":"SINGLE",| &&
*        |"INPUT_DEBIT_ORG_ACC_NO":"{ ls_paym-bankaccount }",| &&
*        |"INPUT_BUSINESS_PROD":"VENDBUS01",| &&
*        |"BENE_ID":"{ ls_paym-supplier }",| &&
*        |"BENE_ACC_NAME":"{ ls_paym-payeename }",| &&
*        |"BENE_ACC_NO":"{ ls_paym-payeebankaccount }",| &&
*        |"BENE_TYPE":"ADHOC",| &&
*        |"BENE_BRANCH":"{ lv_street }",| &&
*        |"BENE_IDN_CODE":"{ ls_paym-payeebankkey }",| &&
*        |"PAYMENT_REF_NO":"{ ls_paym-paymentdocument }"| &&
*        |\}|.

      " skip if already logged for this payment doc - adjust key check once payment_ref_no is in the table key
      READ TABLE lt_existing INTO DATA(ls_exist)
        WITH KEY payment_ref_no = ls_paym-paymentdocument.
      IF sy-subrc <> 0.

*        DATA(ls_cpi_resp) = send_to_cpi( iv_payload = lv_json ).

        ls_log-login_id               = 'APIUSER@CBXMGRT4'.
        ls_log-input_gcif             = 'CBXMGRT4'.
        ls_log-transfer_type_desc     = 'NEFT'.
        ls_log-bene_bank              = ls_paym-payeebankkey.
        ls_log-input_debit_amount     = ls_paym-paytamountincocodecurrency.
        ls_log-input_value_date       = lv_date_fmt.
        ls_log-transaction_type       = 'SINGLE'.
        ls_log-input_debit_org_acc_no = ls_paym-bankaccount.
        ls_log-input_business_prod    = 'VENDBUS01'.
        ls_log-bene_id                = ls_paym-supplier.
        ls_log-bene_acc_name          = ls_paym-payeename.
        ls_log-bene_acc_no            = ls_paym-payeebankaccount.
        ls_log-bene_type              = 'ADHOC'.
        ls_log-bene_branch            = lv_street.
        ls_log-bene_idn_code          = ls_paym-payeebankkey.
        ls_log-payment_ref_no         = ls_paym-paymentdocument.
        ls_log-paymentrunid         = ls_paym-PaymentRunID.
*        ls_log-cbx_api_ref_no         = ls_cpi_resp-cbx_api_ref_no.
*        ls_log-transaction_status     = ls_cpi_resp-transaction.

        APPEND ls_log TO lt_log.

      ENDIF.

    ENDLOOP.

    IF lt_log IS NOT INITIAL.
      MODIFY zvendor_payment FROM TABLE @lt_log.
      IF sy-subrc = 0.
        COMMIT WORK.
      ENDIF.
    ENDIF.

    data(datetoday) = |{ lv_date+6(2) }/{ lv_date+4(2) }/{ sy-datum+0(4) }| .
*    DATA(datetoday) = |{ sy-datum+6(2) }/{ sy-datum+4(2) }/{ sy-datum+0(4) }|.



    SELECT * from zvendor_payment   where
*   cbx_api_ref_no = '' AND transaction_status = '' AND
    status = '' and input_value_date ne @datetoday into table @data(it_latest).
    if sy-subrc = 0 .

    DELETE zvendor_payment from TABLE @it_latest .
    COMMIT work .
    endif.




  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    DATA: application_log           TYPE REF TO if_bali_log,
          application_log_free_text TYPE REF TO if_bali_free_text_setter.
    TRY.
        process_payment_proposal( ).

        application_log = cl_bali_log=>create_with_header(
          header = cl_bali_header_setter=>create( object    = 'XYZ'
                                                   subobject = 'INSERT' ) ).
        application_log_free_text = cl_bali_free_text_setter=>create(
          severity = if_bali_constants=>c_severity_information
          text     = 'Vendor payment payload sent to CPI successfully.' ).

        application_log->add_item( item = application_log_free_text ).
        cl_bali_log_db=>get_instance( )->save_log(
          log                        = application_log
          assign_to_current_appl_job = abap_true ).

      CATCH cx_root INTO DATA(lx_error).
    ENDTRY.
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
*    process_payment_proposal( ).
  ENDMETHOD.
ENDCLASS.
