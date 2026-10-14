CLASS lhc_zcds_vendor_paymentrap DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR VendorPayment RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR VendorPayment RESULT result.

    METHODS proceed FOR MODIFY
      IMPORTING keys FOR ACTION VendorPayment~proceed RESULT result.

    METHODS refresh FOR MODIFY
      IMPORTING keys FOR ACTION VendorPayment~refresh.





    CONSTANTS:
      gc_cpi_url_vendor_paym TYPE string VALUE
        'https://sona-dev-3eio9v2r.it-cpi021-rt.cfapps.in30.hana.ondemand.com/http/HDFC/Vendor_Paym',
      " ^ URL looked truncated originally - confirm the full CPI path before transport.
      gc_login_id   TYPE char40 VALUE 'APIUSER@CBXMGRT4',   " TODO: move to constant/customizing, not hardcode
      gc_input_gcif TYPE char40 VALUE 'CBXMGRT4'.

    TYPES: BEGIN OF ty_cpi_response,
             cbx_api_ref_no TYPE string,
             transaction    TYPE string,
           END OF ty_cpi_response.

    METHODS:
      build_payload
        IMPORTING is_paym        TYPE zvendor_payment
        RETURNING VALUE(rv_json) TYPE string,

      send_to_cpi
        IMPORTING iv_payload     TYPE string
        RETURNING VALUE(rs_resp) TYPE ty_cpi_response,

      refresh_from_proposal
        RAISING cx_static_check.

ENDCLASS.


CLASS lhc_zcds_vendor_paymentrap IMPLEMENTATION.

  METHOD get_instance_features.

    READ ENTITIES   OF zcds_vendor_paymentrap IN LOCAL MODE
      ENTITY VendorPayment
      FIELDS ( status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_paym).

    result = VALUE #( FOR ls_paym IN lt_paym
      ( %tky            = ls_paym-%tky
        %action-proceed = COND #( WHEN ls_paym-status = 'S'
                                   THEN if_abap_behv=>fc-o-disabled
                                   ELSE if_abap_behv=>fc-o-enabled ) ) ).

  ENDMETHOD.


  METHOD get_instance_authorizations.

    result = VALUE #( FOR ls_key IN keys
      ( %tky            = ls_key-%tky
        %action-proceed = if_abap_behv=>auth-allowed
        %update         = if_abap_behv=>auth-allowed ) ).

  ENDMETHOD.


  METHOD proceed.

    READ ENTITIES OF zcds_vendor_paymentrap IN LOCAL MODE
      ENTITY VendorPayment
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_paym).

    DATA lt_update TYPE TABLE FOR UPDATE zcds_vendor_paymentrap.

    LOOP AT lt_paym INTO DATA(ls_paym).

      IF ls_paym-status = 'S'.
        APPEND VALUE #( %tky = ls_paym-%tky %param = ls_paym ) TO result.
        CONTINUE.
      ENDIF.

      DATA(ls_db) = VALUE zvendor_payment(
        payment_ref_no         = ls_paym-PaymentRefNo
        login_id                = ls_paym-LoginId
        input_gcif               = ls_paym-InputGcif
        transfer_type_desc       = ls_paym-TransferTypeDesc
        bene_bank                = ls_paym-BeneBank
        input_debit_amount       = ls_paym-InputDebitAmount
        input_value_date         = ls_paym-InputValueDate
        transaction_type         = ls_paym-TransactionType
        input_debit_org_acc_no   = ls_paym-InputDebitOrgAccNo
        input_business_prod      = ls_paym-InputBusinessProd
        bene_id                  = ls_paym-BeneId
        bene_acc_name            = ls_paym-BeneAccName
        bene_acc_no              = ls_paym-BeneAccNo
        bene_type                = ls_paym-BeneType
        bene_branch              = ls_paym-BeneBranch
        bene_idn_code            = ls_paym-BeneIdnCode
        paymentrunid             = ls_paym-paymentrunid
         ).

      DATA(lv_json)     = build_payload( ls_db ).
      DATA(ls_cpi_resp) = send_to_cpi( iv_payload = lv_json ).

      DATA(lv_status)  = COND #( WHEN ls_cpi_resp-transaction = 'Accepted' THEN 'S' ELSE 'E' ).
      DATA(lv_message) = COND #( WHEN lv_status = 'E' THEN ls_cpi_resp-transaction ELSE '' ).

      APPEND VALUE #(
        %tky                        = ls_paym-%tky
