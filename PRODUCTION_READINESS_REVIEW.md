# Production Readiness Review - Real Estate API

**Date:** February 7, 2026  
**Status:** ⚠️ **CRITICAL ISSUES FOUND - Not Production Ready**

---

## Executive Summary

This Rails 8.1 API for real estate marketing has several **critical security vulnerabilities**, **hardcoded configuration issues**, and **maintainability problems** that must be addressed before production deployment. Key concerns include:

- **JWT token handling with no expiration enforcement**
- **Hardcoded environment-dependent values scattered throughout code**
- **Missing CORS configuration disabled entirely**
- **No rate limiting or request throttling**
- **Weak authorization patterns using string comparisons**
- **CSV import lacks validation and size limits**
- **No audit logging for sensitive operations**
- **Password generation exposed in responses**

---

## 1. CRITICAL SECURITY ISSUES

### 1.1 **JWT Token Expiration Not Enforced** ⚠️ CRITICAL

**File:** [lib/json_web_token.rb](lib/json_web_token.rb)

```ruby
def self.decode(token)
  body = JWT.decode(token, SECRET_KEY)[0]
  HashWithIndifferentAccess.new(body)
rescue JWT::ExpiredSignature, JWT::DecodeError
  nil
end
```

**Problem:**
- Token expiration is set to 24 hours but errors are silently caught and return `nil`
- The application controller doesn't explicitly check token validity timestamps
- No refresh token mechanism exists
- Expired tokens should trigger clear error responses, not silent failures

**Risk:** Attackers could craft tokens that appear valid but bypass expiration checks

**Fix:**
```ruby
# lib/json_web_token.rb
class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base
  TOKEN_EXPIRY = ENV.fetch('JWT_EXPIRY_HOURS', 24).to_i.hours
  REFRESH_TOKEN_EXPIRY = ENV.fetch('JWT_REFRESH_EXPIRY_DAYS', 7).to_i.days

  def self.encode(payload, exp = nil)
    exp ||= TOKEN_EXPIRY.from_now
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  def self.decode(token)
    begin
      body = JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256' })[0]
      HashWithIndifferentAccess.new(body)
    rescue JWT::ExpiredSignature
      raise AuthenticationError, 'Token has expired'
    rescue JWT::DecodeError => e
      raise AuthenticationError, "Invalid token: #{e.message}"
    end
  end
end
```

---

### 1.2 **Hardcoded Environment Dependencies Throughout Code** ⚠️ CRITICAL

**Files:**
- [app/controllers/admin/org_admins_controller.rb](app/controllers/admin/org_admins_controller.rb)
- [app/controllers/organizations_controller.rb](app/controllers/organizations_controller.rb)
- [app/controllers/users_controller.rb](app/controllers/users_controller.rb)
- [app/mailers/user_mailer.rb](app/mailers/user_mailer.rb)

**Problems:**

1. **Magic strings for role names:**
```ruby
# ORG_ADMIN_ROLE, ORG_USER_ROLE referenced as ENV variables
role = Role.find_by!(name: ENV["ORG_ADMIN_ROLE"])
```

2. **Status values hardcoded in ENV:**
```ruby
user.status = ENV["ORG_USER_STATUS"]
user.status = ENV["ORG_ADMIN_STATUS"]
```

3. **Invitation link as ENV variable:**
```ruby
invitation_link = ENV["INVITATION_LINK"]
```

**Issues:**
- Brittle - ENV variable typos cause runtime failures
- No validation that ENV variables exist
- Hard to track which values are configurable
- Repeated throughout multiple controllers
- Inconsistent status values in different places

**Fix - Create a configuration class:**

```ruby
# config/application.rb (add to Rails.application.config)
config.application_config = {
  roles: {
    super_user: ENV.fetch('ROLE_SUPER_USER', 'SUPER_USER'),
    org_admin: ENV.fetch('ROLE_ORG_ADMIN', 'ORG_ADMIN'),
    org_user: ENV.fetch('ROLE_ORG_USER', 'ORG_USER')
  },
  user_statuses: {
    active: ENV.fetch('STATUS_ACTIVE', 'ACTIVE'),
    inactive: ENV.fetch('STATUS_INACTIVE', 'INACTIVE'),
    pending: ENV.fetch('STATUS_PENDING', 'PENDING')
  },
  jwt: {
    expiry_hours: ENV.fetch('JWT_EXPIRY_HOURS', '24').to_i,
    refresh_expiry_days: ENV.fetch('JWT_REFRESH_EXPIRY_DAYS', '7').to_i,
    algorithm: ENV.fetch('JWT_ALGORITHM', 'HS256')
  },
  features: {
    invitation_link: ENV.fetch('INVITATION_LINK', nil),
    enable_email_invitations: ENV.fetch('ENABLE_EMAIL_INVITATIONS', 'true') == 'true'
  }
}
```

