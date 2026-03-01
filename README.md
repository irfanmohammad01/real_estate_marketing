# Real Estate Marketing Platform

This document outlines the setup steps required to get both the frontend and backend of the application up and running locally.

## Prerequisites

Ensure you have the following installed on your local machine:
- **Ruby** (check `.ruby-version` in the backend directory)
- **Node.js & npm**
- **PostgreSQL** (Database)
- **Redis** (For Sidekiq and caching/queues, if applicable)

---

## Backend Setup (Ruby on Rails)

The backend is located in the `rem_backend/real_estate_marketing` directory.

### 1. Navigate to the backend directory
From the root of the project:
```bash
cd rem_backend/real_estate_marketing
```

### 2. Install Dependencies
```bash
bundle install
```

### 3. Database Setup
Ensure PostgreSQL is running, then create, migrate, and seed the database:
```bash
rails db:create
rails db:migrate
rails db:seed
```

### 4. Environment Variables
Verify if you need to set up a `.env` file for any local configuration (e.g., database credentials, JWT secret keys, etc.).

### 5. Start the Rails Server
```bash
rails server
```
The backend API will be available at `http://localhost:3000`.

### 6. Background Jobs (Sidekiq)
This project uses Sidekiq for background processing (e.g., campaign emails). Start the Sidekiq worker in a separate terminal:
```bash
bundle exec sidekiq
```

---

## Frontend Setup (React + Vite + TypeScript)

The frontend is located in the `rem_frontend` directory.
Frontend Repository: [https://github.com/jagdish-josh/rem_frontend](https://github.com/jagdish-josh/rem_frontend)

### 1. Navigate to the frontend directory
From the root of the project:
```bash
cd rem_frontend
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Start the Development Server
```bash
npm run dev
```
This will start the Vite development server. Open the URL provided in the terminal (usually `http://localhost:5173`) to view the application in your browser.

---

## Testing

**Backend (RSpec):**
```bash
cd rem_backend/real_estate_marketing
bundle exec rspec
```

**Frontend (Linting and Type Checking):**
```bash
cd rem_frontend
npm run lint
npm run build
```
