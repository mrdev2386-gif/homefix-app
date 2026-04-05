/**
 * OPTIMIZED BROWSER SCRAPER - PROCESS LOCK IMPLEMENTATION
 * 
 * Features:
 * - Process lock prevents overlapping clicks
 * - Proper wait times for data collection
 * - Guaranteed extraction before next click
 * - No fast clicking issues
 * - Leads properly collected
 * 
 * Usage in browser console:
 *   Copy and paste entire script, then call: startLoop()
 */

// ============================================================================
// 1. PROCESS LOCK (CRITICAL)
// ============================================================================

if (!window.isProcessing) window.isProcessing = false;
if (!window.isRunning) window.isRunning = false;
if (!window.collectedLeads) window.collectedLeads = [];

console.log('[INIT] Process lock initialized');
console.log('[INIT] isProcessing:', window.isProcessing);
console.log('[INIT] isRunning:', window.isRunning);

// ============================================================================
// 2. UTILITY FUNCTIONS
// ============================================================================

/**
 * Sleep for specified milliseconds
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Scroll page down to load more results
 */
function scrollDown() {
  console.log('[SCROLL] Scrolling down...');
  window.scrollBy(0, window.innerHeight);
}

/**
 * Get visible card from list of cards
 */
function getVisibleCard(cards) {
  for (let card of cards) {
    const rect = card.getBoundingClientRect();
    if (rect.top >= 0 && rect.top <= window.innerHeight) {
      console.log('[VISIBLE] Found visible card');
      return card;
    }
  }
  
  // If no visible card, return first one
  console.log('[VISIBLE] No visible card, using first');
  return cards[0];
}

/**
 * Real click with proper event dispatch
 */
function realClick(element) {
  if (!element) {
    console.error('[CLICK] Element is null');
    return false;
  }
  
  try {
    // Scroll into view
    element.scrollIntoView({ behavior: 'smooth', block: 'center' });
    
    // Wait for scroll
    setTimeout(() => {
      // Create and dispatch click event
      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        view: window
      });
      
      element.dispatchEvent(clickEvent);
      console.log('[CLICK] Dispatched click event');
    }, 300);
    
    return true;
  } catch (error) {
    console.error('[CLICK] Error:', error.message);
    return false;
  }
}

/**
 * Wait for profile name to load (CRITICAL)
 */
async function waitForName() {
  console.log('[WAIT] Waiting for profile name...');
  
  for (let i = 0; i < 15; i++) {
    // Try multiple selectors for name
    let el = document.querySelector('h1');
    let name = el?.innerText;
    
    // Fallback selectors
    if (!name) {
      el = document.querySelector('[class*="name"]');
      name = el?.innerText;
    }
    
    if (!name) {
      el = document.querySelector('[class*="title"]');
      name = el?.innerText;
    }
    
    // Validate name
    if (name && name.length > 2) {
      console.log('[WAIT] ✅ Name found:', name);
      return name;
    }
    
    console.log(`[WAIT] Attempt ${i + 1}/15 - name not ready, waiting...`);
    await sleep(400);
  }
  
  console.log('[WAIT] ❌ Name not found after 15 attempts');
  return null;
}

/**
 * Extract lead data from profile
 */
async function extractLeadData() {
  console.log('[EXTRACT] Extracting lead data...');
  
  const lead = {
    name: null,
    phone: null,
    email: null,
    address: null,
    website: null,
    rating: null,
    reviews: null,
    url: window.location.href,
    scrapedAt: new Date().toISOString()
  };
  
  try {
    // Extract name
    let nameEl = document.querySelector('h1');
    lead.name = nameEl?.innerText?.trim();
    
    // Extract phone
    let phoneEl = document.querySelector('[href^="tel:"]');
    if (phoneEl) {
      lead.phone = phoneEl.getAttribute('href').replace('tel:', '').trim();
    }
    
    // Extract email
    let emailEl = document.querySelector('[href^="mailto:"]');
    if (emailEl) {
      lead.email = emailEl.getAttribute('href').replace('mailto:', '').trim();
    }
    
    // Extract address
    let addressEl = document.querySelector('[class*="address"]');
    lead.address = addressEl?.innerText?.trim();
    
    // Extract website
    let websiteEl = document.querySelector('[href*="http"]');
    if (websiteEl && !websiteEl.href.includes('maps')) {
      lead.website = websiteEl.href;
    }
    
    // Extract rating
    let ratingEl = document.querySelector('[class*="rating"]');
    lead.rating = ratingEl?.innerText?.trim();
    
    // Extract review count
    let reviewsEl = document.querySelector('[class*="review"]');
    lead.reviews = reviewsEl?.innerText?.trim();
    
    console.log('[EXTRACT] ✅ Data extracted:', lead);
    return lead;
  } catch (error) {
    console.error('[EXTRACT] Error:', error.message);
    return lead;
  }
}

