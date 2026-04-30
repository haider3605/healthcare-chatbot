Healthcare Chatbot (FYP Project)
Overview

The Healthcare Chatbot is an AI-powered web application designed to assist users in identifying possible health conditions based on symptoms. It provides preliminary guidance, promotes awareness, and suggests when to seek medical attention.

This project combines machine learning, chatbot interaction, and modern web technologies to deliver an intelligent healthcare assistant.

Features
🤖 AI-based symptom analysis
💬 Interactive chatbot interface
🩺 Disease prediction using ML models
💬 Explains the disease and gives precautions using Groq LLM
📊 Trained on medical dataset
🌐 Web-based (accessible anywhere)
🔐 Secure user interaction 

Tech Stack
Frontend:
Flutter Web / HTML / CSS / JavaScript

Backend:
Python (Flask / FastAPI)

Machine Learning:
Scikit-learn
Pandas, NumPy

Deployment:
Railway

How It Works
User enters symptoms in chatbot
System processes input using an ML model
Model predicts possible disease(s)
Chatbot returns a response with guidance

📂 Project Structure
healthcare-chatbot/
│── backend/
│   ├── model/
│   ├── app.py
│   └── requirements.txt
│
│── frontend/
│   ├── lib/
│   └── web/
│
│── dataset/
│── README.md

⚙️ Installation & Setup
1. Clone Repository
git clone https://github.com/your-username/healthcare-chatbot.git
cd healthcare-chatbot
2. Backend Setup
pip install -r requirements.txt
python app.py
3. Frontend Setup
flutter run -d chrome


📊 Model Details
Algorithm: Random Forest Classifier
Dataset: Symptom-based disease dataset
Accuracy: ~80%

⚠️ Disclaimer
This chatbot is for educational purposes only and does not replace professional medical advice.

👨‍💻 Author
Syed Shaheer Haider
GitHub: https://github.com/haider3605
Email: shery9190@gmail.com
