// Analytics & Performance Monitoring Setup
// This file provides privacy-friendly analytics using a self-hosted solution

(function() {
  'use strict';

  // Configuration
  const config = {
    enabled: true,
    debug: false,
    endpoint: '/api/analytics', // Replace with your analytics endpoint
    sessionTimeout: 30 * 60 * 1000, // 30 minutes
    trackingEvents: {
      pageView: true,
      clicks: true,
      scrollDepth: true,
      timeOnPage: true,
      flashDealViews: true,
      offerInteractions: true
    }
  };

  // Analytics Object
  const FlashFeedAnalytics = {
    sessionId: null,
    startTime: Date.now(),
    lastActivity: Date.now(),
    scrollDepth: 0,
    events: [],

    // Initialize analytics
    init: function() {
      if (!config.enabled) return;

      this.sessionId = this.getOrCreateSession();
      this.trackPageView();
      this.setupEventListeners();
      this.trackWebVitals();

      if (config.debug) {
        console.log('FlashFeed Analytics initialized', this.sessionId);
      }
    },

    // Session management
    getOrCreateSession: function() {
      const stored = localStorage.getItem('ff_session');
      if (stored) {
        const session = JSON.parse(stored);
        if (Date.now() - session.lastActivity < config.sessionTimeout) {
          session.lastActivity = Date.now();
          localStorage.setItem('ff_session', JSON.stringify(session));
          return session.id;
        }
      }

      const newSession = {
        id: this.generateId(),
        startTime: Date.now(),
        lastActivity: Date.now()
      };
      localStorage.setItem('ff_session', JSON.stringify(newSession));
      return newSession.id;
    },

    // Generate unique ID
    generateId: function() {
      return 'ff_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    },

    // Track page view
    trackPageView: function() {
      if (!config.trackingEvents.pageView) return;

      this.sendEvent('page_view', {
        url: window.location.href,
        title: document.title,
        referrer: document.referrer,
        screenResolution: window.screen.width + 'x' + window.screen.height,
        viewport: window.innerWidth + 'x' + window.innerHeight,
        userAgent: navigator.userAgent,
        language: navigator.language
      });
    },

    // Track custom event
    trackEvent: function(eventName, data) {
      this.sendEvent(eventName, data);
    },

    // Setup event listeners
    setupEventListeners: function() {
      const self = this;

      // Track clicks
      if (config.trackingEvents.clicks) {
        document.addEventListener('click', function(e) {
          const target = e.target;
          const data = {
            tagName: target.tagName,
            className: target.className,
            id: target.id,
            href: target.href || null,
            text: target.textContent?.substring(0, 50)
          };

          // Special tracking for Flash Deals
          if (target.closest('.flash-deal-card')) {
            self.trackEvent('flash_deal_click', data);
          } else if (target.closest('.offer-card')) {
            self.trackEvent('offer_click', data);
          } else {
            self.trackEvent('click', data);
          }
        });
      }

      // Track scroll depth
      if (config.trackingEvents.scrollDepth) {
        let maxScroll = 0;
        window.addEventListener('scroll', function() {
          const scrollPercent = Math.round(
            (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100
          );
          if (scrollPercent > maxScroll) {
            maxScroll = scrollPercent;
            if (maxScroll % 25 === 0) {
              self.trackEvent('scroll_depth', { depth: maxScroll });
            }
          }
        });
      }

      // Track time on page
      if (config.trackingEvents.timeOnPage) {
        window.addEventListener('beforeunload', function() {
          const timeOnPage = Math.round((Date.now() - self.startTime) / 1000);
          self.trackEvent('time_on_page', { seconds: timeOnPage });
        });
      }

      // Track visibility change
      document.addEventListener('visibilitychange', function() {
        self.trackEvent('visibility_change', {
          hidden: document.hidden,
          timestamp: Date.now()
        });
      });
    },

    // Track Web Vitals
    trackWebVitals: function() {
      if (!window.PerformanceObserver) return;

      // First Contentful Paint (FCP)
      try {
        const observer = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            if (entry.name === 'first-contentful-paint') {
              this.trackEvent('web_vitals', {
                metric: 'FCP',
                value: Math.round(entry.startTime)
              });
            }
          }
        });
        observer.observe({ entryTypes: ['paint'] });
      } catch (e) {
        console.error('Failed to track paint metrics:', e);
      }

      // Largest Contentful Paint (LCP)
      try {
        const observer = new PerformanceObserver((list) => {
          const entries = list.getEntries();
          const lastEntry = entries[entries.length - 1];
          this.trackEvent('web_vitals', {
            metric: 'LCP',
            value: Math.round(lastEntry.startTime)
          });
        });
        observer.observe({ entryTypes: ['largest-contentful-paint'] });
      } catch (e) {
        console.error('Failed to track LCP:', e);
      }

      // First Input Delay (FID)
      try {
        const observer = new PerformanceObserver((list) => {
          const firstInput = list.getEntries()[0];
          this.trackEvent('web_vitals', {
            metric: 'FID',
            value: Math.round(firstInput.processingStart - firstInput.startTime)
          });
        });
        observer.observe({ entryTypes: ['first-input'] });
      } catch (e) {
        console.error('Failed to track FID:', e);
      }
    },

    // Send event to analytics endpoint
    sendEvent: function(eventType, data) {
      const event = {
        type: eventType,
        sessionId: this.sessionId,
        timestamp: Date.now(),
        data: data
      };

      this.events.push(event);

      // In production, send to analytics endpoint
      if (config.endpoint && !config.debug) {
        fetch(config.endpoint, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(event)
        }).catch(err => {
          if (config.debug) {
            console.error('Analytics error:', err);
          }
        });
      }

      // Debug mode - log to console
      if (config.debug) {
        console.log('Analytics Event:', event);
      }
    },

    // Public API for Flutter integration
    flutter: {
      trackScreen: function(screenName) {
        FlashFeedAnalytics.trackEvent('screen_view', { screen: screenName });
      },
      trackFlashDeal: function(dealId, action) {
        FlashFeedAnalytics.trackEvent('flash_deal', { dealId: dealId, action: action });
      },
      trackOffer: function(offerId, action) {
        FlashFeedAnalytics.trackEvent('offer', { offerId: offerId, action: action });
      },
      trackSearch: function(query, resultsCount) {
        FlashFeedAnalytics.trackEvent('search', { query: query, results: resultsCount });
      },
      trackRetailer: function(retailerId, action) {
        FlashFeedAnalytics.trackEvent('retailer', { retailerId: retailerId, action: action });
      }
    }
  };

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      FlashFeedAnalytics.init();
    });
  } else {
    FlashFeedAnalytics.init();
  }

  // Expose to global scope for Flutter integration
  window.FlashFeedAnalytics = FlashFeedAnalytics;

})();