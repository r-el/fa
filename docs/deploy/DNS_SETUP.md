# DNS Settings

## Records to Set in DNS Manager

### For API (api.specter.live) [server]

```text
Type: CNAME
Host: api
Target: <server-dns-target>
TTL: 300
```

You can get the server `DNS Target` url for the `api` host, in the `Custom Domains` section by running this cammand

```bash
heroku domains -a specter-api
```

### For Main Site (specter.live)

```text
Type: ALIAS (or ANAME if available)
Host: @
Target: hidden-skink-8pnj6uw9f7tao7e6vni7r0ro.herokudns.com
TTL: 300
```

### For www (<www.specter.live>)

```text
Type: CNAME
Host: www
Target: genetic-swordtail-uo9293wit79mj3is268f4xtv.herokudns.com
TTL: 300
```

You can get the client `DNS Target` urls for the `@` and `www` hosts, in the `Custom Domains` section by running this cammand

```bash
heroku domains -a specter-frontend
```

## Setup Instructions

1. Go to DNS Manager for the domain specter.live
2. Remove all existing records for hosts: @, www, api
3. Add the new records according to the table above

## Checking Setup

After DNS configuration (may take up to 24 hours), check:

```bash
# DNS check
nslookup api.specter.live
nslookup specter.live
nslookup www.specter.live

# SSL check after DNS works
curl -I https://api.specter.live/health
curl -I https://specter.live/
```

## Heroku App Names

- **API**: specter-api (Region: eu)
- **Frontend**: specter-frontend (Region: eu)
