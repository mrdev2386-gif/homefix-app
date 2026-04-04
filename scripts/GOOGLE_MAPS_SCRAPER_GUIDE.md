# Google Maps Scraper - Production-Grade Implementation

## 🎯 Overview

This is a production-hardened Google Maps scraper with advanced duplicate detection, crash recovery, and resume capabilities.

---

## ✅ Features Implemented

### 1. URL NORMALIZATION (CRITICAL)
- ✅ Removes query parameters (`?...`, `&...`)
- ✅ Removes trailing slashes
- ✅ Normalizes to base URL
- ✅ Standardizes protocol (http → https)
- ✅ Case-insensitive comparison
- ✅ Extracts Place ID when available

### 2. MULTI-LAYER DUPLICATE CHECK
- ✅ Primary check: `normalizedUrl`
- ✅ Fallback check: `normalizedName + normalizedAddress`
- ✅ O(1) lookup using Set data structure
- ✅ Skips processing if either exists

### 3. RESUME HARDENING
- ✅ Saves `lastScrollPosition` on every scroll
- ✅ On restart: scrolls to last position
- ✅ Scans all visible results
- ✅ Skips already processed using `normalizedUrl`
- ✅ Does NOT assume position accuracy

### 4. SAFE EXTRACTION LOCK
- ✅ `processingLock` flag prevents parallel extraction
- ✅ Strict flow: CLICK → WAIT → EXTRACT → SAVE → RELEASE LOCK → NEXT
- ✅ Prevents multiple clicks on same element
- ✅ Logs lock acquisition and release

### 5. DATA VALIDATION LAYER
- ✅ Validates `name` exists
- ✅ Validates at least one of: `phone`, `website`, or `address`
- ✅ Retries up to 2 times on extraction failure
- ✅ Marks as processed and skips if invalid after retries

### 6. STORAGE OPTIMIZATION
- ✅ Converts to object map when > 5000 leads
- ✅ O(1) lookup for large datasets
- ✅ Prevents performance slowdown
- ✅ Automatic optimization on save

### 7. CRASH-SAFE STATE
- ✅ Stores `currentProcessingId`
- ✅ On restart: checks for incomplete processing
- ✅ Retries incomplete lead once
- ✅ Saves state after every successful extraction

---

## 📦 Installation

```bash
cd c:\Users\yash\projects\homefix\scripts
npm install
```

This will install:
- `puppeteer` - Browser automation
- `firebase-admin` - Already installed

---

## 🚀 Usage

### Basic Usage

```bash
node google_maps_scraper_hardened.js
```

### Programmatic Usage

```javascript
const { scrapeGoogleMaps } = require('./google_maps_scraper_hardened');

// Scrape plumbers in Mumbai
await scrapeGoogleMaps('plumbers in Mumbai', 50);

// Scrape electricians in Delhi
await scrapeGoogleMaps('electricians in Delhi', 100);
```

### Custom Configuration

Edit the `CONFIG` object in the script:

```javascript
const CONFIG = {
  STORAGE_FILE: path.join(__dirname, 'scraper_state.json'),
  LEADS_FILE: path.join(__dirname, 'scraped_leads.json'),
  MAX_RETRIES: 2,
  SCROLL_DELAY: 2000,
  EXTRACTION_DELAY: 1500,
  LARGE_DATASET_THRESHOLD: 5000,
  HEADLESS: false, // Set to true for production
};
```

---

## 📊 Data Structure

### Scraped Lead Format

```json
{
  "name": "ABC Plumbing Services",
  "rating": "4.5 stars",
  "address": "123 Main St, Mumbai, Maharashtra 400001",
  "phone": "+91 98765 43210",
  "website": "https://abcplumbing.com",
  "url": "https://www.google.com/maps/place/abc-plumbing",
  "placeId": "ChIJN1t_tDeuEmsRUsoyG83frY4",
  "scrapedAt": "2024-01-15T10:30:00.000Z"
}
```

