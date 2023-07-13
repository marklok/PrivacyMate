from flask import Flask, render_template, request, session
import openai
import os
from dotenv import load_dotenv
from llama_index import SimpleDirectoryReader, GPTListIndex, readers, GPTSimpleVectorIndex, LLMPredictor, PromptHelper, ServiceContext
from langchain import OpenAI
from IPython.display import Markdown, display

# Load environment variables
load_dotenv()
openai.api_key = os.environ["OPENAI_API_KEY"]

# Set up Flask app
app = Flask(__name__, static_url_path='/static')
app.secret_key = os.urandom(24)

# List to store registered products
registered_products = []

# Questions for the chatbot
questions = [
    "What is the name of your product?",
    "What is the purpose of processing data?",
    "What type of data will you process?",
    "Do you process sensitive personal data?",
    "Do you have a data processing agreement?"
]

# Route for the index page


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


# Function to calculate risk rating based on responses
def calculate_risk_rating(responses):
    sensitive_data_answer = responses[3] if len(responses) >= 4 else ""
    processing_agreement_answer = responses[4] if len(responses) >= 5 else ""
    if sensitive_data_answer.lower() == "yes":
        return "High"
    elif processing_agreement_answer.lower() == "no":
        return "High"
    else:
        return "Low"


# Function to summarize responses
def summarize_responses(responses):
    product_name = responses[0] if len(responses) >= 1 else ""
    summary = f"The name of your product is {product_name}. "
    if len(responses) >= 2:
        summary += f"The purpose of your processing will be {responses[1]}. "
    if len(responses) >= 3:
        summary += f"You'll process {responses[2]}. "
    if len(responses) >= 4:
        summary += f"You do process sensitive personal data. "
    if len(responses) >= 5:
        summary += f"You have a data processing agreement. "
    return product_name, summary


# Function to provide feedback based on the summary
def provide_feedback(summary):
    feedback = ""
    if "sensitive personal data" in summary[1].lower():
        feedback += "Processing sensitive personal data without explicit consent or a valid legal basis can pose significant privacy risks. Ensure you have proper safeguards and comply with relevant regulations."
    else:
        feedback += "You have described your processing activities and data handling practices. Consider implementing appropriate security measures and maintaining a data processing agreement to protect personal data."
    return feedback


@app.route("/result")
def result():
    # Retrieve data from the query parameters
    product_name, summary, feedback, risk_rating = (
        request.args.get("product_name"),
        request.args.get("summary"),
        request.args.get("feedback"),
        request.args.get("risk_rating")
    )

    # Render the result template with the retrieved data
    return render_template(
        "result.html",
        product_name=product_name,
        summary=summary,
        feedback=feedback,
        risk_rating=risk_rating
    )


@app.route("/register", methods=["GET"])
def register():
    # Retrieve data from the session
    responses = session.get("responses", [])
    product_name, summary = summarize_responses(responses)
    feedback = provide_feedback(summary)
    risk_rating = calculate_risk_rating(responses)

    # Create a dictionary to store the registered product details
    registered_product = {
        "product_name": product_name,
        "summary": summary,
        "feedback": feedback,
        "risk_rating": risk_rating
    }

    # Retrieve existing registered products from session
    registered_products = session.get("registered_products", [])
    registered_products.append(registered_product)
    session["registered_products"] = registered_products

    # Render the register template with the retrieved data
    return render_template("register.html", registered_products=registered_products, summary=summary)


if __name__ == "__main__":
    app.run(debug=True)