Or create a dedicated config service:
```ruby
# app/services/application_config.rb
class ApplicationConfig
  def self.role_org_admin
    ENV.fetch('ROLE_ORG_ADMIN') { raise 'ROLE_ORG_ADMIN not configured' }
  end

  def self.role_org_user
    ENV.fetch('ROLE_ORG_USER') { raise 'ROLE_ORG_USER not configured' }
  end

  def self.status_active
    ENV.fetch('STATUS_ACTIVE', 'ACTIVE')
  end

  # ... etc
end
```

---

### 1.3 **CORS Configuration Disabled Entirely** ⚠️ CRITICAL

**File:** [config/initializers/cors.rb](config/initializers/cors.rb)

```ruby
# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins "example.com"
#     resource "*",
#       headers: :any,
#       methods: [:get, :post, :put, :patch, :delete, :options, :head]
#   end
# end
```

**Problem:**
- CORS is completely disabled (commented out)
- No origin restriction in place
- Frontend cannot make authenticated requests from any domain
- OR the application is vulnerable to CSRF/cross-origin attacks depending on how it's deployed

**Fix:**
```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allowed_origins = ENV.fetch('CORS_ORIGINS', 'localhost:3001').split(',')
  
  allow do
    origins *allowed_origins
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 3600
  end
end
```

Add to `.env`:
```
CORS_ORIGINS=localhost:3001,staging.example.com,app.example.com
```

---

### 1.4 **Weak Role-Based Authorization** ⚠️ HIGH

**File:** [app/controllers/application_controller.rb](app/controllers/application_controller.rb)

```ruby
def org_admin?
  current_user&.role&.name == "ORG_ADMIN"
end

def authorize_org_member!(*roles)
  unless current_user && current_user.role && roles.include?(current_user.role.name)
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
```

**Problems:**
1. **String comparison for authorization** - fragile and error-prone
2. **Hardcoded role strings** throughout the codebase
3. **No permission matrix** - roles and permissions tightly coupled
4. **Inconsistent authorization patterns** - some use symbols, some use strings
5. **No audit trail** - authorization failures not logged

**Fix - Implement proper authorization:**

```ruby
# app/models/role.rb
class Role < ApplicationRecord
  has_many :users
  
  ROLES = {
    super_user: 'SUPER_USER',
    org_admin: 'ORG_ADMIN',
    org_user: 'ORG_USER'
  }.freeze
  
  validates :name, presence: true, uniqueness: true, inclusion: { in: ROLES.values }
  
  def self.super_user
    find_by!(name: ROLES[:super_user])
  end
  
  def self.org_admin
    find_by!(name: ROLES[:org_admin])
  end
  
  def self.org_user
    find_by!(name: ROLES[:org_user])
  end
end

# app/models/user.rb
class User < ApplicationRecord
  enum role_type: { super_user: 0, org_admin: 1, org_user: 2 }
  
  belongs_to :role
  
  def super_user?
    role.name == Role::ROLES[:super_user]
  end
  
  def org_admin?
    role.name == Role::ROLES[:org_admin]
  end
  
  def org_user?
    role.name == Role::ROLES[:org_user]
  end
end

# app/controllers/application_controller.rb
def authorize_org_admin!
  unless current_user&.org_admin?
    render_forbidden('ORG_ADMIN role required')
  end
end

def authorize_org_member!(*roles)
  unless current_user && roles.any? { |r| current_user.send("#{r}?") rescue false }
    render_forbidden('Insufficient permissions')
  end
end

private

def render_forbidden(message)
  log_authorization_failure(message)
  render json: { error: message }, status: :forbidden
end

def log_authorization_failure(reason)
  Rails.logger.warn({
    event: 'authorization_failure',
    user_id: current_user&.id,
    reason: reason,
    path: request.path,
    timestamp: Time.current
  }.to_json)
end
```

---

### 1.5 **No Request Rate Limiting** ⚠️ HIGH

**Problem:** No protection against brute force attacks or DOS

**Fix:**

```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle login attempts
  throttle('logins/ip', limit: 5, period: 5.minutes) do |req|
    if req.path == '/auth/login' && req.post?
      req.ip
    end
  end

  # Throttle signup attempts
  throttle('signups/ip', limit: 3, period: 1.hour) do |req|
    if req.path == '/users' && req.post?
      req.ip
    end
  end

  # General API rate limiting
  throttle('api/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/health')
  end
end
```

---

