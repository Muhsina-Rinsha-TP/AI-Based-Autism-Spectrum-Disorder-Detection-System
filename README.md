\# AI-Based Autism Spectrum Disorder Detection System



An AI-assisted multimodal application designed to support early screening of Autism Spectrum Disorder (ASD) by analyzing behavioral patterns from video, audio, and questionnaire responses.



\## 📌 Project Overview



This project combines a Flutter mobile application with a Django REST API backend to provide an integrated platform for autism screening and related support features.



The system analyzes behavioral patterns from uploaded videos using computer vision and machine learning techniques. It also provides audio analysis, questionnaire-based assessment, reports, doctor management, appointment booking, and a rule-based chatbot.



> \*\*Note:\*\* This system is intended as a screening/support tool and is not a replacement for professional medical diagnosis.



\---



\## 🎯 Objectives



\- Support early screening of autism-related behavioral patterns.

\- Analyze behavioral patterns from video data.

\- Extract meaningful visual features using a pretrained CNN.

\- Classify behavioral patterns using machine learning.

\- Analyze selected acoustic characteristics from audio.

\- Provide questionnaire-based assessment.

\- Generate screening results and risk-level information.

\- Connect users with healthcare professionals through appointment features.

\- Provide a chatbot for basic autism-related guidance.



\---



\## ✨ Key Features



\### 👤 User Management



\- User registration

\- User login and logout

\- Authentication using API tokens

\- User report access



\### 🧠 Video-Based Behavioral Analysis



The video analysis pipeline uses:



