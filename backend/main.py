import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
from groq import Groq
import joblib
import json
import numpy as np
import os

load_dotenv()
print("SUPABASE_URL:", os.getenv("SUPABASE_URL"))
print("GROQ_API_KEY:", os.getenv("GROQ_API_KEY"))

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
SUPABASE_HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

app = FastAPI(title="Healthcare Chatbot API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load models
model_symptoms = joblib.load("models/model_symptoms.pkl")
model_diabetes = joblib.load("models/model_diabetes.pkl")
model_heart = joblib.load("models/model_heart.pkl")

# Load column names
with open("models/symptom_columns.json") as f:
    symptom_columns = json.load(f)

with open("models/diabetes_columns.json") as f:
    diabetes_columns = json.load(f)

with open("models/heart_columns.json") as f:
    heart_columns = json.load(f)

# Groq client
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

# Request models
class ChatRequest(BaseModel):
    message: str

class SymptomExtractionRequest(BaseModel):
    message: str

class SymptomRequest(BaseModel):
    symptoms: list[str]

class DiabetesRequest(BaseModel):
    pregnancies: float
    glucose: float
    blood_pressure: float
    skin_thickness: float
    insulin: float
    bmi: float
    diabetes_pedigree: float
    age: float

class HeartRequest(BaseModel):
    age: float
    sex: float
    cp: float
    trestbps: float
    chol: float
    fbs: float
    restecg: float
    thalach: float
    exang: float
    oldpeak: float
    slope: float
    ca: float
    thal: float

class ExplainRequest(BaseModel):
    disease: str
    confidence: float
class SavePredictionRequest(BaseModel):
    user_id: str
    disease_type: str
    symptoms: list = []
    predicted_disease: str
    confidence: float
    explanation: str = ""

class SaveChatRequest(BaseModel):
    user_id: str
    message: str
    response: str

# Routes
@app.get("/")
def root():
    return {"status": "Healthcare Chatbot API is running"}

@app.post("/extract-symptoms")
def extract_symptoms(request: SymptomExtractionRequest):
    """
    Takes a natural language message from user,
    extracts symptoms that match our known symptom list,
    returns them as a list.
    """
    try:
        prompt = f"""You are a medical symptom extractor. 
        
From the user message below, extract only symptoms that exist in this list:
{symptom_columns}

User message: "{request.message}"

Rules:
- Return ONLY a JSON array of matching symptom strings
- Only include symptoms from the provided list
- If no symptoms match, return an empty array []
- Do not add any explanation, just the JSON array

Example output: ["chills", "high_fever", "muscle_pain"]"""

        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.1
        )

        raw = response.choices[0].message.content.strip()

        # Parse the JSON array from response
        extracted = json.loads(raw)

        # Filter to only valid symptoms just in case
        valid_symptoms = [s for s in extracted if s in symptom_columns]

        return {
            "extracted_symptoms": valid_symptoms,
            "count": len(valid_symptoms)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/predict/symptoms")
def predict_symptoms(request: SymptomRequest):
    try:
        input_vector = [1 if symptom in request.symptoms else 0
                        for symptom in symptom_columns]
        input_array = np.array(input_vector).reshape(1, -1)

        prediction = model_symptoms.predict(input_array)[0]
        probabilities = model_symptoms.predict_proba(input_array)[0]
        confidence = round(max(probabilities) * 100, 2)

        return {
            "disease": prediction,
            "confidence": confidence,
            "all_probabilities": {
                cls: round(prob * 100, 2)
                for cls, prob in zip(model_symptoms.classes_, probabilities)
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/predict/diabetes")
def predict_diabetes(request: DiabetesRequest):
    try:
        input_array = np.array([[
            request.pregnancies, request.glucose, request.blood_pressure,
            request.skin_thickness, request.insulin, request.bmi,
            request.diabetes_pedigree, request.age
        ]])

        prediction = model_diabetes.predict(input_array)[0]
        probabilities = model_diabetes.predict_proba(input_array)[0]
        confidence = round(max(probabilities) * 100, 2)

        return {
            "result": prediction,
            "confidence": confidence,
            "all_probabilities": {
                cls: round(prob * 100, 2)
                for cls, prob in zip(model_diabetes.classes_, probabilities)
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/predict/heart")
def predict_heart(request: HeartRequest):
    try:
        input_array = np.array([[
            request.age, request.sex, request.cp, request.trestbps,
            request.chol, request.fbs, request.restecg, request.thalach,
            request.exang, request.oldpeak, request.slope, request.ca,
            request.thal
        ]])

        prediction = model_heart.predict(input_array)[0]
        probabilities = model_heart.predict_proba(input_array)[0]
        confidence = round(max(probabilities) * 100, 2)

        return {
            "result": prediction,
            "confidence": confidence,
            "all_probabilities": {
                cls: round(prob * 100, 2)
                for cls, prob in zip(model_heart.classes_, probabilities)
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/explain")
def explain_disease(request: ExplainRequest):
    """
    After prediction, explains the disease and gives
    precautionary measures in simple language.
    """
    try:
        prompt = f"""You are a friendly healthcare assistant.

The user has been assessed and the result is: {request.disease} with {request.confidence}% confidence.

Give a response with exactly these 3 sections:
1. What is {request.disease}? (2-3 simple sentences)
2. Common precautions (3-4 bullet points)
3. When to see a doctor (1-2 sentences)

End with this exact disclaimer:
"This is not a medical diagnosis. Please consult a qualified doctor for proper medical advice."

Keep the language simple and friendly."""

        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3
        )

        return {"explanation": response.choices[0].message.content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat")
def chat(request: ChatRequest):
    """
    General health chat — only discusses the 5 diseases.
    """
    try:
        system_prompt = """You are a healthcare assistant that only discusses 
these 5 conditions: Malaria, Typhoid, Pneumonia, Diabetes, Heart Disease.

Rules:
- Only answer questions related to these 5 diseases
- Never make a definitive diagnosis
- Always recommend seeing a doctor
- If user describes emergency symptoms like chest pain or difficulty breathing say: 
  EMERGENCY - Please go to a hospital immediately
- Keep responses short and clear
- End every response with: This is not medical advice."""

        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.message}
            ],
            temperature=0.3
        )

        return {"response": response.choices[0].message.content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@app.get("/symptoms-list")
def get_symptoms():
    return {
        "symptoms": symptom_columns,
        "count": len(symptom_columns)
    }
@app.post("/save-prediction")
def save_prediction(request: SavePredictionRequest):
    try:
        data = {
            "user_id": request.user_id,
            "disease_type": request.disease_type,
            "symptoms": request.symptoms,
            "predicted_disease": request.predicted_disease,
            "confidence": request.confidence,
            "explanation": request.explanation
        }
        response = httpx.post(
            f"{SUPABASE_URL}/rest/v1/predictions",
            headers=SUPABASE_HEADERS,
            json=data
        )
        return {"status": "saved", "response": response.json(), "status_code": response.status_code}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/save-chat")
def save_chat(request: SaveChatRequest):
    try:
        data = {
            "user_id": request.user_id,
            "message": request.message,
            "response": request.response
        }
        response = httpx.post(
            f"{SUPABASE_URL}/rest/v1/chat_history",
            headers=SUPABASE_HEADERS,
            json=data
        )
        return {"status": "saved"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/history/{user_id}")
def get_history(user_id: str):
    try:
        predictions = httpx.get(
            f"{SUPABASE_URL}/rest/v1/predictions",
            headers=SUPABASE_HEADERS,
            params={"user_id": f"eq.{user_id}", "order": "created_at.desc"}
        )
        chats = httpx.get(
            f"{SUPABASE_URL}/rest/v1/chat_history",
            headers=SUPABASE_HEADERS,
            params={"user_id": f"eq.{user_id}", "order": "created_at.desc"}
        )
        return {
            "predictions": predictions.json(),
            "chats": chats.json()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))