### 1.6 **No Audit Logging for Sensitive Operations** ⚠️ HIGH

**Problem:** No record of who changed what, when, and why. Critical for compliance.

**Fix:**

```ruby
# Gemfile
gem 'audited'

# rails generate audited:install
# rails db:migrate

# app/models/user.rb
class User < ApplicationRecord
  audited
end

# app/models/organization.rb  
class Organization < ApplicationRecord
  audited
end

# app/controllers/organizations_controller.rb
def destroy
  @organization.destroy
  Audit.create!(
    user: current_super_user,
    auditable: @organization,
    action: 'destroy',
    comment: "Soft deleted organization #{@organization.name}"
  )
  render json: { message: "Organization deleted" }
end
```

---

## 2. HARDCODED VALUES & CONFIGURATION ISSUES

### 2.1 **Password Generation Constants Hardcoded**

**Files:**
- [app/controllers/admin/org_admins_controller.rb](app/controllers/admin/org_admins_controller.rb)
- [app/controllers/organizations_controller.rb](app/controllers/organizations_controller.rb)
- [app/controllers/users_controller.rb](app/controllers/users_controller.rb)

```ruby
temporary_password = PasswordGenerator.generate_password(length: 10, uppercase: true, lowercase: true, digits: true, symbols: true)
```

**Problems:**
1. Password generation rules scattered throughout code
2. No consistent policy
3. Length hardcoded to 10 characters (may not meet security policy)
4. Same code duplicated in 3+ places

**Fix:**

```ruby
# app/services/password_service.rb
class PasswordService
  PASSWORD_LENGTH = ENV.fetch('TEMP_PASSWORD_LENGTH', '12').to_i
  REQUIRE_UPPERCASE = ENV.fetch('PASSWORD_REQUIRE_UPPERCASE', 'true') == 'true'
  REQUIRE_LOWERCASE = ENV.fetch('PASSWORD_REQUIRE_LOWERCASE', 'true') == 'true'
  REQUIRE_DIGITS = ENV.fetch('PASSWORD_REQUIRE_DIGITS', 'true') == 'true'
  REQUIRE_SYMBOLS = ENV.fetch('PASSWORD_REQUIRE_SYMBOLS', 'true') == 'true'

  def self.generate_temporary
    PasswordGenerator.generate_password(
      length: PASSWORD_LENGTH,
      uppercase: REQUIRE_UPPERCASE,
      lowercase: REQUIRE_LOWERCASE,
      digits: REQUIRE_DIGITS,
      symbols: REQUIRE_SYMBOLS
    )
  end
end

# Then in controllers:
temporary_password = PasswordService.generate_temporary
```

---

### 2.2 **Hardcoded Email Template Names**

**File:** [app/mailers/user_mailer.rb](app/mailers/user_mailer.rb)

```ruby
def template_name_for(user)
  if user.role.name == ENV["ORG_ADMIN_ROLE"]
    "Admin Invitation Template"
  else
    "Org Agent Invitation Template"
  end
end
```

**Problems:**
1. Magic strings for template names
2. Brittle - template renames will break functionality
3. No validation that template exists before sending
4. Coupled to database content

**Fix:**

```ruby
# app/models/email_template.rb
class EmailTemplate < ApplicationRecord
  TEMPLATE_KEYS = {
    admin_invitation: 'ADMIN_INVITATION',
    user_invitation: 'USER_INVITATION',
    password_reset: 'PASSWORD_RESET',
    welcome: 'WELCOME'
  }.freeze

  validates :key, inclusion: { in: TEMPLATE_KEYS.values }

  def self.for_admin_invitation
    find_by!(key: TEMPLATE_KEYS[:admin_invitation])
  end

  def self.for_user_invitation
    find_by!(key: TEMPLATE_KEYS[:user_invitation])
  end
end

# app/mailers/user_mailer.rb
def invitation_email(user, invitation_link, temporary_password)
  template = user.org_admin? ? 
    EmailTemplate.for_admin_invitation : 
    EmailTemplate.for_user_invitation

  raise TemplateNotFoundError unless template
  # ... rest of code
end
```

---

### 2.3 **Missing Default Configuration Values**

**Problem:** Code fails if ENV variables not set, no defaults or validation

**Examples:**
- `ENV["ORG_ADMIN_ROLE"]` - no default if not set
- `ENV["INVITATION_LINK"]` - optional but behavior unclear
- `GMAIL_USERNAME`, `GMAIL_APP_PASSWORD` - credentials in plain ENV

**Fix:**

