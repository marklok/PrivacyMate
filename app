from flask import Flask, render_template, request, session
import openai
import os
from dotenv import load_dotenv
from llama_index import SimpleDirectoryReader, GPTListIndex, readers, GPTSimpleVectorIndex, LLMPredictor, PromptHelper, ServiceContext
from langchain import OpenAI
from IPython.display import Markdown, display

# https://platform.openai.com/account/api-keys

load_dotenv()
openai.api_key = os.environ["OPENAI_API_KEY"]

print(openai.api_key)

# Set up Flask app
app = Flask(__name__, static_url_path='/static')
app.secret_key = os.urandom(24)

questions = [
    "What is the name of your product?",
    "What is the purpose of processing data?",
    "What type of data will you process?",
    "Do you process sensitive personal data?",
    "Do you have a data processing agreement?"
]


def calculate_risk_rating(responses):
    sensitive_data_answer = responses[3]
    processing_agreement_answer = responses[4]
    if sensitive_data_answer.lower() == "yes":
        return "High"
    elif processing_agreement_answer.lower() == "no":
        return "High"
    else:
        return "Low"


def summarize_responses(responses):
    summary = ""
    if len(responses) >= 1:
        summary += f"The name of your product is {responses[0]}. "
    if len(responses) >= 2:
        summary += f"The purpose of your processing will be {responses[1]}. "
    if len(responses) >= 3:
        summary += f"You'll process {responses[2]} type of personal data. "
    if len(responses) >= 4:
        summary += f"You do process sensitive personal data. "
    if len(responses) >= 5:
        summary += f"You have a data processing agreement. "
    return summary


def provide_feedback(summary):
    feedback = ""
    if "sensitive personal data" in summary.lower():
        feedback += "Processing sensitive personal data without explicit consent or a valid legal basis can pose significant privacy risks. Ensure you have proper safeguards and comply with relevant regulations."
    else:
        feedback += "You have described your processing activities and data handling practices. Consider implementing appropriate security measures and maintaining a data processing agreement to protect personal data."
    return feedback


@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        # Retrieve existing responses from session
        responses = session.get("responses", [])
        # Get the index of the current question
        current_question = len(responses)
        response = request.form.get(f"response-{current_question+1}")

        if response:
            responses.append(response)
            session["responses"] = responses  # Update responses in session

        if current_question == len(questions) - 1:  # All questions answered
            risk_rating = calculate_risk_rating(responses)
            summary = summarize_responses(responses)
            feedback = provide_feedback(summary)
            session.pop("responses")  # Clear responses from session

            return render_template("result.html", summary=summary, feedback=feedback, risk_rating=risk_rating)
        else:
            next_question = current_question + 1
            return render_template("index.html", questions=questions, current_question=next_question)

    else:
        # Clear responses from previous sessions
        session.pop("responses", None)
        return render_template("index.html", questions=questions, current_question=0)


if __name__ == "__main__":
    app.run(debug=True)
