// Comet + Tailwind CSS JavaScript

// Define actions that can be triggered by shards
window.CometActions = {
	// Example action for button clicks
	signup: (event, props) => {
		// Create Tailwind notification
		const notification = document.createElement("div");
		notification.className =
			"fixed top-4 right-4 bg-green-500 text-white px-6 py-4 rounded-lg shadow-lg z-50 transform translate-x-full transition-transform duration-300 ease-in-out";
		notification.innerHTML = `
      <div class="flex items-center justify-between">
        <span>Thanks for clicking "${props.text || "the button"}"!</span>
        <button class="ml-4 text-white hover:text-gray-200" onclick="this.parentElement.parentElement.remove()">
          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
          </svg>
        </button>
      </div>
    `;

		document.body.appendChild(notification);

		// Animate in
		setTimeout(() => {
			notification.classList.remove("translate-x-full");
		}, 100);

		// Auto-hide after 4 seconds
		setTimeout(() => {
			notification.classList.add("translate-x-full");
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
		const menu = document.getElementById(button.getAttribute("aria-controls"));

		if (menu) {
			const isOpen = !menu.classList.contains("hidden");

			if (isOpen) {
				menu.classList.add("hidden");
				button.setAttribute("aria-expanded", "false");
			} else {
				menu.classList.remove("hidden");
				button.setAttribute("aria-expanded", "true");
			}
		}
	},

	// Modal handling
	openModal: (event, props) => {
		const modalId = props.modal || "default-modal";
		const modal = document.getElementById(modalId);
		if (modal) {
			modal.classList.remove("hidden");
			modal.classList.add("flex");
			document.body.style.overflow = "hidden";
		}
	},

	closeModal: (event, props) => {
		const modalId = props.modal || event.target.closest('[id$="modal"]').id;
		const modal = document.getElementById(modalId);
		if (modal) {
			modal.classList.add("hidden");
			modal.classList.remove("flex");
			document.body.style.overflow = "auto";
		}
	},

	// Tab switching
	switchTab: (event, props) => {
		const tabId = props.tab;
		const groupId = props.group || "default";

		// Hide all tabs in group
		const allTabs = document.querySelectorAll(`[data-tab-group="${groupId}"]`);
		for (const tab of allTabs) {
			tab.classList.add("hidden");
		}

		// Remove active state from all tab buttons
		const allButtons = document.querySelectorAll(
			`[data-tab-button-group="${groupId}"]`,
		);
		for (const button of allButtons) {
			button.classList.remove("bg-comet-primary", "text-white");
			button.classList.add("text-gray-600", "hover:text-gray-800");
		}

		// Show target tab
		const targetTab = document.getElementById(tabId);
		if (targetTab) {
			targetTab.classList.remove("hidden");
		}

		// Activate button
		const button = event.target.closest("button");
		button.classList.add("bg-comet-primary", "text-white");
		button.classList.remove("text-gray-600", "hover:text-gray-800");
	},
};

// Listen for custom Comet actions
document.addEventListener("comet:action", (event) => {
	console.log("Comet action triggered:", event.detail);
});

// Initialize components on page load
document.addEventListener("DOMContentLoaded", () => {
	// Close dropdowns when clicking outside
	document.addEventListener("click", (event) => {
		const dropdowns = document.querySelectorAll("[data-dropdown]");
		for (const dropdown of dropdowns) {
			if (!dropdown.contains(event.target)) {
				const menu = dropdown.querySelector("[data-dropdown-menu]");
				if (menu) {
					menu.classList.add("hidden");
				}
			}
		}
	});

	// Handle dropdown toggles
	const dropdownButtons = document.querySelectorAll("[data-dropdown-toggle]");
	for (const button of dropdownButtons) {
		button.addEventListener("click", (event) => {
			event.stopPropagation();
			const dropdown = button.closest("[data-dropdown]");
			const menu = dropdown.querySelector("[data-dropdown-menu]");
			if (menu) {
				menu.classList.toggle("hidden");
			}
		});
	}
});

// Custom hydration function for Tailwind forms
window.hydrate_tailwind_form = (element, props) => {
	console.log("Hydrating Tailwind form", element, props);

	const form = element.querySelector("form");
	if (form) {
		form.addEventListener("submit", (e) => {
			e.preventDefault();

			// Add loading state to submit button
			const submitBtn = form.querySelector('button[type="submit"]');
			if (submitBtn) {
				const originalText = submitBtn.innerHTML;
				submitBtn.innerHTML =
					'<div class="spinner-comet mr-2"></div>Loading...';
				submitBtn.disabled = true;
				submitBtn.classList.add("opacity-75", "cursor-not-allowed");

				// Simulate form submission
				setTimeout(() => {
					submitBtn.innerHTML = originalText;
					submitBtn.disabled = false;
					submitBtn.classList.remove("opacity-75", "cursor-not-allowed");

					// Show success notification
					CometActions.signup(e, { text: "Form submitted successfully!" });
				}, 1500);
			}
		});

		// Add real-time validation styling
		const inputs = form.querySelectorAll("input, textarea, select");
		for (const input of inputs) {
			input.addEventListener("blur", () => {
				if (input.checkValidity()) {
					input.classList.remove("border-red-500", "ring-red-500");
					input.classList.add("border-green-500", "ring-green-500");
				} else {
					input.classList.remove("border-green-500", "ring-green-500");
					input.classList.add("border-red-500", "ring-red-500");
				}
			});

			input.addEventListener("focus", () => {
				input.classList.remove("border-red-500", "border-green-500");
				input.classList.add("ring-2", "ring-purple-500", "border-purple-500");
			});

			input.addEventListener("blur", () => {
				input.classList.remove(
					"ring-2",
					"ring-purple-500",
					"border-purple-500",
				);
			});
		}
	}
};
