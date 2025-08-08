// Comet + Bulma JavaScript

// Define actions that can be triggered by shards
window.CometActions = {
	// Example action for button clicks
	signup: (event, props) => {
		// Show Bulma notification
		const notification = document.createElement("div");
		notification.className = "notification is-success";
		notification.innerHTML = `
      <button class="delete"></button>
      Thanks for clicking "${props.text || "the button"}"!
    `;

		document.body.appendChild(notification);

		// Auto-hide after 3 seconds
		setTimeout(() => {
			if (notification.parentNode) {
				notification.parentNode.removeChild(notification);
			}
		}, 3000);

		// Handle delete button
		notification.querySelector(".delete").addEventListener("click", () => {
			notification.parentNode.removeChild(notification);
		});
	},

	// Toggle mobile menu
	toggleMobileMenu: (event) => {
		const burger = event.target;
		const target = document.getElementById(burger.dataset.target);

		burger.classList.toggle("is-active");
		target.classList.toggle("is-active");
	},

	// Modal handling
	openModal: (event, props) => {
		const modalId = props.modal || "default-modal";
		const modal = document.getElementById(modalId);
		if (modal) {
			modal.classList.add("is-active");
		}
	},

	closeModal: (event, props) => {
		const modalId = props.modal || event.target.closest(".modal").id;
		const modal = document.getElementById(modalId);
		if (modal) {
			modal.classList.remove("is-active");
		}
	},
};

// Listen for custom Comet actions
document.addEventListener("comet:action", (event) => {
	console.log("Comet action triggered:", event.detail);
});

// Initialize Bulma components
document.addEventListener("DOMContentLoaded", () => {
	// Initialize burger menus
	const burgers = document.querySelectorAll(".navbar-burger");
	// biome-ignore lint/complexity/noForEach: <explanation>
	burgers.forEach((burger) => {
		burger.addEventListener("click", CometActions.toggleMobileMenu);
	});

	// Close modals when clicking background or close button
	const modals = document.querySelectorAll(".modal");
	// biome-ignore lint/complexity/noForEach: <explanation>
	modals.forEach((modal) => {
		// Close on background click
		modal.querySelector(".modal-background")?.addEventListener("click", () => {
			modal.classList.remove("is-active");
		});

		// Close on close button click
		// biome-ignore lint/complexity/noForEach: <explanation>
		modal.querySelectorAll(".modal-close, .delete").forEach((closeBtn) => {
			closeBtn.addEventListener("click", () => {
				modal.classList.remove("is-active");
			});
		});
	});

	// Initialize dropdowns
	const dropdowns = document.querySelectorAll(".dropdown");
	// biome-ignore lint/complexity/noForEach: <explanation>
	dropdowns.forEach((dropdown) => {
		dropdown.addEventListener("click", (event) => {
			event.stopPropagation();
			dropdown.classList.toggle("is-active");
		});
	});

	// Close dropdowns when clicking outside
	document.addEventListener("click", () => {
		// biome-ignore lint/complexity/noForEach: <explanation>
		dropdowns.forEach((dropdown) => {
			dropdown.classList.remove("is-active");
		});
	});
});

// Custom hydration function for Bulma forms
window.hydrate_bulma_form = (element, props) => {
	console.log("Hydrating Bulma form", element, props);

	const form = element.querySelector("form");
	if (form) {
		form.addEventListener("submit", (e) => {
			e.preventDefault();

			// Add loading state to submit button
			const submitBtn = form.querySelector('button[type="submit"]');
			if (submitBtn) {
				submitBtn.classList.add("is-loading");

				// Simulate form submission
				setTimeout(() => {
					submitBtn.classList.remove("is-loading");

					// Show success notification
					CometActions.signup(e, { text: "Form submitted successfully!" });
				}, 1500);
			}
		});
	}
};