```ruby
# config/initializers/configuration_validator.rb
class ConfigurationValidator
  REQUIRED_VARS = %w[
    ROLE_ORG_ADMIN
    ROLE_ORG_USER
    STATUS_ACTIVE
    STATUS_INACTIVE
  ].freeze

  SMTP_VARS = %w[
    SMTP_HOST
    SMTP_PORT
    SMTP_USERNAME
    SMTP_PASSWORD
  ].freeze

  def self.validate!
    missing = REQUIRED_VARS.select { |var| ENV[var].blank? }
    
    if missing.any?
      raise "Missing required environment variables: #{missing.join(', ')}"
    end

    if Rails.env.production?
      smtp_missing = SMTP_VARS.select { |var| ENV[var].blank? }
      raise "Missing SMTP vars in production: #{smtp_missing.join(', ')}" if smtp_missing.any?
    end
  end
end

# config/application.rb
config.after_initialize { ConfigurationValidator.validate! }
```

---

## 3. AUTHENTICATION & SESSION MANAGEMENT ISSUES

### 3.1 **No Refresh Token Mechanism**

**Problem:** Tokens expire after 24 hours; users must log in again. No way to maintain sessions.

**Fix:**

```ruby
# db/migrate/20260207_add_refresh_tokens.rb
class AddRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :refresh_token, :string, null: true
    add_column :users, :refresh_token_expires_at, :datetime, null: true
    add_index :users, :refresh_token, unique: true
    
    add_column :super_users, :refresh_token, :string, null: true
    add_column :super_users, :refresh_token_expires_at, :datetime, null: true
    add_index :super_users, :refresh_token, unique: true
  end
end

# lib/json_web_token.rb (updated)
class JsonWebToken
  def self.issue_tokens(user_id, user_type = 'user')
    access_token = encode(
      user_id: user_id, 
      user_type: user_type,
      type: 'access'
    )
    
    refresh_token = SecureRandom.urlsafe_base64(32)
    {
      access_token: access_token,
      refresh_token: refresh_token,
      expires_in: 24.hours.to_i
    }
  end

  def self.refresh_access_token(refresh_token)
    # Validate refresh token exists and not expired
    # Issue new access token
  end
end

# app/controllers/auth/users_controller.rb
def login
  user = User.find_by(email: user_params[:email])
  
  if user&.authenticate(user_params[:password])
    tokens = JsonWebToken.issue_tokens(user.id, 'user')
    user.update(
      refresh_token: tokens[:refresh_token],
      refresh_token_expires_at: 7.days.from_now
    )
    
    render json: {
      access_token: tokens[:access_token],
      refresh_token: tokens[:refresh_token],
      token_type: 'Bearer',
      expires_in: tokens[:expires_in],
      user: { id: user.id, email: user.email, role: user.role.name }
    }
  else
    render json: { error: 'Invalid credentials' }, status: :unauthorized
  end
end
```

---

### 3.2 **No Token Revocation/Blacklist**

**Problem:** Logged-out or compromised tokens cannot be invalidated

**Fix:**

```ruby
# Gemfile
gem 'redis'

# app/services/token_blacklist_service.rb
class TokenBlacklistService
  REDIS = Redis.new(url: ENV['REDIS_URL'])
  BLACKLIST_PREFIX = 'token_blacklist:'

  def self.revoke(token, expires_at)
    ttl = (expires_at - Time.current).to_i
    REDIS.set("#{BLACKLIST_PREFIX}#{token}", true, ex: ttl) if ttl > 0
  end

  def self.revoked?(token)
    REDIS.exists?("#{BLACKLIST_PREFIX}#{token}")
  end

  def self.clear_expired
    # Redis handles TTL automatically
  end
end

# app/controllers/auth/users_controller.rb
def logout
  token = request.headers['Authorization']&.split(' ')&.last
  decoded = JsonWebToken.decode(token)
  
  TokenBlacklistService.revoke(token, Time.at(decoded[:exp]))
  render json: { message: 'Logged out successfully' }
end
```

---

### 3.3 **Password Requirements Hardcoded in Model**

**File:** [app/models/user.rb](app/models/user.rb)

```ruby
VALID_PASSWORD_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}\z/
```

**Problems:**
1. Hardcoded minimum 8 characters + special requirements
2. No configuration for different password policies
3. Duplicated in SuperUser model
4. Difficult to change without code modification

**Fix:**