*        %update                     = if_abap_behv=>mk-on
        CbxApiRefNo                 = ls_cpi_resp-cbx_api_ref_no
        %control-CbxApiRefNo        = if_abap_behv=>mk-on
        TransactionStatus           = ls_cpi_resp-transaction
        %control-TransactionStatus  = if_abap_behv=>mk-on
        status                      = lv_status
        %control-status             = if_abap_behv=>mk-on
        message                     = lv_message
        %control-message            = if_abap_behv=>mk-on
        LocalLastChangedAt          = utclong_current( )
        %control-LocalLastChangedAt = if_abap_behv=>mk-on
      ) TO lt_update.

    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zcds_vendor_paymentrap IN LOCAL MODE
        ENTITY VendorPayment
        UPDATE FIELDS ( CbxApiRefNo TransactionStatus status message LocalLastChangedAt )
        WITH lt_update
        REPORTED DATA(ls_reported).
    ENDIF.

    READ ENTITIES OF zcds_vendor_paymentrap IN LOCAL MODE
      ENTITY VendorPayment
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_final).

    result = VALUE #( FOR ls_final IN lt_final
                       ( %tky = ls_final-%tky %param = ls_final ) ).

  ENDMETHOD.


  METHOD refresh.

    TRY.
        refresh_from_proposal( ).
      CATCH cx_static_check INTO DATA(lx_error).
        " optionally propagate as a global message via `reported`
    ENDTRY.

  ENDMETHOD.


  METHOD build_payload.

    rv_json = |\{| &&
      |"LOGIN_ID":"{ is_paym-login_id }",| &&
      |"INPUT_GCIF":"{ is_paym-input_gcif }",| &&
      |"TRANSFER_TYPE_DESC":"{ is_paym-transfer_type_desc }",| &&
      |"BENE_BANK":"{ is_paym-bene_bank }",| &&
      |"INPUT_DEBIT_AMOUNT":"{ is_paym-input_debit_amount NUMBER = RAW }",| &&
      |"INPUT_VALUE_DATE":"{ is_paym-input_value_date }",| &&
      |"TRANSACTION_TYPE":"{ is_paym-transaction_type }",| &&
      |"INPUT_DEBIT_ORG_ACC_NO":"{ is_paym-input_debit_org_acc_no }",| &&
      |"INPUT_BUSINESS_PROD":"{ is_paym-input_business_prod }",| &&
      |"BENE_ID":"{ is_paym-bene_id }",| &&
      |"BENE_ACC_NAME":"{ is_paym-bene_acc_name }",| &&
      |"BENE_ACC_NO":"{ is_paym-bene_acc_no }",| &&
      |"BENE_TYPE":"{ is_paym-bene_type }",| &&
      |"BENE_BRANCH":"{ is_paym-bene_branch }",| &&
      |"BENE_IDN_CODE":"{ is_paym-bene_idn_code }",| &&
      |"PAYMENT_REF_NO":"{ is_paym-payment_ref_no }"| &&
      |\}|.

  ENDMETHOD.


  METHOD send_to_cpi.

    DATA: lv_resp_text TYPE string.

    TRY.
        DATA(lo_dest)   = cl_http_destination_provider=>create_by_url( gc_cpi_url_vendor_paym ).
        DATA(lo_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
        DATA(lo_req)    = lo_client->get_http_request( ).

        lo_req->set_authorization_basic(
          i_username = 'sb-2ebb3ed6-7f49-4052-9116-545a8822b16e!b37983|it-rt-sona-dev-3eio9v2r!b148'      " pull from destination/SECSTORE, don't hardcode
          i_password = '395d6919-d323-4730-a7d8-00376572a361$tokCb8L4xqxdCAFefFKrQnVOwW9aI1mNXdmyQyMI70g=' ).
        lo_req->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).
        lo_req->set_text( iv_payload ).

        DATA(lo_resp)   = lo_client->execute( if_web_http_client=>post ).
        DATA(ls_status) = lo_resp->get_status( ).
        lv_resp_text     = lo_resp->get_text( ).

        lo_client->close( ).

        IF ls_status-code = 200 OR ls_status-code = 204.
          /ui2/cl_json=>deserialize(
            EXPORTING json = lv_resp_text
            CHANGING  data = rs_resp ).
        ELSE.
          rs_resp-transaction = |HTTP_{ ls_status-code }|.
        ENDIF.

      CATCH cx_static_check INTO DATA(lx_error).
        rs_resp-transaction = lx_error->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD refresh_from_proposal.

    DATA(lv_date) = sy-datum.

    SELECT * FROM i_paymentproposalpayment
      WHERE postingdate = @lv_date
      INTO TABLE @DATA(lt_paym).

    DATA: lt_log TYPE STANDARD TABLE OF zvendor_payment,
          ls_log TYPE zvendor_payment.

    SELECT * FROM zvendor_payment INTO TABLE @DATA(lt_existing).

    LOOP AT lt_paym INTO DATA(ls_paym).

      READ TABLE lt_existing TRANSPORTING NO FIELDS
        WITH KEY payment_ref_no = ls_paym-paymentdocument.
      IF sy-subrc <> 0.

        DATA(lv_date_fmt) =
          |{ ls_paym-postingdate+6(2) }/{ ls_paym-postingdate+4(2) }/{ ls_paym-postingdate+0(4) }|.
        DATA(lv_street) = |{ ls_paym-payeestreet } { ls_paym-streetaddressname }|. " TODO verify - may need address assoc.

        CLEAR ls_log.
        ls_log-payment_ref_no         = ls_paym-paymentdocument.
        ls_log-login_id               = gc_login_id.
        ls_log-input_gcif             = gc_input_gcif.
        ls_log-transfer_type_desc     = 'NEFT'.
        ls_log-bene_bank              = ls_paym-payeebankkey.
        ls_log-input_debit_amount     = ls_paym-paytamountincocodecurrency.
        ls_log-input_value_date       = lv_date_fmt.
        ls_log-transaction_type       = 'SINGLE'.
        ls_log-input_debit_org_acc_no = ls_paym-bankaccount.
        ls_log-input_business_prod    = 'VENDBUS01'.
        ls_log-bene_id                = ls_paym-supplier.
        ls_log-bene_acc_name          = ls_paym-payeename.
        ls_log-paymentrunid          = ls_paym-PaymentRunID.
        ls_log-bene_acc_no            = ls_paym-payeebankaccount.
        ls_log-bene_type              = 'ADHOC'.
        ls_log-bene_branch            = lv_street.
        ls_log-bene_idn_code          = ls_paym-payeebankkey.
        ls_log-status                 = 'N'.
        ls_log-local_last_changed_at  = utclong_current( ).

        APPEND ls_log TO lt_log.

      ENDIF.

    ENDLOOP.

    IF lt_log IS NOT INITIAL.
      MODIFY zvendor_payment FROM TABLE @lt_log.
      IF sy-subrc = 0.
*        COMMIT WORK.
      ENDIF.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