/**
 * Validate lead has required data
 */
function isValidLead(lead) {
  // Must have name
  if (!lead.name || lead.name.length < 2) {
    console.log('[VALIDATE] ❌ Invalid: No name');
    return false;
  }
  
  // Must have at least one contact method
  if (!lead.phone && !lead.email && !lead.website && !lead.address) {
    console.log('[VALIDATE] ❌ Invalid: No contact info');
    return false;
  }
  
  console.log('[VALIDATE] ✅ Valid lead');
  return true;
}

/**
 * Check if lead already collected
 */
function isDuplicateLead(lead) {
  const exists = window.collectedLeads.some(existing => 
    existing.name === lead.name && existing.phone === lead.phone
  );
  
  if (exists) {
    console.log('[DUPLICATE] ❌ Lead already collected');
    return true;
  }
  
  console.log('[DUPLICATE] ✅ New lead');
  return false;
}

/**
 * Save lead to collection
 */
function saveLead(lead) {
  window.collectedLeads.push(lead);
  console.log(`[SAVE] ✅ Lead saved (Total: ${window.collectedLeads.length})`);
  
  // Log to console for verification
  console.table(lead);
  
  // Save to localStorage as backup
  try {
    localStorage.setItem('scraped_leads', JSON.stringify(window.collectedLeads));
    console.log('[SAVE] Backed up to localStorage');
  } catch (error) {
    console.warn('[SAVE] Could not save to localStorage:', error.message);
  }
}

/**
 * Export collected leads
 */
