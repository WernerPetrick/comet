module Comet
  class HydrationManager
    def self.generate_client_script
      <<~JAVASCRIPT
        // Comet Hydration (Stimulus Transitional Layer)
        (function() {
          'use strict';

          const CometHydration = {
            shards: new Map(),
            init() {
              this.scan();
              this.observeVisible();
              this.runImmediate();
              if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => this.runOnLoad());
              } else {
                this.runOnLoad();
              }
              // Re-run after Turbo (if present)
              document.addEventListener('turbo:load', () => this.rescan());
            },
            rescan() {
              this.shards.clear();
              this.scan();
              this.runImmediate();
              this.runOnLoad();
            },
            scan() {
              document.querySelectorAll('[data-shard]').forEach(el => {
                const props = safeJSON(el.dataset.props);
                this.shards.set(el.id, {
                  el,
                  name: el.dataset.shard,
                  strategy: el.dataset.hydrate || 'load',
                  props,
                  hydrated: el.dataset.hydrated === 'true'
                });
                if (!el.hasAttribute('data-controller')) {
                  el.setAttribute('data-controller', 'comet-shard');
                }
              });
              console.log(`[Comet] shards registered: ${this.shards.size}`);
            },
            observeVisible() {
              if (!('IntersectionObserver' in window)) return;
              this.io = new IntersectionObserver(entries => {
                entries.forEach(entry => {
                  if (!entry.isIntersecting) return;
                  const data = this.shards.get(entry.target.id);
                  if (data && data.strategy === 'visible' && !data.hydrated) this.hydrate(entry.target.id);
                });
              }, { threshold: 0.1 });
            },
            runImmediate() {
              this.shards.forEach((d, id) => { if (d.strategy === 'immediate') this.hydrate(id); });
            },
            runOnLoad() {
              this.shards.forEach((d, id) => {
                if (d.strategy === 'load') this.hydrate(id);
                else if (d.strategy === 'visible' && this.io) this.io.observe(d.el);
              });
            },
            hydrate(id) {
              const d = this.shards.get(id);
              if (!d || d.hydrated) return;
              // Fire lifecycle event for Stimulus or plain listeners
              d.el.dispatchEvent(new CustomEvent('comet:hydrate', { detail: { id, props: d.props } }));
              // Legacy global hook support
              const fn = window[`hydrate_${d.name.replace(/-/g,'_')}`];
              if (typeof fn === 'function') {
                try { fn(d.el, d.props); } catch(e){ console.error(e); }
              }
              d.hydrated = true;
              d.el.dataset.hydrated = 'true';
              if (this.io && d.strategy === 'visible') this.io.unobserve(d.el);
            },
            hydrateAll(){ this.shards.forEach((_,id)=>this.hydrate(id)); }
          };

          function safeJSON(str){ try { return JSON.parse(str||'{}'); } catch(_e){ return {}; } }

          // Stimulus controller auto-registration (if Stimulus already loaded via CDN)
          function registerStimulus(){
            if (!window.Stimulus) return;
            if (registerStimulus._done) return; // idempotent
            registerStimulus._done = true;
            window.Stimulus.register('comet-shard', class extends Stimulus.Controller {
              connect(){
                // If already hydrated, skip; else wait for event
                if (this.element.dataset.hydrated === 'true') return;
                this.element.addEventListener('comet:hydrate', (e)=>{
                  // Place for per-shard custom logic via data-action or data-* attributes
                  // Example: data-action="click->comet-shard#toggle"
                }, { once: true });
              }
            });
          }

          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', registerStimulus);
          } else { registerStimulus(); }

          CometHydration.init();
          window.CometHydration = CometHydration;
        })();
      JAVASCRIPT
    end
  end
end
