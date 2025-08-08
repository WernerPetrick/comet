// Props viewer controller: shows shard props JSON inside <pre>
(() => {
	if (!window.Stimulus) return;
	if (!window.__COMET_STIMULUS_APP__) {
		window.__COMET_STIMULUS_APP__ = window.Stimulus.Application.start();
	}
	const app = window.__COMET_STIMULUS_APP__;
	app.register(
		"shard-props-viewer",
		class extends window.Stimulus.Controller {
			connect() {
				const pre = this.element.querySelector("pre");
				if (pre) pre.textContent = JSON.stringify(this._props(), null, 2);
			}
			_props() {
				const wrap = this.element.closest("[data-shard]");
				if (!wrap) return {};
				try {
					return JSON.parse(wrap.dataset.props || "{}");
				} catch (_) {
					return {};
				}
			}
		},
	);
})();
