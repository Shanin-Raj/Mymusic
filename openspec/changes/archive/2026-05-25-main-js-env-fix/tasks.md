## 1. Update `main.js`

- [x] 1.1 Open `d:\music\backend\main.js`.
- [x] 1.2 Add the following line at the very top (Line 1):
```javascript
require('dotenv').config({ path: require('path').join(__dirname, '.env') });
```

## 2. Verification

- [ ] 2.1 Run `node d:\music\backend\main.js` and verify it prompts for a Spotify URL without crashing immediately due to Telegram credentials.
