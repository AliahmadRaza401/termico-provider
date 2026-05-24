# Fix: Imunify360 blocking Tehnico Provider app APIs

## Problem

All API calls from the **Tehnico Provider** mobile app (Flutter) return:

```json
{
  "message": "Access denied by Imunify360 bot-protection. IPs used for automation should be whitelisted"
}
```

The same requests work in **Postman** because Imunify360 treats them differently (different IP/User-Agent).

## Root cause

**Imunify360** (bot protection on the server) is blocking requests from the app. It is a **server-side** setting; the app cannot fix this by itself.

## Solution (server / hosting admin)

Do **one** of the following on the server where **tehnico.md** is hosted (cPanel / Imunify360):

### Option 1: Whitelist API base path (recommended)

- In **Imunify360** → **Bot Protection** / **WAF** settings, add an **allow/whitelist** rule for:
  - Path: `/api/*`  
  - Or full base: `https://tehnico.md/api/*`
- So all API traffic (login, configurations, etc.) is allowed and not checked by bot protection.

### Option 2: Whitelist by User-Agent

- In Imunify360, add an exception for requests where **User-Agent** contains:
  - `TehnicoProvider`
- The app sends: `User-Agent: TehnicoProvider/1.0 (Mobile)`.

### Option 3: Whitelist IPs (only for testing)

- If you only need to test from one place, whitelist that IP in Imunify360.
- Not recommended for production, because real users have different IPs.

## App-side (already done)

The app sends:

- `User-Agent: TehnicoProvider/1.0 (Mobile)`
- `Accept-Language: en-US,en;q=0.9`
- `X-Requested-With: TehnicoProvider`

So the server can safely whitelist by path (**Option 1**) or by User-Agent (**Option 2**).

## Who can apply the fix

Someone with access to:

- **cPanel** (where Imunify360 is installed), or  
- **Imunify360** dashboard / **CloudLinux** panel  

must add the whitelist/exception as above. After that, the app will work without changing app code.