```ruby
# config/initializers/password_policy.rb
PASSWORD_POLICY = {
  min_length: ENV.fetch('PASSWORD_MIN_LENGTH', '12').to_i,
  require_uppercase: ENV.fetch('PASSWORD_REQUIRE_UPPERCASE', 'true') == 'true',
  require_lowercase: ENV.fetch('PASSWORD_REQUIRE_LOWERCASE', 'true') == 'true',
  require_digits: ENV.fetch('PASSWORD_REQUIRE_DIGITS', 'true') == 'true',
  require_special: ENV.fetch('PASSWORD_REQUIRE_SPECIAL', 'true') == 'true',
  expiry_days: ENV.fetch('PASSWORD_EXPIRY_DAYS', '90').to_i
}.freeze

# app/validators/password_validator.rb
class PasswordValidator < ActiveModel::Validator
  def validate(record)
    password = record.password
    policy = PASSWORD_POLICY

    if password.length < policy[:min_length]
      record.errors.add(:password, "must be at least #{policy[:min_length]} characters")
    end

    if policy[:require_uppercase] && !password.match?(/[A-Z]/)
      record.errors.add(:password, "must include uppercase letter")
    end

    if policy[:require_lowercase] && !password.match?(/[a-z]/)
      record.errors.add(:password, "must include lowercase letter")
    end

    if policy[:require_digits] && !password.match?(/\d/)
      record.errors.add(:password, "must include digit")
    end

    if policy[:require_special] && !password.match?(/[^A-Za-z0-9]/)
      record.errors.add(:password, "must include special character")
    end
  end
end

# app/models/user.rb
class User < ApplicationRecord
  validates_with PasswordValidator
end
```

---

## 4. DATA VALIDATION & INPUT SECURITY

### 4.1 **CSV Import Without Size Limits** ⚠️ HIGH

**File:** [app/controllers/contacts_controller.rb](app/controllers/contacts_controller.rb)

```ruby
def import
  uploaded_file = params[:file]
  # ... directly saves to disk with timestamp
  File.open(tmp_path, "wb") { |f| f.write(uploaded_file.read) }
  ContactCsvImportWorker.perform_async(tmp_path.to_s, organization_id)
end
```

**Problems:**
1. **No file size validation** - could cause DOS with huge file
2. **No file type validation** - could accept arbitrary file types
3. **No row count limit** - bulk import could create massive records
4. **No validation of CSV structure** before queuing job
5. **Stored in `/tmp` without cleanup** - could fill disk
6. **No progress tracking** - user doesn't know import status

**Fix:**

```ruby
# app/controllers/contacts_controller.rb
MAX_FILE_SIZE = ENV.fetch('MAX_IMPORT_FILE_SIZE', 10.megabytes).to_i
MAX_ROWS = ENV.fetch('MAX_IMPORT_ROWS', 10000).to_i
ALLOWED_MIME_TYPES = %w[text/csv application/vnd.ms-excel].freeze

def import
  uploaded_file = params[:file]
  
  unless uploaded_file
    return render json: { error: 'No file uploaded' }, status: :unprocessable_entity
  end

  # Validate file size
  if uploaded_file.size > MAX_FILE_SIZE
    return render json: { 
      error: "File size exceeds #{MAX_FILE_SIZE / 1.megabyte}MB limit" 
    }, status: :unprocessable_entity
  end

  # Validate MIME type
  unless ALLOWED_MIME_TYPES.include?(uploaded_file.content_type)
    return render json: { 
      error: "Invalid file type. Only CSV files allowed" 
    }, status: :unprocessable_entity
  end

  # Validate CSV structure and row count before queuing
  begin
    validation_result = ContactCsvImportService.validate(uploaded_file)
    
    unless validation_result[:valid]
      return render json: validation_result[:errors], status: :unprocessable_entity
    end

    if validation_result[:row_count] > MAX_ROWS
      return render json: { 
        error: "CSV exceeds #{MAX_ROWS} rows limit" 
      }, status: :unprocessable_entity
    end
  rescue => e
    return render json: { error: "Failed to validate CSV: #{e.message}" }, status: :unprocessable_entity
  end

  # Queue import with organization and user context
  organization_id = current_user.organization_id
  import_job = ContactImportJob.perform_later(
    organization_id,
    current_user.id,
    uploaded_file.read,
    uploaded_file.original_filename
  )

  render json: { 
    message: 'Import started successfully',
    job_id: import_job.job_id
  }, status: :accepted
rescue => e
  Rails.logger.error "Import error: #{e.message}"
  render json: { error: 'Failed to start import' }, status: :unprocessable_entity
end
```

