// Comet Custom Framework JavaScript

// Define actions that can be triggered by shards
window.CometActions = {
	// Example action for button clicks
	signup: (event, props) => {
		// Create custom notification
		const notification = document.createElement("div");
		notification.className = "notification";
		notification.innerHTML = `
      <div class="notification-content">
        <span>Thanks for clicking "${props.text || "the button"}"!</span>
        <button class="notification-close" onclick="this.parentElement.parentElement.remove()">×</button>
      </div>
    `;

		// Add notification styles
		notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: linear-gradient(135deg, var(--comet-accent) 0%, #38a169 100%);
      color: white;
      padding: 1rem 1.5rem;
      border-radius: var(--radius-lg);
      box-shadow: var(--shadow-lg);
      z-index: 1000;
      transform: translateX(100%);
      transition: transform 0.3s ease;
      max-width: 300px;
    `;

		notification.querySelector(".notification-content").style.cssText = `
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
    `;

		notification.querySelector(".notification-close").style.cssText = `
      background: none;
      border: none;
      color: white;
      font-size: 1.5rem;
      cursor: pointer;
      padding: 0;
      margin: 0;
      line-height: 1;
    `;

		document.body.appendChild(notification);

		// Animate in
		setTimeout(() => {
			notification.style.transform = "translateX(0)";
		}, 100);

		// Auto-hide after 4 seconds
		setTimeout(() => {
			notification.style.transform = "translateX(100%)";
			setTimeout(() => {
				if (notification.parentNode) {
					notification.parentNode.removeChild(notification);
				}
			}, 300);
		}, 4000);
	},

	// Toggle mobile menu
	toggleMobileMenu: (event) => {
		const button = event.target.closest("button");
		const menuId = button.getAttribute("data-menu-target");
		const menu = document.getElementById(menuId);

		if (menu) {
			const isHidden = menu.style.display === "none" || !menu.style.display;

			if (isHidden) {
				menu.style.display = "block";
				button.setAttribute("aria-expanded", "true");
			} else {
				menu.style.display = "none";
				button.setAttribute("aria-expanded", "false");
			}
		}
	},

	// Modal handling
	openModal: (event, props) => {
		const modalId = props.modal || "default-modal";
		const modal = document.getElementById(modalId);
		if (modal) {
			modal.style.display = "flex";
			document.body.style.overflow = "hidden";
		}
	},

	closeModal: (event, props) => {
		const modalId = props.modal || event.target.closest(".modal").id;
		const modal = document.getElementById(modalId);
		if (modal) {
			modal.style.display = "none";
			document.body.style.overflow = "auto";
		}
	},

	// Accordion toggle
	toggleAccordion: (event, props) => {
		const button = event.target.closest("button");
		const content = button.nextElementSibling;
		const isOpen = content.style.display === "block";

		// Close all accordions in the same group if specified
		if (props.group) {
			const groupAccordions = document.querySelectorAll(
				`[data-accordion-group="${props.group}"]`,
			);
			for (const accordion of groupAccordions) {
				const accordionContent = accordion.nextElementSibling;
				accordionContent.style.display = "none";
				accordion.setAttribute("aria-expanded", "false");
			}
		}

		if (!isOpen) {
			content.style.display = "block";
			button.setAttribute("aria-expanded", "true");
		} else {
			content.style.display = "none";
			button.setAttribute("aria-expanded", "false");
		}
	},

	// Tooltip handling
	showTooltip: (event, props) => {
		const element = event.target;
		const tooltipText = props.text || element.getAttribute("data-tooltip");

		if (!tooltipText) return;

		const tooltip = document.createElement("div");
		tooltip.className = "tooltip";
		tooltip.textContent = tooltipText;
		tooltip.style.cssText = `
      position: absolute;
      background: var(--comet-dark);
      color: white;
      padding: 0.5rem;
      border-radius: var(--radius-md);
      font-size: 0.875rem;
      z-index: 1000;
      pointer-events: none;
      white-space: nowrap;
      box-shadow: var(--shadow-lg);
    `;

		document.body.appendChild(tooltip);

		const rect = element.getBoundingClientRect();
		tooltip.style.left = `${rect.left + rect.width / 2 - tooltip.offsetWidth / 2}px`;
		tooltip.style.top = `${rect.top - tooltip.offsetHeight - 8}px`;

		element._tooltip = tooltip;
	},

	hideTooltip: (event) => {
		const element = event.target;
		if (element._tooltip) {
			element._tooltip.remove();
			element._tooltip = undefined;
		}
	},
};

// Listen for custom Comet actions
document.addEventListener("comet:action", (event) => {
	console.log("Comet action triggered:", event.detail);
});

// Initialize components on page load
document.addEventListener("DOMContentLoaded", () => {
	// Initialize tooltips
	const tooltipElements = document.querySelectorAll("[data-tooltip]");
	for (const element of tooltipElements) {
		element.addEventListener("mouseenter", CometActions.showTooltip);
		element.addEventListener("mouseleave", CometActions.hideTooltip);
	}

	// Initialize dropdowns
	const dropdownButtons = document.querySelectorAll("[data-dropdown-toggle]");
	for (const button of dropdownButtons) {
		button.addEventListener("click", (event) => {
			event.stopPropagation();
			const targetId = button.getAttribute("data-dropdown-toggle");
			const menu = document.getElementById(targetId);

			if (menu) {
				const isHidden = menu.style.display === "none" || !menu.style.display;

				// Close all other dropdowns
				const allDropdowns = document.querySelectorAll("[data-dropdown]");
				for (const dropdown of allDropdowns) {
					if (dropdown !== menu) {
						dropdown.style.display = "none";
					}
				}

				menu.style.display = isHidden ? "block" : "none";
			}
		});
	}

	// Close dropdowns when clicking outside
	document.addEventListener("click", () => {
		const dropdowns = document.querySelectorAll("[data-dropdown]");
		for (const dropdown of dropdowns) {
			dropdown.style.display = "none";
		}
	});

	// Prevent dropdown close when clicking inside
	const dropdowns = document.querySelectorAll("[data-dropdown]");
	for (const dropdown of dropdowns) {
		dropdown.addEventListener("click", (event) => {
			event.stopPropagation();
		});
	}
});

// Custom hydration function for custom framework forms
window.hydrate_custom_form = (element, props) => {
	console.log("Hydrating custom form", element, props);

	const form = element.querySelector("form");
	if (form) {
		form.addEventListener("submit", (e) => {
			e.preventDefault();

			// Add loading state to submit button
			const submitBtn = form.querySelector('button[type="submit"]');
			if (submitBtn) {
				const originalText = submitBtn.innerHTML;
				submitBtn.innerHTML =
					'<div class="spinner" style="margin-right: 0.5rem;"></div>Loading...';
				submitBtn.disabled = true;
				submitBtn.style.opacity = "0.7";

				// Simulate form submission
				setTimeout(() => {
					submitBtn.innerHTML = originalText;
					submitBtn.disabled = false;
					submitBtn.style.opacity = "1";

					// Show success notification
					CometActions.signup(e, { text: "Form submitted successfully!" });
				}, 1500);
			}
		});

		// Add real-time validation
		const inputs = form.querySelectorAll("input, textarea, select");
		for (const input of inputs) {
			input.addEventListener("blur", () => {
				if (input.checkValidity()) {
					input.classList.remove("is-invalid");
					input.classList.add("is-valid");
				} else {
					input.classList.remove("is-valid");
					input.classList.add("is-invalid");
				}
			});

			input.addEventListener("input", () => {
				// Remove validation classes while typing
				input.classList.remove("is-valid", "is-invalid");
			});
		}
	}
};

// Utility functions
window.CometUtils = {
	// Smooth scroll to element
	scrollTo: (elementId, offset = 0) => {
		const element = document.getElementById(elementId);
		if (element) {
			const y =
				element.getBoundingClientRect().top + window.pageYOffset + offset;
			window.scrollTo({ top: y, behavior: "smooth" });
		}
	},

	// Copy text to clipboard
	copyToClipboard: (text) => {
		navigator.clipboard.writeText(text).then(() => {
			CometActions.signup(
				{ target: document.body },
				{ text: "Copied to clipboard!" },
			);
		});
	},

	// Debounce function
	debounce: (func, wait) => {
		let timeout;
		return function executedFunction(...args) {
			const later = () => {
				clearTimeout(timeout);
				func(...args);
			};
			clearTimeout(timeout);
			timeout = setTimeout(later, wait);
		};
	},
};
