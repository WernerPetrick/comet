module Comet
  class HydrationManager
    def self.generate_client_script
      <<~JAVASCRIPT
        // Comet Hydration System
        (function() {
          'use strict';
          
          const CometHydration = {
            shards: new Map(),
            observers: new Map(),
            
            // Initialize hydration system
            init() {
              this.registerShards();
              this.setupIntersectionObserver();
              this.hydrateImmediate();
              
              // Handle different hydration strategies
              if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => this.hydrateOnLoad());
              } else {
                this.hydrateOnLoad();
              }
            },
            
            // Register all shards found on the page
            registerShards() {
              const shardElements = document.querySelectorAll('[data-shard]');
              
              shardElements.forEach(element => {
                const shardName = element.dataset.shard;
                const strategy = element.dataset.hydrate;
                const props = JSON.parse(element.dataset.props || '{}');
                
                this.shards.set(element.id, {
                  element,
                  name: shardName,
                  strategy,
                  props,
                  hydrated: false
                });
              });
              
              console.log(`🧩 Found ${this.shards.size} shards to hydrate`);
            },
            
            // Setup intersection observer for 'visible' strategy
            setupIntersectionObserver() {
              if ('IntersectionObserver' in window) {
                this.intersectionObserver = new IntersectionObserver(
                  (entries) => {
                    entries.forEach(entry => {
                      if (entry.isIntersecting) {
                        const shardData = this.shards.get(entry.target.id);
                        if (shardData && shardData.strategy === 'visible' && !shardData.hydrated) {
                          this.hydrateShard(entry.target.id);
                        }
                      }
                    });
                  },
                  { threshold: 0.1 }
                );
              }
            },
            
            // Hydrate shards with 'load' strategy immediately
            hydrateImmediate() {
              this.shards.forEach((shardData, id) => {
                if (shardData.strategy === 'immediate') {
                  this.hydrateShard(id);
                }
              });
            },
            
            // Hydrate shards with 'load' strategy after DOM is ready
            hydrateOnLoad() {
              this.shards.forEach((shardData, id) => {
                if (shardData.strategy === 'load') {
                  this.hydrateShard(id);
                } else if (shardData.strategy === 'visible' && this.intersectionObserver) {
                  this.intersectionObserver.observe(shardData.element);
                }
              });
            },
            
            // Hydrate a specific shard
            hydrateShard(shardId) {
              const shardData = this.shards.get(shardId);
              if (!shardData || shardData.hydrated) return;
              
              console.log(`💧 Hydrating shard: ${shardData.name} (${shardData.strategy})`);
              
              try {
                // Look for a hydration function for this shard
                const hydrateFunction = window[`hydrate_${shardData.name.replace('-', '_')}`];
                
                if (typeof hydrateFunction === 'function') {
                  hydrateFunction(shardData.element, shardData.props);
                } else {
                  // Default hydration behavior
                  this.defaultHydration(shardData);
                }
                
                shardData.hydrated = true;
                shardData.element.dataset.hydrated = 'true';
                
                // Stop observing if using intersection observer
                if (this.intersectionObserver && shardData.strategy === 'visible') {
                  this.intersectionObserver.unobserve(shardData.element);
                }
                
              } catch (error) {
                console.error(`❌ Error hydrating shard ${shardData.name}:`, error);
              }
            },
            
            // Default hydration behavior
            defaultHydration(shardData) {
              // Add event listeners for common interactive elements
              const { element, props } = shardData;
              
              // Buttons
              const buttons = element.querySelectorAll('button[data-action]');
              buttons.forEach(button => {
                const action = button.dataset.action;
                button.addEventListener('click', (e) => {
                  this.handleAction(action, e, props);
                });
              });
              
              // Forms
              const forms = element.querySelectorAll('form[data-action]');
              forms.forEach(form => {
                const action = form.dataset.action;
                form.addEventListener('submit', (e) => {
                  this.handleAction(action, e, props);
                });
              });
              
              // Links with actions
              const links = element.querySelectorAll('a[data-action]');
              links.forEach(link => {
                const action = link.dataset.action;
                link.addEventListener('click', (e) => {
                  e.preventDefault();
                  this.handleAction(action, e, props);
                });
              });
            },
            
            // Handle data-action attributes
            handleAction(action, event, props) {
              // Emit custom event
              const actionEvent = new CustomEvent('comet:action', {
                detail: { action, event, props }
              });
              document.dispatchEvent(actionEvent);
              
              // Look for global action handler
              if (window.CometActions && typeof window.CometActions[action] === 'function') {
                window.CometActions[action](event, props);
              }
            },
            
            // Public API for manual hydration
            hydrateAll() {
              this.shards.forEach((_, id) => this.hydrateShard(id));
            },
            
            // Public API to get shard data
            getShard(id) {
              return this.shards.get(id);
            }
          };
          
          // Initialize when script loads
          CometHydration.init();
          
          // Expose to global scope
          window.CometHydration = CometHydration;
          
          // Initialize global actions object
          window.CometActions = window.CometActions || {};
          
        })();
      JAVASCRIPT
    end
  end
end