```ruby
# app/services/contact_csv_import_service.rb
class ContactCsvImportService
  def self.validate(file)
    errors = []
    row_count = 0
    required_headers = %w[first_name last_name email phone]

    CSV.foreach(file.path, headers: true) do |row|
      row_count += 1
      
      # Validate headers on first row
      if row_count == 1
        missing_headers = required_headers - row.headers
        if missing_headers.any?
          errors << "Missing required columns: #{missing_headers.join(', ')}"
        end
      end

      # Validate required fields
      required_headers.each do |header|
        if row[header].blank?
          errors << "Row #{row_count}: #{header} is required"
          break
        end
      end

      # Validate email format
      unless row['email'].match?(URI::MailTo::EMAIL_REGEXP)
        errors << "Row #{row_count}: Invalid email format"
      end

      # Validate phone length
      if row['phone'].present? && row['phone'].length != 10
        errors << "Row #{row_count}: Phone must be 10 digits"
      end

      break if errors.any? # Stop validation on first error batch
    end

    { valid: errors.empty?, errors: errors, row_count: row_count }
  end
end
```

---

### 4.2 **No Input Sanitization in Preference Lookups**

**File:** [app/controllers/contacts_controller.rb](app/controllers/contacts_controller.rb)

```ruby
Preference.create!(
  contact_id: contact.id,
  bhk_type_id: BhkType.find_by(name: params[:preference][:bhk_type])&.id,
  furnishing_type_id: FurnishingType.find_by(name: params[:preference][:furnishing_type])&.id,
  # ...
)
```

**Problems:**
1. No validation that lookups succeed
2. Silent failures if preference types don't exist
3. No error handling if enum values invalid
4. Direct string matching could be vulnerable

**Fix:**

```ruby
# app/services/preference_resolver_service.rb
class PreferenceResolverService
  class InvalidPreferenceError < StandardError; end

  def self.resolve(preference_params)
    {
      bhk_type_id: resolve_bhk_type(preference_params[:bhk_type]),
      furnishing_type_id: resolve_furnishing_type(preference_params[:furnishing_type]),
      location_id: resolve_location(preference_params[:location]),
      property_type_id: resolve_property_type(preference_params[:property_type]),
      power_backup_type_id: resolve_power_backup_type(preference_params[:power_backup_type])
    }
  end

  private

  def self.resolve_bhk_type(name)
    return nil if name.blank?
    BhkType.find_by(name: name) || raise(InvalidPreferenceError, "Invalid BhkType: #{name}")
  end

  def self.resolve_furnishing_type(name)
    return nil if name.blank?
    FurnishingType.find_by(name: name) || raise(InvalidPreferenceError, "Invalid FurnishingType: #{name}")
  end

  # ... similar methods
end

# app/controllers/contacts_controller.rb
if params[:preference].present?
  Preference.create!(
    contact_id: contact.id,
    **PreferenceResolverService.resolve(params[:preference])
  )
end
```

---

## 5. MAINTAINABILITY & SCALABILITY ISSUES

### 5.1 **No Database Connection Pooling Configuration**

**File:** [config/database.yml](config/database.yml) - likely using defaults

**Problem:** Default pool size (5) may be insufficient or excessive

**Fix:**

```yaml
# config/database.yml
default: &default
  adapter: postgresql
  pool: <%= ENV.fetch("DB_POOL_SIZE", "10") %>
  timeout: <%= ENV.fetch("DB_TIMEOUT", "5000") %>
  reaping_frequency: <%= ENV.fetch("DB_REAPING_FREQUENCY", "10") %>
  
production:
  <<: *default
  pool: <%= ENV.fetch("DB_POOL_SIZE", "25") %>
  timeout: <%= ENV.fetch("DB_TIMEOUT", "5000") %>
```

---

### 5.2 **Missing Database Indexes**

**Problems observed:**
1. Authorization checks query `users.organization_id` repeatedly without index
2. Contact queries filter by `organization_id` without index
3. No composite indexes for common queries

**Fix:**

```ruby
# db/migrate/20260207_add_indexes_for_performance.rb
class AddIndexesForPerformance < ActiveRecord::Migration[8.1]
  def change
    # Organization ownership
    add_index :users, [:organization_id, :role_id], name: 'idx_users_org_role'
    add_index :contacts, [:organization_id, :created_at], name: 'idx_contacts_org_date'
    add_index :audiences, [:organization_id, :deleted_at], name: 'idx_audiences_org_soft_delete'
    add_index :preferences, :contact_id, name: 'idx_preferences_contact'
    
    # Authentication
    add_index :users, [:email, :organization_id], unique: true, name: 'idx_users_email_org'
    add_index :super_users, :email, unique: true, name: 'idx_super_users_email'
    
    # Token revocation
    add_index :users, :refresh_token, unique: true, sparse: true, name: 'idx_users_refresh_token'
  end
end
```

---

### 5.3 **No Query Optimization (N+1 queries)**

**Example from** [app/controllers/users_controller.rb](app/controllers/users_controller.rb):