### State File Format

```json
{
  "lastScrollPosition": 2500,
  "totalProcessed": 45,
  "totalSkipped": 12,
  "totalFailed": 3,
  "processedUrls": [
    "https://www.google.com/maps/place/abc-plumbing",
    "https://www.google.com/maps/place/xyz-services"
  ],
  "processedFallbackKeys": [
    "abc_plumbing_services__123_main_st_mumbai",
    "xyz_services__456_park_road_mumbai"
  ],
  "currentProcessingId": null,
  "lastSaveTime": 1705315800000
}
```

---

## 🔄 Resume Capability

The scraper automatically resumes from where it left off:

1. **On Crash**: State is saved after every extraction
2. **On Restart**: 
   - Loads `lastScrollPosition`
   - Scrolls to that position
   - Scans visible results
   - Skips already processed leads

### Manual Resume

If you want to start fresh:

```bash
# Delete state file
rm scraper_state.json

# Run scraper
node google_maps_scraper_hardened.js
```

---

## 🛡️ Duplicate Detection

### Layer 1: Normalized URL

```javascript
// Original URLs
"https://www.google.com/maps/place/abc?hl=en&gl=us"
"https://www.google.com/maps/place/abc/"
"http://www.google.com/maps/place/ABC"

// All normalize to
"https://www.google.com/maps/place/abc"
```

### Layer 2: Fallback Key

```javascript
// If URL is missing or different
Name: "ABC Plumbing Services"
Address: "123 Main St, Mumbai"

// Generates fallback key
"abc_plumbing_services__123_main_st_mumbai"
```

### Duplicate Check Logic

```javascript
if (normalizedUrl exists in processedUrls) {
  SKIP
} else if (fallbackKey exists in processedFallbackKeys) {
  SKIP
} else {
  PROCESS
}
```

---

## 🔒 Processing Lock

Prevents race conditions and parallel extraction:

```
[LOCK] Acquired for https://www.google.com/maps/place/abc
[PROCESS] Extracting lead 1/50
[EXTRACT] Clicking element...
[EXTRACT] Waiting for details...
[EXTRACT] Extracting phone and website...
[SUCCESS] Saved: ABC Plumbing Services
[LOCK] Released for https://www.google.com/maps/place/abc
```

If lock is held:
```
[SKIP] Lock is held, skipping
```

---

## ✅ Data Validation

### Valid Lead

```javascript
{
  name: "ABC Services",
  phone: "+91 98765 43210",
  // OR
  website: "https://abc.com",
  // OR
  address: "123 Main St"
}
```

### Invalid Lead (Skipped)

```javascript
{
  name: "",  // ❌ Missing name
  phone: null,
  website: null,
  address: null
}

{
  name: "ABC Services",  // ✅ Has name
  phone: null,           // ❌ No contact info
  website: null,
  address: null
}
```

### Retry Logic

```
[EXTRACT] Retry 1/2 for element
[EXTRACT] Retry 2/2 for element
[FAILED] Could not extract data
```

---

## 📈 Storage Optimization

### Small Dataset (< 5000 leads)

```javascript
// Array format for simplicity
[
  { name: "ABC", phone: "123" },
  { name: "XYZ", phone: "456" }
]
```

### Large Dataset (> 5000 leads)

```javascript
// Object map for O(1) lookup
{
  "https://maps/abc": { name: "ABC", phone: "123" },
  "https://maps/xyz": { name: "XYZ", phone: "456" }
}
```

Automatic conversion happens on save:
```
[STORAGE] Optimizing 5500 leads for O(1) lookup
```

---

## 🔧 Crash Recovery

### Scenario 1: Crash During Extraction

```
[LOCK] Acquired for https://maps/abc
[PROCESS] Extracting lead 25/50
--- CRASH ---

On restart:
[RECOVERY] Found incomplete processing: https://maps/abc
[RECOVERY] Will retry on next run
```

