document.addEventListener("DOMContentLoaded", () => {
  const questionContainers = document.querySelectorAll("[id^=question-container]");
  const submitButton = document.getElementById("submit-btn");
  let currentQuestionIndex = 0;

  // Show the current question and hide the rest
  function showCurrentQuestion() {
    questionContainers.forEach((container, index) => {
      if (index === currentQuestionIndex) {
        container.style.display = "block";
      } else {
        container.style.display = "none";
      }
    });
  }

  // Handle the form submission
  function handleSubmit(event) {
    event.preventDefault();

    const form = event.target;
    const formData = new FormData(form);

    // Display the next question or submit the form if all questions have been answered
    if (currentQuestionIndex < questionContainers.length - 1) {
      currentQuestionIndex++;
      showCurrentQuestion();
    } else {
      form.submit();
    }
  }

  // Attach the event listener to the form submission
  const form = document.getElementById("message-form");
  form.addEventListener("submit", handleSubmit);

  // Show the initial question
  showCurrentQuestion();
});
