/**
 * PRODUCTION-GRADE GOOGLE MAPS SCRAPER
 * 
 * Features:
 * - URL normalization for duplicate detection
 * - Multi-layer duplicate checking (URL + name+address)
 * - Resume capability with scroll position tracking
 * - Safe extraction with processing lock
 * - Data validation with retry logic
 * - Storage optimization for large datasets
 * - Crash-safe state management
 * 
 * Usage:
 *   node scripts/google_maps_scraper_hardened.js
 */

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

// ==========================================
// CONFIGURATION
// ==========================================

const CONFIG = {
  STORAGE_FILE: path.join(__dirname, 'scraper_state.json'),
  LEADS_FILE: path.join(__dirname, 'scraped_leads.json'),
  MAX_RETRIES: 2,
  SCROLL_DELAY: 2000,
  EXTRACTION_DELAY: 1500,
  LARGE_DATASET_THRESHOLD: 5000,
  HEADLESS: false, // Set to true for production
};

// ==========================================
// 1. URL NORMALIZATION (CRITICAL)
// ==========================================

/**
 * Normalize Google Maps URL to base form
 * Removes query params, trailing slashes, and standardizes format
 */
function normalizeUrl(url) {
  if (!url) return null;
  
  try {
    // Remove query parameters and hash
    let normalized = url.split('?')[0].split('#')[0];
    
    // Remove trailing slashes
    normalized = normalized.replace(/\/+$/, '');
    
    // Standardize protocol
    normalized = normalized.replace(/^http:/, 'https:');
    
    return normalized.toLowerCase().trim();
  } catch (error) {
    console.error('[URL NORMALIZE] Error:', error.message);
    return null;
  }
}

/**
 * Extract place ID from Google Maps URL if available
 */
function extractPlaceId(url) {
  if (!url) return null;
  
  const placeIdMatch = url.match(/!1s([^!]+)/);
  return placeIdMatch ? placeIdMatch[1] : null;
}

// ==========================================
// 2. MULTI-LAYER DUPLICATE CHECK
// ==========================================

/**
 * Generate fallback unique key from name and address
 */
function generateFallbackKey(name, address) {
  if (!name) return null;
  
  const normalizedName = name.toLowerCase().trim().replace(/\s+/g, '_');
  const normalizedAddress = address ? address.toLowerCase().trim().replace(/\s+/g, '_') : '';
  
  return `${normalizedName}__${normalizedAddress}`;
}

/**
 * Check if lead is duplicate using multi-layer approach
 */
function isDuplicate(lead, state) {
  const normalizedUrl = normalizeUrl(lead.url);
  const fallbackKey = generateFallbackKey(lead.name, lead.address);
  
  // Check normalized URL
  if (normalizedUrl && state.processedUrls.has(normalizedUrl)) {
    console.log(`[DUPLICATE] URL already processed: ${normalizedUrl}`);
    return true;
  }
  
  // Check fallback key
  if (fallbackKey && state.processedFallbackKeys.has(fallbackKey)) {
    console.log(`[DUPLICATE] Fallback key already processed: ${fallbackKey}`);
    return true;
  }
  
  return false;
}

/**
 * Mark lead as processed in state
 */
function markAsProcessed(lead, state) {
  const normalizedUrl = normalizeUrl(lead.url);
  const fallbackKey = generateFallbackKey(lead.name, lead.address);
  
  if (normalizedUrl) {
    state.processedUrls.add(normalizedUrl);
  }
  
  if (fallbackKey) {
    state.processedFallbackKeys.add(fallbackKey);
  }
}

// ==========================================
// 3. STORAGE OPTIMIZATION
// ==========================================

/**
 * Convert Set to Array for JSON serialization
 */
function serializeState(state) {
  return {
    ...state,
    processedUrls: Array.from(state.processedUrls),
    processedFallbackKeys: Array.from(state.processedFallbackKeys),
  };
}

/**
 * Convert Array back to Set for O(1) lookup
 */
function deserializeState(data) {
  return {
    ...data,
    processedUrls: new Set(data.processedUrls || []),
    processedFallbackKeys: new Set(data.processedFallbackKeys || []),
  };
}

/**
 * Optimize storage for large datasets
 * Convert array to object map if threshold exceeded
 */