function exportLeads() {
  const dataStr = JSON.stringify(window.collectedLeads, null, 2);
  const dataBlob = new Blob([dataStr], { type: 'application/json' });
  const url = URL.createObjectURL(dataBlob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `leads_${new Date().getTime()}.json`;
  link.click();
  console.log('[EXPORT] ✅ Leads exported');
}

/**
 * Get current stats
 */
function getStats() {
  return {
    totalCollected: window.collectedLeads.length,
    isProcessing: window.isProcessing,
    isRunning: window.isRunning,
    leads: window.collectedLeads
  };
}

// ============================================================================
// 3. STEP FUNCTION (CORE LOGIC)
// ============================================================================

/**
 * Single step: Click → Wait → Extract → Validate → Save
 * 
 * CRITICAL FLOW:
 * 1. Find visible card
 * 2. Scroll into view
 * 3. Click to open profile
 * 4. WAIT for profile to load (800ms)
 * 5. WAIT for name to appear (up to 6 seconds)
 * 6. Extract all data
 * 7. Validate data
 * 8. Check for duplicates
 * 9. Save lead
 * 10. Return to list
 */
async function step() {
  console.log('\n========== STEP START ==========');
  
  // Find cards
  const cards = document.querySelectorAll('.Nv2PK');
  
  if (!cards.length) {
    console.log('[STEP] No cards found, scrolling...');
    scrollDown();
    return;
  }
  
  console.log(`[STEP] Found ${cards.length} cards`);
  
  // Get visible card
  const target = getVisibleCard(cards);
  
  if (!target) {
    console.log('[STEP] No visible card');
    return;
  }
  
  // Scroll into view
  console.log('[STEP] Scrolling card into view...');
  target.scrollIntoView({ block: 'center' });
  
  // Wait for scroll animation
  await sleep(800);
  
  // Find clickable element
  const clickable = target.querySelector('a');
  
  if (!clickable) {
    console.log('[STEP] ❌ No clickable element → skip');
    return;
  }
  
  // Click to open profile
  console.log('[STEP] Clicking to open profile...');
  realClick(clickable);
  
  // CRITICAL: Wait for panel to load
  console.log('[STEP] Waiting for profile panel to load...');
  await sleep(1200);
  
  // CRITICAL: Wait for name to appear
  const name = await waitForName();
  
  if (!name) {
    console.log('[STEP] ❌ No name found → skip');
    return;
  }
  
  console.log(`[STEP] ✅ Profile loaded: ${name}`);
  
  // Extract all data
  const lead = await extractLeadData();
  
  // Validate lead
  if (!isValidLead(lead)) {
    console.log('[STEP] ❌ Invalid lead → skip');
    return;
  }
  
  // Check for duplicates
  if (isDuplicateLead(lead)) {
    console.log('[STEP] ❌ Duplicate → skip');
    return;
  }
  
  // Save lead
  saveLead(lead);
  
  // Close profile (click back or press Escape)
  console.log('[STEP] Closing profile...');
  document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
  
  await sleep(500);
  
  console.log('========== STEP END ==========\n');
}

// ============================================================================
// 4. MAIN LOOP (WITH PROCESS LOCK)
// ============================================================================

/**
 * Main loop with process lock
 * 
 * CRITICAL FEATURES:
 * - Checks isProcessing before each step
 * - Sets isProcessing = true during step
 * - Sets isProcessing = false after step
 * - Prevents overlapping clicks
 * - Ensures data collection completes
 */
async function startLoop() {
  console.log('\n╔════════════════════════════════════════╗');
  console.log('║  BROWSER SCRAPER - OPTIMIZED LOOP    ║');
  console.log('║  Process Lock: ENABLED               ║');
  console.log('║  Click Prevention: ACTIVE            ║');
  console.log('╚════════════════════════════════════════╝\n');
  
  window.isRunning = true;
  
  let stepCount = 0;
  
  while (window.isRunning) {
    stepCount++;
    
    // ========== CRITICAL: CHECK LOCK ==========
    if (window.isProcessing) {
      console.log(`[LOOP] Step ${stepCount}: Processing in progress, waiting...`);
      await sleep(500);
      continue;
    }
    
    // ========== CRITICAL: ACQUIRE LOCK ==========
    window.isProcessing = true;
    console.log(`[LOOP] Step ${stepCount}: Lock acquired, starting step...`);
    
    try {
      // Execute step
      await step();
    } catch (error) {
      console.error(`[LOOP] Step ${stepCount} error:`, error.message);
    }
    
    // ========== CRITICAL: RELEASE LOCK ==========
    window.isProcessing = false;
    console.log(`[LOOP] Step ${stepCount}: Lock released`);
    
    // Wait before next step
    console.log('[LOOP] Waiting 1500ms before next step...');
    await sleep(1500);
  }
  
  console.log('\n╔════════════════════════════════════════╗');
  console.log('║  LOOP STOPPED                        ║');
  console.log(`║  Total steps: ${stepCount}                      ║`);
  console.log(`║  Leads collected: ${window.collectedLeads.length}                  ║`);
  console.log('╚════════════════════════════════════════╝\n');
}

/**
 * Stop the loop
 */
function stopLoop() {
  window.isRunning = false;
  console.log('[STOP] Loop stopped');
  console.log(`[STOP] Total leads collected: ${window.collectedLeads.length}`);
}

/**
 * Pause the loop (can resume)
 */
function pauseLoop() {
  window.isRunning = false;
  console.log('[PAUSE] Loop paused');
}

/**
 * Resume the loop
 */
function resumeLoop() {
  if (!window.isRunning) {
    startLoop();
  }
}

// ============================================================================
// 5. CONTROL COMMANDS
// ============================================================================

console.log('\n╔════════════════════════════════════════╗');
console.log('║  AVAILABLE COMMANDS                  ║');
console.log('╠════════════════════════════════════════╣');
console.log('║  startLoop()      - Start scraping   ║');
console.log('║  stopLoop()       - Stop scraping    ║');
console.log('║  pauseLoop()      - Pause scraping   ║');
console.log('║  resumeLoop()     - Resume scraping  ║');
console.log('║  getStats()       - Show stats       ║');
console.log('║  exportLeads()    - Export as JSON   ║');
console.log('║  window.collectedLeads - View leads  ║');
console.log('╚════════════════════════════════════════╝\n');

console.log('✅ Scraper ready! Type: startLoop()');
