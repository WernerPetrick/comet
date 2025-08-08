// Custom JavaScript for your Comet site

// Define actions that can be triggered by shards
window.CometActions = {
	// Example action for button clicks
	signup: (event, props) => {
		alert(`Thanks for clicking ${props.text || "the button"}!`);
	},

	// Add more actions as needed
	contact: (event, props) => {
		console.log("Contact action triggered", props);
	},
};

// Listen for custom Comet actions
document.addEventListener("comet:action", (event) => {
	console.log("Action triggered:", event.detail);
});

// Example: Custom hydration function for a specific shard
window.hydrate_signup_form = (element, props) => {
	console.log("Custom hydration for signup-form", element, props);

	const form = element.querySelector("form");
	if (form) {
		form.addEventListener("submit", (e) => {
			e.preventDefault();
			console.log("Form submitted with props:", props);
			// Handle form submission
		});
	}
};
