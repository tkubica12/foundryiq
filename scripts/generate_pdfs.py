#!/usr/bin/env python3
"""Generate sample PDF documents for the FoundryIQ knowledge base."""
import os
import sys

def ensure_fpdf():
    try:
        from fpdf import FPDF
        return FPDF
    except ImportError:
        os.system(f"{sys.executable} -m pip install fpdf2 --quiet")
        from fpdf import FPDF
        return FPDF

def create_pdf(FPDF, filename, title, sections):
    pdf = FPDF()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 20)
    pdf.cell(0, 15, title, new_x="LMARGIN", new_y="NEXT", align="C")
    pdf.ln(5)

    for heading, body in sections:
        pdf.set_font("Helvetica", "B", 14)
        pdf.cell(0, 10, heading, new_x="LMARGIN", new_y="NEXT")
        pdf.set_font("Helvetica", "", 11)
        pdf.multi_cell(0, 6, body)
        pdf.ln(3)

    pdf.output(filename)
    print(f"  Created: {filename}")

def main():
    FPDF = ensure_fpdf()
    out_dir = os.path.join(os.path.dirname(__file__), "..", "sample-data")
    os.makedirs(out_dir, exist_ok=True)

    # Document 1: Company IT Security Policy
    create_pdf(FPDF, os.path.join(out_dir, "it-security-policy.pdf"),
        "Contoso Corp - IT Security Policy v3.2",
        [
            ("1. Purpose", "This policy establishes the information security requirements for all Contoso Corp employees, contractors, and third-party partners. It aims to protect company assets, data, and systems from unauthorized access, disclosure, alteration, or destruction."),
            ("2. Password Requirements", "All users must use passwords with a minimum length of 14 characters, including uppercase, lowercase, numbers, and special characters. Passwords must be changed every 90 days. Multi-factor authentication (MFA) is mandatory for all accounts accessing corporate systems. Biometric authentication is recommended for privileged accounts."),
            ("3. Data Classification", "Data is classified into four levels: Public, Internal, Confidential, and Restricted. Public data may be shared freely. Internal data is for employee use only. Confidential data requires encryption at rest and in transit. Restricted data requires additional access controls, audit logging, and approval from the Data Protection Officer."),
            ("4. Network Security", "All remote access must use the corporate VPN with split tunneling disabled. Guest Wi-Fi networks are isolated from corporate networks. Network segmentation is enforced between production, development, and corporate environments. All internet traffic is inspected by the web proxy."),
            ("5. Incident Response", "Security incidents must be reported to the Security Operations Center (SOC) within 1 hour of discovery. The incident response team will classify incidents as P1 (critical), P2 (high), P3 (medium), or P4 (low). P1 incidents require executive notification within 2 hours. All incidents must be documented in the incident tracking system."),
            ("6. Device Management", "All corporate devices must be enrolled in the Mobile Device Management (MDM) system. Personal devices accessing corporate data must comply with the BYOD policy. Full disk encryption is required on all laptops and workstations. USB storage devices are blocked on corporate endpoints unless explicitly approved."),
        ])

    # Document 2: Employee Handbook
    create_pdf(FPDF, os.path.join(out_dir, "employee-handbook.pdf"),
        "Contoso Corp - Employee Handbook 2026",
        [
            ("Welcome", "Welcome to Contoso Corp! Founded in 2010, we have grown to over 5,000 employees across 12 countries. Our mission is to deliver innovative cloud solutions that empower businesses worldwide. This handbook outlines our policies, benefits, and culture."),
            ("Working Hours & Flexibility", "Standard working hours are 9:00 AM to 5:30 PM local time, Monday through Friday. We offer flexible working arrangements including hybrid work (3 days office, 2 days remote), compressed work weeks, and flextime. Core hours are 10:00 AM to 3:00 PM when all team members should be available."),
            ("Leave Policy", "Employees receive 25 days of annual leave, 10 days of sick leave, and 5 days of personal leave per year. Parental leave is 16 weeks fully paid for primary caregivers and 8 weeks for secondary caregivers. Sabbatical leave of up to 3 months is available after 5 years of service."),
            ("Benefits", "Health insurance covers medical, dental, and vision for employees and dependents. We offer a 401(k) match of up to 6% of salary. Education assistance up to $10,000 per year for job-related courses. Gym membership subsidy of $75 per month. Employee stock purchase plan at 15% discount."),
            ("Performance Reviews", "Performance reviews are conducted quarterly using the OKR (Objectives and Key Results) framework. Annual compensation reviews occur in March. Promotion cycles are in January and July. The performance rating scale is: Exceptional, Exceeds Expectations, Meets Expectations, Needs Improvement."),
            ("Code of Conduct", "All employees must act with integrity, respect, and professionalism. Harassment, discrimination, and retaliation are strictly prohibited. Conflicts of interest must be disclosed to HR. Gifts from vendors exceeding $50 in value must be reported. Insider trading is prohibited."),
        ])

    # Document 3: Cloud Architecture Standards
    create_pdf(FPDF, os.path.join(out_dir, "cloud-architecture-standards.pdf"),
        "Contoso Corp - Cloud Architecture Standards",
        [
            ("1. Overview", "These standards define the architectural patterns, practices, and governance requirements for all cloud workloads at Contoso Corp. All new deployments must comply with these standards. Existing workloads must achieve compliance within 12 months."),
            ("2. Cloud Provider Strategy", "Azure is the primary cloud provider for all production workloads. Multi-cloud deployments require Architecture Review Board (ARB) approval. All resources must be deployed using Infrastructure as Code (IaC) with Terraform or Bicep. Manual resource creation in the portal is prohibited for production environments."),
            ("3. Networking", "All production workloads must use private endpoints for PaaS services. Virtual networks must follow the hub-spoke topology. Network Security Groups (NSGs) must follow the principle of least privilege. Azure Firewall or third-party NVAs must be used for east-west traffic inspection. DNS resolution must use Azure Private DNS Zones."),
            ("4. Identity & Access", "Azure Active Directory (Entra ID) is the sole identity provider. All service-to-service authentication must use managed identities. API keys and connection strings must not be stored in application code. Key Vault must be used for secret management. Conditional Access policies enforce MFA and compliant device requirements."),
            ("5. Data Protection", "All data at rest must be encrypted using platform-managed or customer-managed keys. TLS 1.2 or higher is required for all data in transit. Azure Storage accounts must disable shared key access and use Entra ID authentication. Backup retention must be minimum 30 days for production data."),
            ("6. Monitoring & Observability", "All workloads must send logs to the central Log Analytics workspace. Application Insights must be configured for all web applications. Azure Monitor alerts must be configured for critical metrics. Cost management tags (CostCenter, Owner, Environment) are mandatory on all resources."),
            ("7. AI & ML Workloads", "AI workloads must use Azure AI Foundry for model management and deployment. All AI models must be evaluated for bias and fairness before production deployment. Content safety filters must be enabled for all generative AI deployments. Data used for AI training must be classified and handled according to the data classification policy."),
        ])

    # Document 4: Disaster Recovery Plan
    create_pdf(FPDF, os.path.join(out_dir, "disaster-recovery-plan.pdf"),
        "Contoso Corp - Disaster Recovery Plan",
        [
            ("1. Scope", "This plan covers disaster recovery procedures for all Tier-1 and Tier-2 business applications hosted in Azure. It defines Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO) for each service tier."),
            ("2. Service Tiers", "Tier-1 (Mission Critical): RTO = 1 hour, RPO = 15 minutes. Includes ERP, customer-facing APIs, and payment processing. Tier-2 (Business Important): RTO = 4 hours, RPO = 1 hour. Includes internal portals, reporting, and email. Tier-3 (Standard): RTO = 24 hours, RPO = 24 hours. Includes dev/test environments and internal tools."),
            ("3. Backup Strategy", "Azure Backup is used for VMs and databases with geo-redundant storage. SQL databases use active geo-replication to the paired region. Storage accounts use GRS (Geo-Redundant Storage) for Tier-1 data. Cosmos DB uses multi-region writes for globally distributed data. Backup verification tests are conducted monthly."),
            ("4. Failover Procedures", "Automated failover is configured for Tier-1 services using Azure Traffic Manager and Azure Front Door. Manual failover requires approval from the DR Commander and takes approximately 30 minutes. Failover runbooks are stored in Azure DevOps and tested quarterly. Communication during DR events uses the incident management channel in Microsoft Teams."),
            ("5. Testing Schedule", "Full DR drills are conducted semi-annually in April and October. Tabletop exercises are conducted quarterly. Backup restoration tests are performed monthly. Results are reported to the CTO and CISO within 5 business days."),
            ("6. Contact Information", "DR Commander: Sarah Johnson (sarah.johnson@contoso.com, +1-555-0101). Infrastructure Lead: Mike Chen (mike.chen@contoso.com, +1-555-0102). Security Lead: Priya Patel (priya.patel@contoso.com, +1-555-0103). Communications: Alex Rivera (alex.rivera@contoso.com, +1-555-0104)."),
        ])

    print(f"\nAll sample PDFs generated in: {os.path.abspath(out_dir)}")

if __name__ == "__main__":
    main()
