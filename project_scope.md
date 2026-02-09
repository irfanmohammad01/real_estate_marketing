# Real Estate Marketing Platform

#### Our platform is a multi-organization email marketing and campaign management system

#### designed for businesses that need to manage customer communications at scale.

### System Admin can add/manage Org details

```
● Goal : System Admin can create and maintain the Organization data.
● Org details (typical fields): Org name, legal name (optional)
● Capabilities
● Create Org (System Admin usually creates)
● View/Update Org profile
● Manage Org settings (timezone, defaults, feature toggles if needed)
● Acceptance criteria
● Org details are editable and reflected in agent invite emails and campaign scheduling
defaults.
```
### 1) Add Agent under an Organization (Org)

● **Goal** : Org Admin can create/manage “Agents” that belong to their Org.
**● Key capabilities**
● Add agent: name, email (unique), phone (optional), role (Office Admin/ User), status:
(Active/Deactive)
● List/search agents within an Org.
● Edit agent (basic profile + role).
● Deactivate agent.
**● Rules**
● Agent must belong to exactly one Org (unless you want multi-org).
● Email uniqueness is enforced (globally).
● **Acceptance criteria**
● Org Admin can add an agent and see them in the Org agent list immediately.
● An agent cannot act if the status is Disabled.
**Roles:**

1. **Org Admin:** Permission with read-write access features and add other agents to the same Org
2. **Org User:** Permission with read-write access


### 2) Send email to Agent once added to Org

```
● Goal : Automatically notify the agent with onboarding steps.
● Email content
● Invite email with Org name + “Set password / Activate account” link.
● Workflow
● On agent creation → send invite email
● Acceptance criteria
● Email is sent exactly once per invite event (resends are explicit).
● Invite link works, expires, and can be regenerated.
```
### 3) Agent can add Contacts (manual + import)

```
● Goal : Agents can build a contact under their Org.
● Manual : single contact
● Fields: first name, last name, email, phone, preferences (see #4)
● Validation + duplicate detection (by email/phone rules you choose).
● Import : multiple contacts
● Upload CSV → map columns → validate → import in background → import summary report.
● Report includes: created, updated (if allowed), skipped, and failed rows with reasons.
● Permissions
● Agents can create/edit contacts within their Org.
● Acceptance criteria
● Import handles large files via a background worker (if possible, shows progress)
```
### 4) Contacts should have a multi-select “Preferences” field

```
● Goal : Store multiple preferences per contact for targeting.
● Behavior
● Preferences are multi-select (e.g., PropertyType, Bedrooms, Bathrooms, Min Price, Max
Price, Built Area).
● Acceptance criteria
● A contact can have 0..N preferences.
```

### 5) Contacts can be added to Audience Groups

```
● Goal : Allow grouping contacts for campaigns.
● Capabilities
● Create an audience group (name, description).
● Add/remove contacts to a group (bulk add/remove supported).
● View group members + counts.
● Rules
● Groups are scoped to Org.
● A contact can belong to multiple groups.
● Acceptance criteria
● Campaigns can select one or more groups as recipients (see #7).
```
### 6) Create Email (template/content)

```
● Goal : Build an email message that can be reused in campaigns.
● Capabilities
● Create/edit email: subject, preheader (optional), from name/address, reply-to (optional),
body (HTML + optional plain text).
● Test send (optional).
● Acceptance criteria
● Email can be selected in campaign creation and renders correctly.
```
### 7) Create Campaign (choose email, recurring or one-time)

```
● Goal : Send a selected email to selected audience(s) either one-time or recurring.
● Campaign setup
● Name, selected Email, recipients (audience groups),
● schedule type:
● One-time: pick date/time + timezone.
● Recurring: define recurrence (daily/weekly/monthly) + start time + timezone + optional
end conditions.
● Campaign execution
● Queue sends as background jobs.
● Track status: Scheduled/Completed/Failed/Paused.
```

```
● Acceptance criteria
● One-time campaign sends once at the scheduled time.
● Recurring campaign creates runs on schedule and can be paused/stopped.
● Track email status
```


