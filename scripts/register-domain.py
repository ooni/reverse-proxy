import argparse

import boto3

CONTACT_INFO = {
    'FirstName': 'Arturo',
    'LastName': 'Filastò',
    'ContactType': 'ASSOCIATION',
    'OrganizationName': 'Open Observatory of Network Interference (OONI)',
    'AddressLine1': 'Via Ostiense 131L',
    'AddressLine2': 'string',
    'City': 'Roma',
    'State': 'RM',
    'CountryCode': 'IT',
    'ZipCode': '00154',
    'PhoneNumber': '+39.338123456',
    'Email': 'admin@ooni.org',
    'Fax': '',
    'ExtraParams': []
}

def parse_args():
    parser = argparse.ArgumentParser(prog='register-domain', description='Register a domain name using route53')
    parser.add_argument('fqdn')
    parser.add_argument('--auto-renew', action='store_true')
    return parser.parse_args()

def main():
    args = parse_args()
    client = boto3.client('route53domains', region_name='us-east-1')

    response = client.register_domain(
        DomainName=args.fqdn,
        DurationInYears=1,
        AutoRenew=args.auto_renew,
        AdminContact=CONTACT_INFO,
        RegistrantContact=CONTACT_INFO,
        TechContact=CONTACT_INFO,
        BillingContact=CONTACT_INFO,
        PrivacyProtectAdminContact=True,
        PrivacyProtectRegistrantContact=True,
        PrivacyProtectTechContact=True,
        PrivacyProtectBillingContact=True
    )
    print(response)

if __name__ == "__main__":
    main()