function optimizeStorage(leads) {
  if (leads.length > CONFIG.LARGE_DATASET_THRESHOLD) {
    console.log(`[STORAGE] Optimizing ${leads.length} leads for O(1) lookup`);
    
    const leadsMap = {};
    leads.forEach(lead => {
      const key = normalizeUrl(lead.url) || generateFallbackKey(lead.name, lead.address);
      if (key) {
        leadsMap[key] = lead;
      }
    });
    
    return leadsMap;
  }
  
  return leads;
}

// ==========================================
// 4. STATE MANAGEMENT
// ==========================================

/**
 * Load scraper state from disk
 */
function loadState() {
  try {
    if (fs.existsSync(CONFIG.STORAGE_FILE)) {
      const data = JSON.parse(fs.readFileSync(CONFIG.STORAGE_FILE, 'utf8'));
      console.log('[STATE] Loaded existing state');
      return deserializeState(data);
    }
  } catch (error) {
    console.error('[STATE] Error loading state:', error.message);
  }
  
  // Return default state
  return {
    lastScrollPosition: 0,
    totalProcessed: 0,
    totalSkipped: 0,
    totalFailed: 0,
    processedUrls: new Set(),
    processedFallbackKeys: new Set(),
    currentProcessingId: null,
    lastSaveTime: Date.now(),
  };
}

/**
 * Save scraper state to disk
 */
function saveState(state) {
  try {
    const serialized = serializeState(state);
    fs.writeFileSync(CONFIG.STORAGE_FILE, JSON.stringify(serialized, null, 2));
    console.log(`[STATE] Saved (Processed: ${state.totalProcessed}, Skipped: ${state.totalSkipped})`);
  } catch (error) {
    console.error('[STATE] Error saving state:', error.message);
  }
}

/**
 * Load scraped leads from disk
 */
function loadLeads() {
  try {
    if (fs.existsSync(CONFIG.LEADS_FILE)) {
      const data = JSON.parse(fs.readFileSync(CONFIG.LEADS_FILE, 'utf8'));
      console.log(`[LEADS] Loaded ${Array.isArray(data) ? data.length : Object.keys(data).length} existing leads`);
      return data;
    }
  } catch (error) {
    console.error('[LEADS] Error loading leads:', error.message);
  }
  
  return [];
}

/**
 * Save scraped leads to disk
 */
function saveLeads(leads) {
  try {
    const optimized = optimizeStorage(Array.isArray(leads) ? leads : Object.values(leads));
    fs.writeFileSync(CONFIG.LEADS_FILE, JSON.stringify(optimized, null, 2));
    console.log(`[LEADS] Saved ${Array.isArray(optimized) ? optimized.length : Object.keys(optimized).length} leads`);
  } catch (error) {
    console.error('[LEADS] Error saving leads:', error.message);
  }
}

// ==========================================
// 5. DATA VALIDATION LAYER
// ==========================================

/**
 * Validate lead data before saving
 */
function validateLead(lead) {
  // Must have name
  if (!lead.name || lead.name.trim() === '') {
    return { valid: false, reason: 'Missing name' };
  }
  
  // Must have at least one contact method
  if (!lead.phone && !lead.website && !lead.address) {
    return { valid: false, reason: 'No contact information' };
  }
  
  return { valid: true };
}

// ==========================================
// 6. SAFE EXTRACTION WITH LOCK
// ==========================================

class ExtractionLock {
  constructor() {
    this.locked = false;
    this.currentId = null;
  }
  
  acquire(id) {
    if (this.locked) {
      console.warn(`[LOCK] Already processing ${this.currentId}, cannot acquire for ${id}`);
      return false;
    }
    
    this.locked = true;
    this.currentId = id;
    console.log(`[LOCK] Acquired for ${id}`);
    return true;
  }
  
  release() {
    if (this.locked) {
      console.log(`[LOCK] Released for ${this.currentId}`);
      this.locked = false;
      this.currentId = null;
    }
  }
  
  isLocked() {
    return this.locked;
  }
}

// ==========================================
// 7. SCRAPER IMPLEMENTATION
// ==========================================

/**
 * Extract lead data from a single result card
 */
