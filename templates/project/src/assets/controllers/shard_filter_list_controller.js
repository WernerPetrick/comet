// Live filter list shard controller
(() => {
	if (!window.Stimulus) return;
	if (!window.__COMET_STIMULUS_APP__) {
		window.__COMET_STIMULUS_APP__ = window.Stimulus.Application.start();
	}
	const app = window.__COMET_STIMULUS_APP__;
	app.register(
		"shard-filter-list",
		class extends window.Stimulus.Controller {
			connect() {
				this.itemsEl = this.element.querySelector('[data-role="items"]');
				this.inputEl = this.element.querySelector('[data-role="filter-input"]');
				this.emptyEl = this.element.querySelector('[data-role="empty"]');
				this.allItems = this.readItems();
				console.log(
					"[FilterList] connect; items:",
					this.allItems,
					"controller element id:",
					this.element.id,
				);
				if (!this.allItems.length) {
					// Debug: show raw data-props
					const wrap = this.element.closest("[data-shard]");
					console.log(
						"[FilterList] raw data-props:",
						wrap ? wrap.dataset.props : "(no wrap)",
					);
					// Async fallback read after DOM settles
					setTimeout(() => {
						if (!this.allItems.length) {
							const liItems = Array.from(
								this.element.querySelectorAll('[data-role="items"] > li'),
							)
								.map((li) => li.textContent.trim())
								.filter(Boolean);
							if (liItems.length) {
								this.allItems = liItems;
								console.log(
									"[FilterList] recovered items from DOM fallback:",
									this.allItems,
								);
								this.render(this.allItems);
							}
						}
					}, 0);
				}
				this.render(this.allItems);
				if (this.inputEl) {
					this.inputEl.addEventListener("input", () => this.applyFilter());
				}
			}
			readItems() {
				const wrap = this.element.closest("[data-shard]");
				if (!wrap) return [];
				let arr = [];
				// Prefer wrapper data-items (added by shard processor) for reliability
				if (wrap.dataset.items) {
					arr = wrap.dataset.items
						.split("|")
						.map((s) => s.trim())
						.filter(Boolean);
					if (arr.length) return arr;
				}
				try {
					const raw = wrap.dataset.props || "{}";
					const props = JSON.parse(raw);
					arr = props.items || [];
				} catch (e) {
					console.warn("[FilterList] props parse failed", e);
				}
				// Fallback: data-items attribute on the controller element
				if (
					(!Array.isArray(arr) || !arr.length) &&
					this.element.dataset.items
				) {
					arr = this.element.dataset.items
						.split("|")
						.map((s) => s.trim())
						.filter(Boolean);
					console.log("[FilterList] using data-items fallback", arr);
				}
				if (!Array.isArray(arr) || !arr.length) {
					// fallback to any server-rendered li items
					const existing = Array.from(
						this.element.querySelectorAll('[data-role="items"] > li'),
					)
						.map((li) => li.textContent.trim())
						.filter(Boolean);
					if (existing.length) return existing;
				}
				return Array.isArray(arr) ? arr.map(String) : [];
			}
			applyFilter() {
				const raw = this.inputEl ? this.inputEl.value : "";
				const q = (raw || "").trim().toLowerCase();
				console.log(`[FilterList] applyFilter query="${q}"`);
				if (!q) {
					this.render(this.allItems);
					return;
				}
				const filtered = this.allItems.filter((i) =>
					i.toLowerCase().includes(q),
				);
				console.log("[FilterList] filtered:", filtered);
				this.render(filtered, q);
			}
			render(list, highlight) {
				if (!this.itemsEl) return;
				this.itemsEl.innerHTML = "";
				if (!list.length) {
					if (this.emptyEl) this.emptyEl.style.display = "";
					return;
				}
				if (this.emptyEl) this.emptyEl.style.display = "none";
				const frag = document.createDocumentFragment();
				for (const item of list) {
					const li = document.createElement("li");
					li.innerHTML = highlight
						? this._highlight(item, highlight)
						: this._escape(item);
					frag.appendChild(li);
				}
				this.itemsEl.appendChild(frag);
			}
			_highlight(text, needle) {
				const re = new RegExp(`(${this._escapeReg(needle)})`, "ig");
				return this._escape(text).replace(re, "<mark>$1</mark>");
			}
			_escape(str) {
				return String(str).replace(
					/[&<>"']/g,
					(c) =>
						({
							"&": "&amp;",
							"<": "&lt;",
							">": "&gt;",
							'"': "&quot;",
							"'": "&#39;",
						})[c],
				);
			}
			_escapeReg(str) {
				return str.replace(/[.*+?^${}()|[\]\\]/g, (r) => `\\${r}`);
			}
			_debounce(fn, ms) {
				let t;
				return (...a) => {
					clearTimeout(t);
					t = setTimeout(() => fn.apply(this, a), ms);
				};
			}
		},
	);
})();