```ruby
def index
  @users = User.where(organization_id: current_user.organization_id)
  render json: @users  # Will trigger N queries for roles
end
```

**Fix:**

```ruby
def index
  @users = User.where(organization_id: current_user.organization_id)
              .includes(:role)
              .order(created_at: :desc)
  render json: @users
end
```

Implement for all controllers.

---

### 5.4 **No Error Handling Standardization**

**Problems:**
- Different error response formats
- No error codes for clients to parse
- Stack traces potentially exposed in development

**Fix:**

```ruby
# app/controllers/concerns/error_handler.rb
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_standard_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from AuthenticationError, with: :handle_authentication_error
    rescue_from AuthorizationError, with: :handle_authorization_error
  end

  private

  def handle_standard_error(exception)
    Rails.logger.error("#{exception.class}: #{exception.message}")
    render json: {
      error: 'Internal server error',
      code: 'INTERNAL_ERROR'
    }, status: :internal_server_error
  end

  def handle_not_found(exception)
    render json: {
      error: 'Resource not found',
      code: 'NOT_FOUND'
    }, status: :not_found
  end

  def handle_validation_error(exception)
    render json: {
      error: 'Validation failed',
      code: 'VALIDATION_ERROR',
      details: exception.record.errors.messages
    }, status: :unprocessable_entity
  end

  def handle_authentication_error(exception)
    render json: {
      error: exception.message,
      code: 'AUTHENTICATION_FAILED'
    }, status: :unauthorized
  end

  def handle_authorization_error(exception)
    render json: {
      error: exception.message,
      code: 'FORBIDDEN'
    }, status: :forbidden
  end
end

# app/controllers/application_controller.rb
include ErrorHandler
```

---

### 5.5 **Missing API Versioning Strategy**

**Problem:** Routes show V1 swagger but no actual versioning implementation

**Fix:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "/auth/super/login", to: "auth/super_users#login"
      post "/auth/login", to: "auth/users#login"
      
      namespace :admin do
        resources :org_admins, only: [:create, :update]
      end
      
      resources :organizations do
        post :restore, on: :member
      end
      
      # ... rest of routes
    end
    
    # Future v2 changes
    namespace :v2 do
      # Backward compatibility not broken
    end
  end
end

# app/controllers/api/v1/application_controller.rb
module Api
  module V1
    class ApplicationController < ::ApplicationController
      # V1 specific behavior
    end
  end
end
```

---

## 6. OPERATIONAL & DEPLOYMENT ISSUES

### 6.1 **Missing Environment Configuration Validation**

**Problem:** No startup verification that all required variables are set

**See fix in Section 2.3 - Add ConfigurationValidator**

---

### 6.2 **Sidekiq Configuration Not Environment-Aware**

**File:** [config/sidekiq.yml](config/sidekiq.yml)

```yaml
:concurrency: 5
```

**Problems:**
1. Concurrency hardcoded to 5
2. No production vs. development differentiation
3. No queue priorities defined
4. No retry policy configured

**Fix:**

```yaml
# config/sidekiq.yml
:concurrency: <%= ENV.fetch('SIDEKIQ_CONCURRENCY', Rails.env.production? ? 10 : 5) %>
:timeout: <%= ENV.fetch('SIDEKIQ_TIMEOUT', 30) %>
:max_retries: <%= ENV.fetch('SIDEKIQ_MAX_RETRIES', 5) %>

:queues:
  - [critical, 5]
  - [default, 3]
  - [low, 1]

:dead_letter_max_jobs: 10000
:dead_letter_max_age: <%= 3.months.to_i %>
```

---

### 6.3 **Missing Health Check Endpoints**

**Problem:** Only `/up` endpoint exists, no service health checks

**Fix:**

```ruby
# app/controllers/health_check_controller.rb
class HealthCheckController < ApplicationController
  skip_before_action :authorize_request

  def status
    checks = {
      api: 'ok',
      database: database_healthy?,
      redis: redis_healthy?,
      sidekiq: sidekiq_healthy?
    }

    status = checks.values.all? { |v| v == 'ok' } ? :ok : :service_unavailable

    render json: checks, status: status
  end

  private

  def database_healthy?
    ActiveRecord::Base.connection.execute('SELECT 1')
    'ok'
  rescue
    'error'
  end

  def redis_healthy?
    Redis.new.ping == 'PONG' ? 'ok' : 'error'
  rescue
    'error'
  end

  def sidekiq_healthy?
    Sidekiq::Api.redis_info ? 'ok' : 'error'
  rescue
    'error'
  end
