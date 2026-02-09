# Campaign Management Setup Guide

## Overview
This guide explains how to set up and verify the Campaign Management feature.

## Prerequisites
- PostgreSQL database
- Redis (for Sidekiq)
- SMTP configuration for sending emails

## Setup Steps

### 1. Database Migration
The migrations have already been run. Verify with:
```bash
rails db:migrate:status
```

### 2. Seed Data
Ensure schedule types are seeded:
```bash
rails db:seed
```

This creates two schedule types:
- `one-time` - for campaigns that run once
- `recurring` - for campaigns that run on a schedule

### 3. Start Sidekiq
Start Sidekiq to process background jobs:
```bash
bundle exec sidekiq
```

### 4. Recurring Campaign Scheduler (Important!)
For recurring campaigns to work, you need to run the scheduler worker periodically.

**Option A: Using Linux Cron (Recommended for production)**
Add this to your crontab (`crontab -e`):
```
* * * * * cd /path/to/real_estate_marketing && bundle exec rails runner "RecurringCampaignSchedulerWorker.perform_async" >> log/cron.log 2>&1
```

**Option B: Manual trigger (for development/testing)**
In Rails console:
```ruby
RecurringCampaignSchedulerWorker.perform_async
```

**Option C: Using Sidekiq-Scheduler (Optional - Advanced)**
If you want automatic scheduling, install sidekiq-scheduler:
```bash
# Add to Gemfile:
gem 'sidekiq-scheduler'

# Run:
bundle install

# Create config/sidekiq.yml:
:schedule:
  recurring_campaign_check:
    cron: '* * * * *'  # Every minute
    class: RecurringCampaignSchedulerWorker
```

## Testing the Implementation

### 1. Create a One-Time Campaign

```bash
curl -X POST http://localhost:3000/campaigns \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "campaign": {
      "name": "Test One-Time Campaign",
      "email_template_id": 1,
      "schedule_type": "one-time",
      "scheduled_at": "2026-02-09T10:00:00Z"
    },
    "audience_ids": [1]
  }'
```

Expected response: 201 Created with campaign details

### 2. List Campaigns

```bash
curl http://localhost:3000/campaigns \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 3. Pause a Campaign

```bash
curl -X POST http://localhost:3000/campaigns/1/pause \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 4. View Campaign Stats

```bash
curl http://localhost:3000/campaigns/1/stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 5. View Email Sends

```bash
curl http://localhost:3000/campaigns/1/sends \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 6. Create a Recurring Campaign

```bash
curl -X POST http://localhost:3000/campaigns \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "campaign": {
      "name": "Weekly Newsletter",
      "email_template_id": 1,
      "schedule_type": "recurring",
      "cron_expression": "0 9 * * 1",
      "end_date": "2026-03-09T10:00:00Z"
    },
    "audience_ids": [1, 2]
  }'
```

Cron expression examples:
- `* * * * *` - Every minute (testing)
- `0 9 * * *` - Daily at 9:00 AM
- `0 9 * * 1` - Every Monday at 9:00 AM
- `0 9 1 * *` - 1st day of every month at 9:00 AM

## How It Works

### Dynamic Contact Matching
Audiences don't have fixed contact lists. Instead, contacts matching to audiences happens dynamically at **campaign execution time** based on preference criteria.

Example:
- Audience "Luxury Buyers" has preferences: `3BHK`, `Mumbai`, `Fully Furnished`
- At campaign execution, the system finds ALL contacts with those exact preferences
- If a contact is added/modified after campaign creation, they'll be included in the next run

### One-Time Campaigns Flow
1. Campaign created with `scheduled_at` time
2. `CampaignExecutionWorker` is scheduled to run at that time
3. At execution, contacts are matched from audiences
4. `CampaignSend` records created for each contact
5. `EmailSendWorker` queued for each send
6. Emails are sent asynchronously
7. Campaign status changes: scheduled → running → completed

### Recurring Campaigns Flow
1. Campaign created with `cron_expression`
2. `RecurringCampaignSchedulerWorker` runs every minute
3. Checks if it's time to execute based on cron and `last_run_at`
4. If yes, queues `CampaignExecutionWorker`
5. After execution, campaign reverts to `scheduled` status
6. Process repeats until `end_date` is reached

## Important Notes

### No Deduplication
If a contact matches multiple audiences in a campaign, they will receive **multiple emails**. This is by design per requirements.

### No Campaign Editing
Once a campaign is created, it **cannot be edited**. You can only:
- Pause it
- Resume it
- Cancel it

### Email Tracking
The system tracks three statuses for each email:
- `queued` - Email is waiting to be sent
- `sent` - Email was sent successfully
- `failed` - Email failed with error message

## Troubleshooting

### Emails not sending
1. Check Sidekiq is running: `ps aux | grep sidekiq`
2. Check Redis is running: `redis-cli ping`
3. Check SMTP configuration in `.env`
4. Check Sidekiq logs: `tail -f log/sidekiq.log`

### Recurring campaigns not executing
1. Ensure cron job is running OR manually trigger scheduler
2. Check campaign status is not `paused`
3. Check `end_date` hasn't passed
4. Verify cron expression is valid: https://crontab.guru/

### No matching contacts
1. Verify audience preferences match contact preferences
2. Check contacts have preference records
3. Audience criteria uses AND logic (all must match)

## API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /campaigns | List all campaigns (with pagination) |
| POST | /campaigns | Create new campaign |
| GET | /campaigns/:id | Show campaign details |
| POST | /campaigns/:id/pause | Pause campaign |
| POST | /campaigns/:id/resume | Resume campaign |
| DELETE | /campaigns/:id | Cancel campaign |
| GET | /campaigns/:id/stats | View campaign statistics |
| GET | /campaigns/:id/sends | List individual email sends |

## Next Steps

1. ✅ Verify database migrations
2. ✅ Seed schedule types
3. ✅ Start Sidekiq
4. ⚠️  Configure recurring campaign scheduler
5. Test one-time campaign creation
6. Test recurring campaign creation
7. Monitor email sends
8. Update Swagger documentation

