/****************************************************************************
 * SECTION: SMOOTHFOX                                                       *
****************************************************************************/
// recommended for 60hz+ displays
user_pref("apz.overscroll.enabled", true); // DEFAULT NON-LINUX
user_pref("general.smoothScroll", true); // DEFAULT
user_pref("mousewheel.default.delta_multiplier_y", 275); // 250-400; adjust this number to your liking

/****************************************************************************
 * MY OVERRIDES                                                             *
 * https://github.com/yokoffing/Betterfox/wiki/Common-Overrides            *
 * https://github.com/yokoffing/Betterfox/wiki/Optional-Hardening          *
****************************************************************************/

// PREF: disable the Firefox View tour from popping up
user_pref("browser.firefox-view.feature-tour", "{\"screen\":\"\",\"complete\":true}");

// PREF: disable login manager
user_pref("signon.rememberSignons", false);

// PREF: disable address and credit card manager
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.creditCards.enabled", false);

// PREF: disable passkeys
user_pref("security.webauth.webauthn", false);

// PREF: hide site shortcut thumbnails on New Tab page
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);

// PREF: hide weather on New Tab page
user_pref("browser.newtabpage.activity-stream.showWeather", false);

// PREF: hide dropdown suggestions when clicking on the address bar
user_pref("browser.urlbar.suggest.topsites", false);

// PREF: ask whether to open or save new file types
user_pref("browser.download.always_ask_before_handling_new_types", true);

// PREF: enforce certificate pinning
// [ERROR] MOZILLA_PKIX_ERROR_KEY_PINNING_FAILURE
// 1 = allow user MiTM (such as your antivirus) (default)
// 2 = strict
user_pref("security.cert_pinning.enforcement_level", 2);

// PREF: delete cookies, cache, and site data on shutdown
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
user_pref("privacy.clearOnShutdown_v2.browsingHistoryAndDownloads", false); // Browsing & download history
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", true); // Cookies and site data
user_pref("privacy.clearOnShutdown_v2.cache", true); // Temporary cached files and pages
user_pref("privacy.clearOnShutdown_v2.formdata", true); // Saved form info

// PREF: disable service workers
// This will break push notifications (blocked in Betterfox by default).
user_pref("dom.serviceWorkers.enabled", false);
user_pref("dom.serviceWorkers.privateBrowsing.enabled", false);

// PREF: disable JIT optimization
// This removes most of the attack surface while keeping JIT compilation.
user_pref("javascript.options.ion", false);
user_pref("javascript.options.wasm_optimizingjit", false);

// PREF: disable captive portal detection
// [WARNING] Do NOT use for mobile devices!
user_pref("captivedetect.canonicalURL", "");
user_pref("network.captive-portal-service.enabled", false);
user_pref("network.connectivity-service.enabled", false);

// PREF: Disable Built-In VPN
user_pref("browser.ipProtection.enabled", false);
user_pref("browser.ipProtection.added", false);
