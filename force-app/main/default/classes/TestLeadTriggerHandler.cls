@isTest
public with sharing class TestLeadTriggerHandler {

    static Id ownerId = UserInfo.getUserId();

    @isTest
    public static void TestTitleNormalization() {
        List<String> titles = new List<String>{
            'vp', 'v.p.', 'vice president', 
            'mgr', 'manage', 'head of department', 
            'exec', 'chief', 'head', 
            'assist', 'deputy', 'jr',
            'random'
        };
        List<Lead> leadsList = new List<Lead>();

        for (Integer i = 0; i < titles.size(); i++) {      
            // Create a new lead with a dynamic title given to it
            Lead ld = new Lead(
                LastName = 'Lead' + i,
                Company = 'Pierre Mingels Inc',
                OwnerId = ownerId,
                Title = titles[i]
            );

            leadsList.add(ld);
        }

        insert leadsList;
        
        System.assertEquals(13, leadsList.size(), 'Did not insert the correct amount of leads');

        LeadTriggerHandler.handleTitleNormalization(leadsList);

        Map<String,String> titleToExpectedMap = new Map<String, String>{
            'Vice President' => 'Vice President',
            'Manager' => 'Manager',
            'Executive' => 'Executive',
            'Assistant' => 'Assistant',
            'random' => 'random'
        };

        for (Lead lead : leadsList) {
            String expectedTitle = titleToExpectedMap.get(lead.Title);
            System.assertEquals(expectedTitle, lead.Title);
        }
    }

    @isTest
    public static void TestAutoLeadScoring() {
        List<Lead> leads = new List<Lead>{
            new Lead(
                LastName = 'Lead',
                Company = 'Pierre Mingels Inc',
                OwnerId = ownerId,
                LeadSource = 'Website',
                Email = 'mr.mingels@gmail.com'
            ),
            new Lead(
                LastName = 'Lead',
                Company = 'Pierre Mingels Inc',
                OwnerId = ownerId,
                Industry = 'Technology'
            ),
            new Lead(
                LastName = 'Lead',
                Company = 'Pierre Mingels Inc',
                OwnerId = ownerId,
                Phone = '(850) 644-4200'
            ),
            new Lead(
                LastName = 'Lead',
                Company = 'Pierre Mingels Inc',
                OwnerId = ownerId
            )
        };
        
        insert leads;

        LeadTriggerHandler.handleAutoLeadScoring(new List<Lead>{leads[0]});
        System.assertEquals(13, leads[0].Lead_Score__c);

        LeadTriggerHandler.handleAutoLeadScoring(new List<Lead>{leads[1]});
        System.assertEquals(18, leads[1].Lead_Score__c);

        LeadTriggerHandler.handleAutoLeadScoring(new List<Lead>{leads[2]});
        System.assertEquals(15, leads[2].Lead_Score__c);
        
        LeadTriggerHandler.handleAutoLeadScoring(new List<Lead>{leads[3]});
        System.assertEquals(10, leads[3].Lead_Score__c);
    }

    @isTest
    public static void TestLeadAutoConvert() {
        Account acc1 = new Account(Name = 'Company 1');
        insert acc1;

        List<Lead> leads = new List<Lead>{
            new Lead(
                LastName = 'Lead',
                Company = 'Pierre Mingels Inc',
                OwnerId = ownerId,
                IsConverted = false,
                Email = 'mr.mingels@gmail.com'
            ),
            new Lead(
                LastName = 'Lead',
                Company = 'Pierre Mingels Inc',
                OwnerId = ownerId,
                IsConverted = false,
                Email = 'pierre.mingels@gmail.com'
            ),
            new Lead(
                LastName = 'Lead',
                Company = 'Pierre Mingels Inc',
                OwnerId = ownerId,
                IsConverted = false,
                Email = 'peter.dinkle@gmail.com'
            ),
            new Lead(
                LastName = 'Lead',
                Company = 'Pierre Mingels Inc',
                OwnerId = ownerId,
                IsConverted = false,
                Email = 'nocontact@gmail.com'
            )
        };
        insert leads;

        List<Contact> contacts = new List<Contact>{
            new Contact(
                LastName = 'Contact',
                Email = 'pierre.mingels@gmail.com',
                AccountId = acc1.Id
            ),
            new Contact(
                LastName = 'Contact',
                Email = 'mr.mingels@gmail.com',
                AccountId = acc1.Id
            ),
            new Contact(
                LastName = 'Contact',
                Email = 'mr.mingels@gmail.com',
                AccountId = acc1.Id
            ),
            new Contact(
                LastName = 'Contact',
                Email = 'peter.dinkle@gmail.com',
                AccountId = acc1.Id
            )
        };
        insert contacts;

        LeadTriggerHandler.handleLeadAutoConvert(leads);

        leads = [SELECT IsConverted, Email FROM Lead WHERE Id IN :leads];
        for(Lead lead : leads) {
            // Test for the case in which there are multiple contacts with duplicate emails as the lead
            if(lead.Email == 'mr.mingels@gmail.com') {
                System.assertEquals(false, lead.IsConverted);
            }  
            // Test for when there's no contacts for a lead
            else if (lead.Email == 'nocontact@gmail.com') {
                System.assertEquals(false, lead.IsConverted);
            }
            // Test for when there's one contact with the same email as the lead
            else {
                System.assertEquals(true, lead.IsConverted);
            }
        }
    }
}