end
```

---

### 6.4 **No Structured Logging**

**Problem:** Logs are unstructured, hard to parse for monitoring

**Fix:**

```ruby
# config/initializers/logging.rb
if Rails.env.production?
  formatter = lambda do |severity, datetime, progname, msg|
    {
      timestamp: datetime.iso8601,
      level: severity,
      message: msg,
      application: 'real_estate_api'
    }.to_json
  end

  STDOUT.sync = true
  rails_logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
  rails_logger.formatter = formatter

  Rails.logger = rails_logger
end
```

---

### 6.5 **Missing Security Headers**

**Fix:**

```ruby
# config/initializers/security_headers.rb
Rails.application.configure do
  config.middleware.use Rack::SecurityHeaders do |headers|
    headers.strict_transport_security = "max-age=31536000; includeSubDomains" if Rails.env.production?
    headers.x_frame_options = "DENY"
    headers.x_content_type_options = "nosniff"
    headers.x_xss_protection = "1; mode=block"
    headers.referrer_policy = "strict-origin-when-cross-origin"
    headers.content_security_policy = "default-src 'self'"
  end
end
```

### 7.1 **No Data Encryption at Rest**

**Problem:** Sensitive data (passwords, emails) stored plaintext

**Fix - Already using `has_secure_password`** ✅

But add encryption for additional fields:

```ruby
# Gemfile
gem 'attr_encrypted'

# app/models/user.rb
class User < ApplicationRecord
  attr_encrypted :email, key: ENV['EMAIL_ENCRYPTION_KEY']
  
  # ... rest
end
```

---


**See fix in Section 1.6**

---

## 8. SUMMARY TABLE

| Issue | Severity | Category | Fix Effort | Status |
|-------|----------|----------|-----------|--------|
| JWT expiration not enforced | CRITICAL | Security | 2 hours | 🔴 Not Fixed |
| Hardcoded env dependencies | CRITICAL | Config | 4 hours | 🔴 Not Fixed |
| CORS disabled entirely | CRITICAL | Security | 1 hour | 🔴 Not Fixed |
| No rate limiting | HIGH | Security | 2 hours | 🔴 Not Fixed |
| Weak authorization patterns | HIGH | Security | 3 hours | 🔴 Not Fixed |
| CSV import size limits missing | HIGH | Security | 2 hours | 🔴 Not Fixed |
| No audit logging | HIGH | Compliance | 3 hours | 🔴 Not Fixed |
| No token refresh mechanism | HIGH | Auth | 3 hours | 🔴 Not Fixed |
| Password policy hardcoded | MEDIUM | Config | 2 hours | 🔴 Not Fixed |
| N+1 query issues | MEDIUM | Perf | 1 hour | 🔴 Not Fixed |
| Missing indexes | MEDIUM | Perf | 1 hour | 🔴 Not Fixed |
| No error standardization | MEDIUM | Maintainability | 2 hours | 🔴 Not Fixed |
| Sidekiq not tuned | MEDIUM | Ops | 1 hour | 🔴 Not Fixed |
| No structured logging | MEDIUM | Ops | 2 hours | 🔴 Not Fixed |
| Missing health checks | LOW | Ops | 1 hour | 🔴 Not Fixed |
| No security headers | LOW | Security | 1 hour | 🔴 Not Fixed |

---

## 9. RECOMMENDED IMPLEMENTATION ORDER

### Phase 1: Critical Security (1-2 days)
1. Fix JWT token expiration and validation
2. Enable and configure CORS properly
3. Add rate limiting with Rack::Attack
4. Implement configuration validator

### Phase 2: Authentication & Authorization (1-2 days)
1. Implement refresh tokens
2. Fix authorization patterns (use enums instead of string comparison)
3. Add token revocation
4. Add audit logging

### Phase 3: Data Integrity (1 day)
1. Add input validation for CSV imports
2. Implement size/row limits
3. Add database indexes
4. Fix N+1 query issues

### Phase 4: Operational Readiness (1 day)
1. Add structured logging
2. Configure health check endpoints
3. Add security headers
4. Tune Sidekiq for production

### Phase 5: Documentation & Testing (2 days)
1. Document security architecture
2. Add comprehensive tests for auth/authz
3. Security audit
4. Load testing

---

## 10. DEPLOYMENT CHECKLIST

Before deploying to production:

- [ ] All critical issues fixed
- [ ] Security audit completed
- [ ] Load testing shows acceptable performance
- [ ] Database backups configured and tested
- [ ] Monitoring and alerting configured
- [ ] Log aggregation working
- [ ] CORS origins configured for production
- [ ] SSL/TLS enabled
- [ ] Rate limiting tested
- [ ] Rollback procedure documented
- [ ] Incident response plan created
- [ ] Secrets management verified (no hardcoded values)

---