// Controller for the 'counter' shard
(() => {
	if (!window.Stimulus) return;
	if (!window.__COMET_STIMULUS_APP__) {
		window.__COMET_STIMULUS_APP__ = window.Stimulus.Application.start();
	}
	const app = window.__COMET_STIMULUS_APP__;
	app.register(
		"shard-counter",
		class extends window.Stimulus.Controller {
			static values = { start: Number };
			connect() {
				const wrapperProps = this.readProps();
				// Precedence: explicit props.start > inline data value > 0
				if (wrapperProps.start != null && wrapperProps.start !== "") {
					const n = Number(wrapperProps.start);
					this.count = Number.isNaN(n) ? 0 : n;
				} else if (this.hasStartValue) {
					this.count = this.startValue;
				} else {
					this.count = 0;
				}
				this.render();
			}
			increment() {
				this.count++;
				this.render();
			}
			render() {
				const t = this.element.querySelector('[data-role="count"]');
				if (t) t.textContent = this.count;
			}
			readProps() {
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