async function extractLeadData(page, element, retryCount = 0) {
  try {
    // Extract basic info
    const name = await element.$eval('[class*="fontHeadlineSmall"]', el => el.textContent.trim()).catch(() => null);
    const rating = await element.$eval('[class*="fontBodyMedium"] span[role="img"]', el => el.getAttribute('aria-label')).catch(() => null);
    const address = await element.$eval('[class*="fontBodyMedium"]:nth-of-type(2)', el => el.textContent.trim()).catch(() => null);
    
    // Get URL
    const url = await element.$eval('a', el => el.href).catch(() => null);
    
    // Click to get more details
    await element.click();
    await page.waitForTimeout(CONFIG.EXTRACTION_DELAY);
    
    // Extract phone and website
    const phone = await page.$eval('[data-item-id*="phone"]', el => el.textContent.trim()).catch(() => null);
    const website = await page.$eval('[data-item-id*="authority"]', el => el.getAttribute('href')).catch(() => null);
    
    return {
      name,
      rating,
      address,
      phone,
      website,
      url: normalizeUrl(url),
      placeId: extractPlaceId(url),
      scrapedAt: new Date().toISOString(),
    };
  } catch (error) {
    if (retryCount < CONFIG.MAX_RETRIES) {
      console.warn(`[EXTRACT] Retry ${retryCount + 1}/${CONFIG.MAX_RETRIES} for element`);
      await page.waitForTimeout(1000);
      return extractLeadData(page, element, retryCount + 1);
    }
    
    console.error('[EXTRACT] Failed after retries:', error.message);
    return null;
  }
}

/**
 * Scroll to load more results
 */
async function scrollResults(page, scrollPosition = 0) {
  try {
    const scrollableDiv = await page.$('[role="feed"]');
    
    if (scrollableDiv) {
      // Scroll to last position
      await page.evaluate((div, pos) => {
        div.scrollTop = pos;
      }, scrollableDiv, scrollPosition);
      
      await page.waitForTimeout(CONFIG.SCROLL_DELAY);
      
      // Get new scroll position
      const newPosition = await page.evaluate(div => div.scrollTop, scrollableDiv);
      
      return newPosition;
    }
  } catch (error) {
    console.error('[SCROLL] Error:', error.message);
  }
  
  return scrollPosition;
}

/**
 * Main scraper function
 */
