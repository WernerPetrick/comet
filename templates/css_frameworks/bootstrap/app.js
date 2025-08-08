// Import Bootstrap JS
import "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js";

// Comet + Bootstrap JavaScript
window.CometActions = {
	// Example action for button clicks
	signup: (event, props) => {
		// Show Bootstrap toast
		const toastContainer =
			document.querySelector(".toast-container") || createToastContainer();

		const toast = document.createElement("div");
		toast.className = "toast";
		toast.setAttribute("role", "alert");
		toast.innerHTML = `
      <div class="toast-header">
        <strong class="me-auto">Comet</strong>
        <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
      </div>
      <div class="toast-body">
        Thanks for clicking "${props.text || "the button"}"!
      </div>
    `;

		toastContainer.appendChild(toast);

		// Initialize and show toast
		const bsToast = new bootstrap.Toast(toast);
		bsToast.show();

		// Remove from DOM after hiding
		toast.addEventListener("hidden.bs.toast", () => {
			toast.remove();
		});
	},

	// Modal handling
	openModal: (event, props) => {
		const modalId = props.modal || "defaultModal";
		const modal = document.getElementById(modalId);
		if (modal) {
			const bsModal = new bootstrap.Modal(modal);
			bsModal.show();
		}
	},

	closeModal: (event, props) => {
		const modalId = props.modal || event.target.closest(".modal").id;
		const modal = document.getElementById(modalId);
		if (modal) {
			const bsModal = bootstrap.Modal.getInstance(modal);
			if (bsModal) {
				bsModal.hide();
			}
		}
	},

	// Alert handling
	showAlert: (event, props) => {
		const alertType = props.type || "success";
		const message = props.message || "Action completed!";

		const alert = document.createElement("div");
		alert.className = `alert alert-${alertType} alert-dismissible fade show`;
		alert.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;

		// Insert at top of main content or body
		const main = document.querySelector("main") || document.body;
		main.insertBefore(alert, main.firstChild);

		// Auto-hide after 5 seconds
		setTimeout(() => {
			if (alert.parentNode) {
				const bsAlert = new bootstrap.Alert(alert);
				bsAlert.close();
			}
		}, 5000);
	},
};

// Helper function to create toast container
function createToastContainer() {
	const container = document.createElement("div");
	container.className = "toast-container position-fixed top-0 end-0 p-3";
	container.style.zIndex = "1050";
	document.body.appendChild(container);
	return container;
}

// Listen for custom Comet actions
document.addEventListener("comet:action", (event) => {
	console.log("Comet action triggered:", event.detail);
});

// Initialize Bootstrap components on page load
document.addEventListener("DOMContentLoaded", () => {
	// Initialize tooltips
	const tooltipTriggerList = [].slice.call(
		document.querySelectorAll('[data-bs-toggle="tooltip"]'),
	);
	tooltipTriggerList.map(
		(tooltipTriggerEl) => new bootstrap.Tooltip(tooltipTriggerEl),
	);

	// Initialize popovers
	const popoverTriggerList = [].slice.call(
		document.querySelectorAll('[data-bs-toggle="popover"]'),
	);
	popoverTriggerList.map(
		(popoverTriggerEl) => new bootstrap.Popover(popoverTriggerEl),
	);
});

// Custom hydration function for Bootstrap forms
window.hydrate_bootstrap_form = (element, props) => {
	console.log("Hydrating Bootstrap form", element, props);

	const form = element.querySelector("form");
	if (form) {
		form.addEventListener("submit", (e) => {
			e.preventDefault();

			// Add loading state to submit button
			const submitBtn = form.querySelector('button[type="submit"]');
			if (submitBtn) {
				const originalText = submitBtn.innerHTML;
				submitBtn.innerHTML =
					'<span class="spinner-comet me-2"></span>Loading...';
				submitBtn.disabled = true;

				// Simulate form submission
				setTimeout(() => {
					submitBtn.innerHTML = originalText;
					submitBtn.disabled = false;

					// Show success toast
					CometActions.signup(e, { text: "Form submitted successfully!" });
				}, 1500);
			}
		});

		// Add Bootstrap validation classes
		const inputs = form.querySelectorAll("input, textarea, select");
		for (const input of inputs) {
			input.addEventListener("blur", () => {
				if (input.checkValidity()) {
					input.classList.add("is-valid");
					input.classList.remove("is-invalid");
				} else {
					input.classList.add("is-invalid");
					input.classList.remove("is-valid");
				}
			});
		}
	}
};
