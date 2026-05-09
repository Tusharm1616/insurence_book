"""
Run this script once to seed the Terms & Conditions into the database.
Usage: python patch_terms.py
"""
import asyncio
import os
import json
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import text

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL is not set")
DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

engine = create_async_engine(DATABASE_URL)
SessionLocal = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)

TERMS_CONTENT = [
    {
        "id": 1,
        "title": "Introduction",
        "icon": "info",
        "content": [
            "Welcome to InsureBook — an advanced Insurance CRM and WhatsApp Reminder Application developed for managing insurance customers, policies, reminders, follow-ups, and automated WhatsApp communication.",
            "This application provides the following core functionalities:",
            "• Insurance customer relationship management (CRM)",
            "• Policy creation, tracking, and renewal management",
            "• Automated WhatsApp reminder services for premium due dates, birthdays, anniversaries, and policy renewals",
            "• Insurance lead management and conversion tracking",
            "• Motor insurance premium calculator and quote generation",
            "• Life insurance policy reporting and analytics",
            "By accessing or using InsureBook, you agree to be bound by these Terms & Conditions. Please read them carefully before using the application."
        ]
    },
    {
        "id": 2,
        "title": "User Acceptance",
        "icon": "check_circle",
        "content": [
            "By registering, accessing, or using the InsureBook application, you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions.",
            "Key acceptance points:",
            "• Users must agree to all terms before using the application",
            "• Continued use of the app constitutes ongoing acceptance of these terms",
            "• All registered agents, administrators, and sub-users must comply with these policies",
            "• Any violation of these terms may result in account suspension or termination",
            "If you do not agree to these terms, please discontinue use of the application immediately."
        ]
    },
    {
        "id": 3,
        "title": "User Responsibilities",
        "icon": "person",
        "content": [
            "As a registered user of InsureBook, you are responsible for:",
            "• Providing accurate and truthful customer information at all times",
            "• Maintaining the confidentiality of your account credentials (username and password)",
            "• Ensuring that customer data is not misused, shared without authorization, or used for any purpose outside the scope of insurance management",
            "• Not sending unsolicited spam messages or unauthorized communications via WhatsApp or any other channel",
            "Prohibited activities include:",
            "• Creating fake or fraudulent customer entries",
            "• Unauthorized sharing of customer data with third parties",
            "• Using WhatsApp automation features for illegal, harassing, or spamming purposes",
            "• Attempting to access other users' accounts or data without proper authorization",
            "Violations may result in immediate account suspension and legal action where applicable."
        ]
    },
    {
        "id": 4,
        "title": "Customer Data & Privacy Policy",
        "icon": "shield",
        "content": [
            "InsureBook is committed to protecting the privacy and security of customer data. All personal information is handled with the utmost care and in compliance with applicable data protection regulations.",
            "Protected data includes:",
            "• Full Name and Contact Information",
            "• Mobile Number and Email Address",
            "• Policy Details (policy number, type, premium, sum assured, etc.)",
            "• Vehicle Information (registration number, make, model, etc.)",
            "• Date of Birth, Anniversary Date, and other personal identifiers",
            "Data usage policy:",
            "• Customer data is stored securely and used exclusively for insurance management services",
            "• WhatsApp numbers are used solely for sending authorized reminders and notifications",
            "• Personal information will never be sold, rented, or traded to third parties",
            "Security measures implemented:",
            "• Encrypted passwords using bcrypt hashing",
            "• Secure REST APIs with HTTPS encryption",
            "• JWT (JSON Web Token) based authentication",
            "• PostgreSQL database with secure cloud hosting",
            "• Regular security audits and vulnerability assessments"
        ]
    },
    {
        "id": 5,
        "title": "WhatsApp Reminder Consent",
        "icon": "message",
        "content": [
            "InsureBook integrates WhatsApp messaging services to provide timely and helpful reminders to customers. By using this feature, customers and agents agree to the following:",
            "Types of WhatsApp messages that may be sent:",
            "• Insurance policy expiry and renewal reminders",
            "• Premium due date alerts",
            "• Birthday and anniversary wishes",
            "• Follow-up messages for pending leads",
            "• Policy status notifications and updates",
            "• Motor insurance quote notifications",
            "Important notes:",
            "• All WhatsApp communication is powered through official WhatsApp Business API services provided by Meta",
            "• Customers have the right to opt out of WhatsApp reminders at any time by contacting their agent or using the app settings",
            "• Message delivery depends on the customer's WhatsApp availability and Meta's service uptime",
            "• InsureBook does not guarantee 100% delivery of WhatsApp messages due to external factors"
        ]
    },
    {
        "id": 6,
        "title": "Lead Management Policy",
        "icon": "trending_up",
        "content": [
            "InsureBook provides a comprehensive lead management system to help insurance agents track and convert potential customers.",
            "Lead management includes:",
            "• Leads are customer enquiries or prospects before policy purchase",
            "• Lead information (name, contact, insurance interest) is used exclusively for follow-up and sales management",
            "• Agents may contact leads via phone, WhatsApp, or email for insurance assistance and consultation",
            "Features provided:",
            "• Follow-up scheduling and tracking",
            "• CRM-based lead pipeline management",
            "• Lead conversion tracking and analytics",
            "• Automated follow-up reminders",
            "• Lead categorization (new, in-progress, converted, lost)",
            "All lead data is treated with the same privacy and security standards as customer data."
        ]
    },
    {
        "id": 7,
        "title": "Payment & Premium Disclaimer",
        "icon": "currency_rupee",
        "content": [
            "InsureBook serves as a CRM and management platform for insurance agents. Please note the following important disclaimers:",
            "• Premium amounts displayed in the app are estimates and may vary based on the insurance company's final assessment",
            "• Insurance policy approval is entirely at the discretion of the respective insurance company",
            "• InsureBook does not guarantee the approval of any insurance policy or claim",
            "• Pricing, rates, and premium calculations are subject to change without prior notice based on regulatory updates and insurance company policies",
            "• The Motor Insurance Premium Calculator provides estimated quotes only — final premium will be determined by the insurance provider",
            "InsureBook acts solely as a management and organization tool and does not serve as an insurance provider, underwriter, or financial advisor."
        ]
    },
    {
        "id": 8,
        "title": "Data Storage & Backup",
        "icon": "cloud",
        "content": [
            "InsureBook employs enterprise-grade data storage and backup practices to ensure the safety of your data.",
            "Storage infrastructure:",
            "• All data is stored securely in PostgreSQL databases hosted on cloud infrastructure",
            "• Cloud hosting is provided by reputable providers with industry-standard security certifications",
            "• Regular automated backups are performed to prevent data loss",
            "Maintenance:",
            "• System maintenance may occur periodically, during which the app may experience brief downtime",
            "• Users will be notified in advance of scheduled maintenance windows when possible",
            "• Data integrity checks are performed regularly to ensure accuracy and consistency"
        ]
    },
    {
        "id": 9,
        "title": "Account Security",
        "icon": "lock",
        "content": [
            "Account security is a shared responsibility between InsureBook and its users.",
            "User responsibilities:",
            "• Users are responsible for maintaining the security of their passwords and login credentials",
            "• Password sharing with unauthorized individuals is strictly prohibited",
            "• Any unauthorized access or suspicious activity must be reported to the InsureBook support team immediately",
            "Security features provided:",
            "• Secure login with encrypted credentials",
            "• Change password functionality available in Settings",
            "• Session-based JWT authentication with automatic token expiry",
            "• Account lockout after multiple failed login attempts",
            "• Secure logout that clears all session data"
        ]
    },
    {
        "id": 10,
        "title": "Prohibited Activities",
        "icon": "block",
        "content": [
            "The following activities are strictly prohibited while using InsureBook:",
            "• Sending spam, bulk unsolicited, or unauthorized WhatsApp messages",
            "• Uploading malicious files, viruses, or harmful content",
            "• Misusing, selling, or unauthorized sharing of customer data",
            "• Attempting to gain unauthorized access to other users' accounts, the database, or backend systems",
            "• Using the application for any illegal, fraudulent, or unethical activities",
            "• Reverse engineering, decompiling, or attempting to extract source code from the application",
            "• Creating automated bots or scripts to interact with the app without authorization",
            "Consequences:",
            "• Violation of any prohibited activity may lead to immediate account suspension",
            "• Serious violations may result in permanent account termination and legal action",
            "• InsureBook reserves the right to report illegal activities to appropriate law enforcement authorities"
        ]
    },
    {
        "id": 11,
        "title": "Limitation of Liability",
        "icon": "gavel",
        "content": [
            "InsureBook is provided as a management and organization software tool. The following limitations of liability apply:",
            "• InsureBook is not responsible for any downtime, errors, or data loss caused by external API services (including WhatsApp Business API, cloud hosting, etc.)",
            "• WhatsApp message delivery depends entirely on Meta's services and the recipient's device availability",
            "• Insurance decisions, approvals, and claims are the sole responsibility of the respective insurance providers",
            "• InsureBook does not guarantee uninterrupted, error-free, or completely secure service at all times",
            "• External integrations (payment gateways, messaging APIs, etc.) may experience temporary failures outside of InsureBook's control",
            "• The company shall not be liable for any indirect, incidental, or consequential damages arising from the use of this application"
        ]
    },
    {
        "id": 12,
        "title": "Third-Party Services",
        "icon": "extension",
        "content": [
            "InsureBook integrates with the following third-party services to provide its full functionality:",
            "• Meta WhatsApp Cloud API — for sending WhatsApp reminders and notifications",
            "• Cloud Hosting Providers (Railway, AWS, etc.) — for application and database hosting",
            "• PostgreSQL Database Services — for secure data storage",
            "• Payment Gateways (if integrated in future) — for premium collection",
            "Important:",
            "• Each third-party service operates under its own terms of service and privacy policies",
            "• InsureBook is not responsible for changes, outages, or policy modifications made by third-party providers",
            "• Users are encouraged to review the terms of service of integrated third-party providers independently"
        ]
    },
    {
        "id": 13,
        "title": "App Updates & Modifications",
        "icon": "update",
        "content": [
            "InsureBook is continuously improved to provide the best experience for insurance professionals.",
            "• Application features, user interface (UI), and services may be updated periodically",
            "• New features may be added and existing features may be modified or deprecated",
            "• These Terms & Conditions may be updated from time to time to reflect changes in the application or regulatory requirements",
            "• Continued use of InsureBook after any modifications constitutes acceptance of the updated terms",
            "• Users will be notified of significant changes through in-app notifications or email",
            "• It is the user's responsibility to periodically review these terms for any changes"
        ]
    },
    {
        "id": 14,
        "title": "Contact & Support",
        "icon": "support_agent",
        "content": [
            "For any questions, concerns, or support requests, please reach out to us through the following channels:",
            "📧 Email Support: support@insurebook.in",
            "📱 WhatsApp Support: +91-7875024546",
            "📞 Phone Support: +91-7875024546",
            "🏢 Office Address: InsureBook Technologies, Bhigwan, Maharashtra, India",
            "Support availability:",
            "• Email support: Available 24/7 with response within 24 hours",
            "• WhatsApp support: Available during business hours (9 AM - 6 PM IST)",
            "• Phone support: Available during business hours (9 AM - 6 PM IST)",
            "For urgent security concerns or data breach reports, please email security@insurebook.in immediately."
        ]
    }
]

async def seed_terms():
    async with SessionLocal() as session:
        # Check if terms already exist
        result = await session.execute(text("SELECT id FROM terms_conditions LIMIT 1"))
        existing = result.scalars().first()

        if existing:
            # Update existing
            await session.execute(
                text("UPDATE terms_conditions SET content = :content, version = :version, updated_at = NOW() WHERE id = :id"),
                {"content": json.dumps(TERMS_CONTENT), "version": "1.0.0", "id": existing}
            )
            print("✅ Terms & Conditions updated successfully!")
        else:
            # Insert new
            await session.execute(
                text("INSERT INTO terms_conditions (title, version, content) VALUES (:title, :version, :content)"),
                {"title": "Terms and Conditions", "version": "1.0.0", "content": json.dumps(TERMS_CONTENT)}
            )
            print("✅ Terms & Conditions seeded successfully!")

        await session.commit()

if __name__ == "__main__":
    asyncio.run(seed_terms())
