*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Run keywords
...             Enable RD2
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

*** Keywords ***

Setup Test Data
        [Documentation]     Data setup needed for the testcase. Creates a recurring
        ...                 donation of type open linked to a contact using backend API
        ${NS} =             Get NPSP Namespace Prefix
        Set Suite Variable  ${NS}

        #Create a Recurring Donation
        &{contact1_fields}=             Create Dictionary           Email=rd2tester@example.com
        &{recurringdonation_fields} =	Create Dictionary           Name=ERD With Manual Donation
        ...                                                         npe03__Installment_Period__c=Yearly
        ...                                                         npe03__Amount__c=100
        ...                                                         npe03__Open_Ended_Status__c=Open
        ...                                                         npe03__Date_Established__c=2019-07-08
        ...                                                         ${NS}Status__c=Active
        ...                                                         ${NS}Day_of_Month__c=20
        ...                                                         ${NS}InstallmentFrequency__c=1
        ...                                                         ${NS}PaymentMethod__c=Check

        Setupdata   contact         ${contact1_fields}             recurringdonation_data=${recurringdonation_fields}
        ${CURRENT_DATE}=            Get current date               result_format=%-m/%-d/%Y
        Set Suite Variable          ${CURRENT_DATE}

Validate Opportunity Details
       [Documentation]         Navigate to opportunity details page of the specified
       ...                     opportunity and validate stage and Close date fields
       [Arguments]                       ${opportunityid}          ${stage}        ${date}
       Go To Page                              Details                        Opportunity                   object_id=${opportunityid}
       Navigate To And Validate Field Value    Stage                          contains                      ${stage}
       Navigate To And Validate Field Value    Close Date                     contains                      ${date}

Edit Opportunity Stage
       [Documentation]         Navigate to opportunity details page of the specified
       ...                     opportunity and update the opportunity stage detail
       [Arguments]                       ${opportunityid}          ${stage}
       Go To Page                              Details                        Opportunity                     object_id=${opportunityid}
       Wait Until Loading Is Complete
       Current Page Should be                  Details                        Opportunity
       Click Link                              link=Edit
       Wait until Modal Is Open
       Select Value From Dropdown              Stage                          ${stage}
       Click Modal Button                      Save

Create An Opportunity Related to Recurring Donation
       [Documentation]         Create a manual related opportunity from the
       ...                     Recurring Donation's opportunity related list
       [Arguments]                       ${rd_id}                            ${Stage_Type}
       Go To Recurring Donation Related Opportunities Page                   ${rd_id}
       Wait Until Loading Is Complete
       Click Object Button                     New
       Select Record Type                      Donation
       Wait For Modal                          New                       Opportunity: Donation
       # Create a new Opportunity from the UI
       Populate Modal Form
       ...                                     Opportunity Name=Manual Opportunity
       ...                                     Account Name=${data}[contact][LastName] Household
       ...                                     Amount=25
       ...                                     Do Not Automatically Create Payment=checked
       Select Value From Dropdown              Stage    ${Stage_Type}
       Open Date Picker                        Close Date
       Pick Date                               Today
       Click Modal Button                      Save
       Wait Until Modal Is Closed

*** Test Cases ***

Edit Day Of Month For Enhanced Recurring donation record of type open with a manual opportunity
    [Documentation]               After creating an open recurring donation using API,
     ...                          The test ensures that there is only one opportunity.
     ...                          Creates a new manual opportunity. Edits the day of month
     ...                          on the Recurring donation object and verifies that
     ...                          close date of the system generated opportuntiy only
     ...                          changes.


    [tags]                             unstable               W-040346            feature:RD2

    Go To Page                         Details
    ...                                npe03__Recurring_Donation__c
    ...                                object_id=${data}[contact_rd][Id]
    Wait Until Loading Is Complete
    #Validate the number of opportunities on UI, Verify Opportinity got created in the backend
    Validate Related Record Count      Opportunities                                    1
    Create An Opportunity Related to Recurring Donation                    ${data}[contact_rd][Id]            Pledged
    @{opportunities} =                 API Query Opportunity For Recurring Donation     ${data}[contact_rd][Id]
    Go To Page                         Details
    ...                                npe03__Recurring_Donation__c
    ...                                object_id=${data}[contact_rd][Id]
    Current Page Should be             Details    npe03__Recurring_Donation__c
    Edit Recurring Donation Status
    ...                                Recurring Period=Monthly
    ...                                Day of Month=1
    Go To Page                         Details
    ...                                npe03__Recurring_Donation__c
    ...                                object_id=${data}[contact_rd][Id]

    Wait Until Loading Is Complete
    Reload Page
    Current Page Should Be             Details                                        npe03__Recurring_Donation__c
    ${next_payment_date}               get next payment date number                    1

    #Validate that the number of opportunities now show as 2 .
    Validate Related Record Count      Opportunities                                   2
    @{opportunity} =                   API Query Opportunity For Recurring Donation                  ${data}[contact_rd][Id]
    #Verify the details on the respective opportunities
    Validate Opportunity Details       ${opportunity}[0][Id]        Pledged                          ${next_payment_date}
    Go To Page                         Details
    ...                                npe03__Recurring_Donation__c
    ...                                object_id=${data}[contact_rd][Id]
    Validate Opportunity Details       ${opportunity}[1][Id]        Pledged                          ${CURRENT_DATE}