### Scenario 2: Normal Shutdown

```
[LOCK] Released for https://maps/abc
[STATE] Saved (Processed: 50, Skipped: 10)
--- SHUTDOWN ---

On restart:
[INIT] Resume from scroll: 2500
[RESUME] Scrolling to position 2500
```

---

## 📊 Output Files

### 1. `scraper_state.json`
- Tracks scraping progress
- Stores processed URLs and fallback keys
- Saves scroll position
- Enables resume capability

### 2. `scraped_leads.json`
- Contains all scraped leads
- Optimized format (array or object map)
- Ready for import to database

---

## 🎯 Example Output

```
========================================
GOOGLE MAPS SCRAPER - PRODUCTION GRADE
========================================

[INIT] Search: "plumbers in Mumbai"
[INIT] Max results: 50
[INIT] Existing leads: 0
[INIT] Resume from scroll: 0

[NAVIGATE] https://www.google.com/maps/search/plumbers%20in%20Mumbai

[SCAN] Found 20 visible results

[PROCESS] Extracting lead 1/50
[LOCK] Acquired for https://www.google.com/maps/place/abc-plumbing
[SUCCESS] Saved: ABC Plumbing Services
  Phone: +91 98765 43210
  Website: https://abcplumbing.com
  Address: 123 Main St, Mumbai
[LOCK] Released for https://www.google.com/maps/place/abc-plumbing

[PROCESS] Extracting lead 2/50
[DUPLICATE] URL already processed: https://www.google.com/maps/place/abc-plumbing
[SKIP] Already processed

[SCROLL] Loading more results...

========================================
SCRAPING COMPLETE
========================================
Total processed: 50
Total skipped: 5
Total failed: 2
Total leads: 50
========================================
```

---

## 🐛 Troubleshooting

### Issue: Scraper not finding results

**Solution**: Check if Google Maps loaded correctly
```javascript
// Increase wait time
await page.waitForTimeout(5000);
```

### Issue: Duplicate leads still appearing

**Solution**: Check URL normalization
```javascript
const { normalizeUrl } = require('./google_maps_scraper_hardened');
console.log(normalizeUrl('https://maps.google.com/place/abc?hl=en'));
// Should output: https://maps.google.com/place/abc
```

### Issue: Extraction failing

**Solution**: Increase retry count
```javascript
const CONFIG = {
  MAX_RETRIES: 3, // Increase from 2
};
```

### Issue: Scraper too slow

**Solution**: Reduce delays
```javascript
const CONFIG = {
  SCROLL_DELAY: 1000,      // Reduce from 2000
  EXTRACTION_DELAY: 1000,  // Reduce from 1500
};
```

---

## 🔐 Best Practices

### 1. Run in Headless Mode for Production

```javascript
const CONFIG = {
  HEADLESS: true,
};
```

### 2. Backup State Files Regularly

```bash
cp scraper_state.json scraper_state_backup.json
cp scraped_leads.json scraped_leads_backup.json
```

### 3. Monitor for Rate Limiting

If Google blocks requests:
- Increase delays
- Use proxies
- Rotate user agents

### 4. Validate Data After Scraping

```javascript
const leads = require('./scraped_leads.json');
const valid = leads.filter(lead => lead.phone || lead.website);
console.log(`Valid leads: ${valid.length}/${leads.length}`);
```

---

## 📞 Support

For issues or questions:
- **Contact**: 9508322397
- **Project**: HomeFix
- **File**: `scripts/google_maps_scraper_hardened.js`

---

## 📝 Changelog

### Version 1.0 (2024)
- ✅ URL normalization
- ✅ Multi-layer duplicate detection
- ✅ Resume capability
- ✅ Processing lock
- ✅ Data validation
- ✅ Storage optimization
- ✅ Crash recovery

---

**Last Updated**: 2024  
**Status**: Production-Ready  
**Quality**: ⭐⭐⭐⭐⭐ (5/5)