```text

Video

&#x20; ↓

Frame Extraction

&#x20; ↓

VGG16 Feature Extraction

&#x20; ↓

SVM Classification

&#x20; ↓

Behavior Classification

&#x20; ↓

Confidence Score

&#x20; ↓

Risk-Level Assessment



The system identifies behavioral patterns including:



Arm Flapping

Head Banging

Spinning



The result includes a confidence score and an associated screening risk level.



🎙️ Audio Analysis



The system analyzes uploaded audio using acoustic features such as:



Pitch variation

Vocal energy

Zero-crossing rate

Speech intervals

Pause duration

Onset strength

Tempo



The audio analysis provides an interpretation of observed speech characteristics.



📝 Questionnaire



Users can:



View screening questions

Submit questionnaire responses

Access their assessment information

📊 Reports



The backend maintains assessment information and provides:



User reports

Detection results

Questionnaire responses

Doctor-side user reports

👨‍⚕️ Doctor Management



The system supports:



Doctor registration

Doctor listing

Doctor availability and slot creation

Doctor-side appointment management

User appointment booking

💬 Chatbot



A rule-based chatbot provides basic guidance related to:



Repetitive behaviors

Speech delay

Eye contact

Sensory sensitivity

Stimming

Other autism-related concerns



The chatbot is designed for basic informational support and does not provide medical diagnosis.



🏗️ System Architecture

&#x20;               Flutter Mobile Application

&#x20;                        │

&#x20;                        │ HTTP / REST API

&#x20;                        ▼

&#x20;             Django REST Framework

&#x20;                        │

&#x20;         ┌──────────────┼──────────────┐

&#x20;         │              │              │

&#x20;         ▼              ▼              ▼

&#x20;   Video Analysis   Audio Analysis   Questionnaire

&#x20;         │              │              │

&#x20;         ▼              ▼              ▼

&#x20;      VGG16          Librosa         Django APIs

&#x20;         │

&#x20;         ▼

&#x20;        SVM

&#x20;         │

&#x20;         ▼

Behavior Classification

&#x20;         │

&#x20;         ▼

&#x20;Confidence \& Risk

&#x20;         │

&#x20;         ▼

&#x20;      Reports

🛠️ Technologies Used

Frontend

Flutter

Dart

HTTP/REST API integration

Backend

Python

Django

Django REST Framework

Django CORS Headers

Machine Learning \& Computer Vision

TensorFlow

Keras

Scikit-learn

OpenCV

VGG16

SVM

Audio Processing

Librosa

Pydub

Data \& Utilities

NumPy

Pandas

SciPy

Joblib

📁 Project Structure

Autism\_Project/

│

├── backend/

│   ├── ai\_training/

│   │   └── train\_model.py

│   │

│   ├── autism\_apis/

│   ├── autism\_app/

│   ├── autism\_project/

│   ├── templates/

│   ├── autismdetection.pkl

│   ├── manage.py

│   └── requirements.txt

│

├── frontend/

│   ├── lib/

│   ├── android/

│   ├── ios/

│   ├── linux/

│   ├── macos/

│   ├── web/

│   ├── windows/

│   ├── test/

│   ├── pubspec.yaml

│   └── pubspec.lock

│

├── .gitignore

└── README.md

🔄 How the System Works

1\. User Registration \& Authentication



Users can register and log in through the Flutter application. Authentication requests are handled by the Django REST API.



2\. Video Screening



The user provides a behavioral video for analysis.



The backend:



Extracts video frames.

Resizes and preprocesses the frames.

Uses VGG16 as a feature extractor.

Aggregates extracted visual features.

Passes the features to an SVM classifier.

Determines the predicted behavioral category.

Calculates a confidence score.

Assigns a screening risk level.

3\. Audio Analysis



Audio files are processed to extract acoustic characteristics such as pitch, energy, pauses, speech intervals, and tempo.



These characteristics are interpreted to identify potentially unusual speech patterns.



4\. Questionnaire Assessment



The user answers the available screening questions through the Flutter application. The responses are submitted to the Django backend and stored for reporting.



5\. Reports \& Healthcare Support



Assessment information can be accessed through user reports. Doctors can also access relevant user information according to their role.



Users can view available doctors and book appointments through the application.



🔐 API Modules



The Flutter application communicates with the Django backend through REST API endpoints supporting:



User registration

Doctor registration

Login/logout

Questionnaire retrieval

Questionnaire submission

Autism detection

User reports

Doctor reports

Doctor slots

Doctor listing

Appointment booking

Appointment management

Chatbot

🚀 Setup

Backend



Navigate to the backend directory:



cd backend



Create a virtual environment:



python -m venv venv



Activate the virtual environment on Windows:



venv\\Scripts\\activate



Install the required dependencies:



pip install -r requirements.txt



Run database migrations:



python manage.py migrate



Start the Django development server:



python manage.py runserver

Frontend



Navigate to the Flutter application:



cd frontend



Install Flutter dependencies:



flutter pub get



Run the application:



flutter run



For physical-device testing, configure the Flutter API base URL to point to the accessible IP address of the Django development server.



📌 Important Development Notes



This repository is configured for development and portfolio demonstration.



Some environment-specific configuration, such as the local backend IP address and FFmpeg installation path, may need to be changed when running the project on another computer.



The machine-learning model and dataset configuration may also require additional setup depending on the execution environment.



🔮 Future Enhancements

Improve model performance using larger and more diverse datasets.

Add additional behavioral indicators.

Improve multimodal fusion between video, audio, and questionnaire information.

Deploy the backend to a cloud platform.

Replace local development configuration with production environment variables.

Improve mobile UI/UX.

Add more comprehensive healthcare professional workflows.

Add stronger privacy and security controls for sensitive assessment data.

⚠️ Medical Disclaimer



This project is intended for educational, research, and preliminary screening purposes only.



The predictions and screening results generated by the system should not be considered a medical diagnosis. Autism Spectrum Disorder should be assessed and diagnosed by qualified healthcare professionals using appropriate clinical evaluation.



👩‍💻 Author



Muhsina Rinsha T P



B.Tech – Artificial Intelligence \& Data Science



GitHub:

https://github.com/Muhsina-Rinsha-TP

