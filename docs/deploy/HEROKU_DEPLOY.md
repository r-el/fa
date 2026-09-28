# Heroku Deploy Docs

## Heroku Deploy

### Create the client and server apps

#### Check Heroku CLI version

```bash
heroku --version
```

#### Check Heroku Auth

```bash
heroku auth:whoami
```

#### Create new apps at eu region

```bash
heroku create specter-api --region eu
heroku create specter-frontend --region eu
```

#### Add custom domains

```bash
heroku domains:add api.specter.live -a specter-api
heroku domains:add api.specter.live -a specter-api
heroku domains:add www.specter.live -a specter-frontend
```

#### Set production environment variables

##### For server

```bash
# Basic environment
heroku config:set NODE_ENV=production -a specter-api

# CORS settings
heroku config:set ALLOWED_ORIGINS=https://specter.live,https://www.specter.live -a specter-api

# Authentication settings
heroku config:set JWT_SECRET=your-super-secret-jwt-key-here -a specter-api
heroku config:set BCRYPT_SALT_ROUNDS=10 -a specter-api

# Supabase configuration (REQUIRED)
heroku config:set SUPABASE_URL=your-supabase-project-url -a specter-api
heroku config:set SUPABASE_KEY=your-supabase-anon-key -a specter-api


# Server settings
heroku config:set PORT=3000 -a specter-api
```

**Important Notes:**

- Replace `your-supabase-project-url` with your actual Supabase project URL
- Replace `your-supabase-anon-key` with your Supabase anonymous key
- Generate a strong JWT secret (recommended: 32+ random characters)

##### For client

```bash
heroku config:set NODE_ENV=production -a specter-frontend
heroku config:set REACT_APP_API_URL=https://api.specter.live -a specter-frontend
```

#### Enable SSL certificates

```bash
# Enable automatic SSL for API
heroku certs:auto:enable -a specter-api

# Enable automatic SSL for frontend  
heroku certs:auto:enable -a specter-frontend
```

#### Verify SSL status

```bash
# Check API SSL
heroku certs -a specter-api

# Check frontend SSL
heroku certs -a specter-frontend
```

#### DNS information

##### To check the DNS information that needs to be configured

###### DNS for server

```bash
heroku domains -a specter-api
```

###### DNS for client

```bash
heroku domains -a specter-frontend
```

#### Add Heroku remotes to Git

Add remotes for both applications:

```bash
# Add server remote
heroku git:remote -a specter-api -r heroku-server

# Add client remote  
heroku git:remote -a specter-frontend -r heroku-client
```

#### Deploy applications

##### Deploy server

```bash
git push heroku-server `git subtree split --prefix=fs-dashboard/server HEAD`:refs/heads/main --force
```

##### Deploy client

```bash
git push heroku-client `git subtree split --prefix=fs-dashboard/client HEAD`:refs/heads/main --force
```

### Check that the apps are working

#### Check server app

Get the server domain from the DNS information (`heroku domains -a specter-api`)

```bash
curl <server-domain/health>
```

For example

```bash
curl https://specter-api-0a992bc444dd.herokuapp.com/health
```

#### Check client app

Get the server domain from the DNS information (`heroku domains -a specter-frontend`)

```bash
curl <client-domain>
```

For example

```bash
curl https://specter-frontend-2f8031e1bcc2.herokuapp.com/
```

#### DNS configuration

Instructions for setting up DNS are in the [docs/deploy/DNS_SETUP.md](DNS_SETUP.md) file.
