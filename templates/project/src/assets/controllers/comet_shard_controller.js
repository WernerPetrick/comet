// Generic fallback controller: runs for any shard without a more specific controller.
(() => {
	if (!window.Stimulus) return;
	// Reuse a singleton application instance
	if (!window.__COMET_STIMULUS_APP__) {
		window.__COMET_STIMULUS_APP__ = window.Stimulus.Application.start();
	}
	const app = window.__COMET_STIMULUS_APP__;
	app.register(
		"comet-shard",
		class extends window.Stimulus.Controller {
			connect() {
				this.element.addEventListener(
					"comet:hydrate",
					() => {
						/* generic hook */
					},
					{ once: true },
				);
			}
		},
	);
})();