async function scrapeGoogleMaps(searchQuery, maxResults = 100) {
  console.log('========================================');
  console.log('GOOGLE MAPS SCRAPER - PRODUCTION GRADE');
  console.log('========================================\n');
  
  // Load state and leads
  const state = loadState();
  const leads = loadLeads();
  const lock = new ExtractionLock();
  
  console.log(`[INIT] Search: "${searchQuery}"`);
  console.log(`[INIT] Max results: ${maxResults}`);
  console.log(`[INIT] Existing leads: ${Array.isArray(leads) ? leads.length : Object.keys(leads).length}`);
  console.log(`[INIT] Resume from scroll: ${state.lastScrollPosition}\n`);
  
  const browser = await puppeteer.launch({
    headless: CONFIG.HEADLESS,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 800 });
  
  try {
    // Navigate to Google Maps
    const searchUrl = `https://www.google.com/maps/search/${encodeURIComponent(searchQuery)}`;
    console.log(`[NAVIGATE] ${searchUrl}`);
    await page.goto(searchUrl, { waitUntil: 'networkidle2' });
    
    await page.waitForTimeout(3000);
    
    // Resume from last scroll position
    if (state.lastScrollPosition > 0) {
      console.log(`[RESUME] Scrolling to position ${state.lastScrollPosition}`);
      await scrollResults(page, state.lastScrollPosition);
    }
    
    let processedCount = 0;
    let scrollAttempts = 0;
    const maxScrollAttempts = 50;
    
    while (processedCount < maxResults && scrollAttempts < maxScrollAttempts) {
      // Get all visible results
      const results = await page.$$('[role="feed"] > div > div > a');
      console.log(`\n[SCAN] Found ${results.length} visible results`);
      
      for (const result of results) {
        if (processedCount >= maxResults) break;
        
        // Check if already processing
        if (lock.isLocked()) {
          console.warn('[SKIP] Lock is held, skipping');
          continue;
        }
        
        try {
          // Get URL for duplicate check
          const url = await result.evaluate(el => el.href);
          const normalizedUrl = normalizeUrl(url);
          
          // Check if already processed
          if (normalizedUrl && state.processedUrls.has(normalizedUrl)) {
            console.log(`[SKIP] Already processed: ${normalizedUrl}`);
            state.totalSkipped++;
            continue;
          }
          
          // Acquire lock
          if (!lock.acquire(normalizedUrl || 'unknown')) {
            continue;
          }
          
          // Set current processing ID for crash recovery
          state.currentProcessingId = normalizedUrl;
          saveState(state);
          
          // Extract data
          console.log(`\n[PROCESS] Extracting lead ${processedCount + 1}/${maxResults}`);
          const leadData = await extractLeadData(page, result);
          
          if (!leadData) {
            console.error('[FAILED] Could not extract data');
            state.totalFailed++;
            lock.release();
            state.currentProcessingId = null;
            continue;
          }
          
          // Validate data
          const validation = validateLead(leadData);
          if (!validation.valid) {
            console.warn(`[INVALID] ${validation.reason}`);
            state.totalFailed++;
            lock.release();
            state.currentProcessingId = null;
            continue;
          }
          
          // Check for duplicates (multi-layer)
          if (isDuplicate(leadData, state)) {
            state.totalSkipped++;
            lock.release();
            state.currentProcessingId = null;
            continue;
          }
          
          // Save lead
          leads.push(leadData);
          markAsProcessed(leadData, state);
          state.totalProcessed++;
          processedCount++;
          
          console.log(`[SUCCESS] Saved: ${leadData.name}`);
          console.log(`  Phone: ${leadData.phone || 'N/A'}`);
          console.log(`  Website: ${leadData.website || 'N/A'}`);
          console.log(`  Address: ${leadData.address || 'N/A'}`);
          
          // Save progress
          saveLeads(leads);
          saveState(state);
          
          // Release lock
          lock.release();
          state.currentProcessingId = null;
          
        } catch (error) {
          console.error('[ERROR] Processing result:', error.message);
          state.totalFailed++;
          lock.release();
          state.currentProcessingId = null;
        }
      }
      
      // Scroll to load more
      console.log('\n[SCROLL] Loading more results...');
      const newScrollPosition = await scrollResults(page, state.lastScrollPosition);
      
      if (newScrollPosition === state.lastScrollPosition) {
        console.log('[SCROLL] No more results to load');
        break;
      }
      
      state.lastScrollPosition = newScrollPosition;
      saveState(state);
      scrollAttempts++;
    }
    
    console.log('\n========================================');
    console.log('SCRAPING COMPLETE');
    console.log('========================================');
    console.log(`Total processed: ${state.totalProcessed}`);
    console.log(`Total skipped: ${state.totalSkipped}`);
    console.log(`Total failed: ${state.totalFailed}`);
    console.log(`Total leads: ${leads.length}`);
    console.log('========================================\n');
    
  } catch (error) {
    console.error('\n[FATAL ERROR]', error);
    
    // Save state even on crash
    saveState(state);
    saveLeads(leads);
    
  } finally {
    await browser.close();
  }
}

// ==========================================
// 8. CRASH RECOVERY
// ==========================================

/**
 * Check for incomplete processing and retry
 */
async function checkCrashRecovery() {
  const state = loadState();
  
  if (state.currentProcessingId) {
    console.log(`[RECOVERY] Found incomplete processing: ${state.currentProcessingId}`);
    console.log('[RECOVERY] Will retry on next run');
    
    // Clear the processing ID
    state.currentProcessingId = null;
    saveState(state);
  }
}

// ==========================================
// MAIN EXECUTION
// ==========================================

async function main() {
  // Check for crash recovery
  await checkCrashRecovery();
  
  // Example usage
  const searchQuery = 'plumbers in Mumbai';
  const maxResults = 50;
  
  await scrapeGoogleMaps(searchQuery, maxResults);
}

// Run if executed directly
if (require.main === module) {
  main().catch(error => {
    console.error('[FATAL]', error);
    process.exit(1);
  });
}

module.exports = {
  scrapeGoogleMaps,
  normalizeUrl,
  generateFallbackKey,
  validateLead,
};
