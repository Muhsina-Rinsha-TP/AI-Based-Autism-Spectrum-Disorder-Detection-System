import os
import numpy as np
import cv2
import joblib
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from tensorflow import keras

from autism_app.models import *
# MODEL PATH
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "autismdetection.pkl")

# Load Model Once
svm_model = joblib.load(MODEL_PATH)
# Load VGG16
base_model = keras.applications.VGG16(
    weights="imagenet",
    include_top=False,
    input_shape=(224,224,3)
)

feature_extractor = keras.Model(
    inputs=base_model.input,
    outputs=keras.layers.GlobalAveragePooling2D()(base_model.output)
)

# Load Video Frames
def load_video_frames(video_path, frame_count=50):
    cap = cv2.VideoCapture(video_path)
    frames = []
    count = 0
    while cap.isOpened() and count < frame_count:
        ret, frame = cap.read()
        if not ret:
            break
        frame = cv2.resize(frame,(224,224))
        frame = frame/255.0
        frames.append(frame)
        count+=1
    cap.release()
    if len(frames)==0:
        return None
    return np.array(frames)

# Extract Features
def extract_features(frames):
    features = feature_extractor.predict(frames)
    return features.mean(axis=0)

# Detection API
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

# New Code added 08-05-2026
# CHECK VIDEO MOTION LEVEL
def detect_motion_level(video_path):

    cap = cv2.VideoCapture(video_path)

    prev_frame = None

    motion_scores = []

    while True:

        ret, frame = cap.read()

        if not ret:
            break

        frame = cv2.resize(frame, (128, 128))

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        gray = cv2.GaussianBlur(gray, (5, 5), 0)

        if prev_frame is not None:

            diff = cv2.absdiff(prev_frame, gray)

            motion = np.sum(diff) / (128 * 128)

            motion_scores.append(motion)

        prev_frame = gray

    cap.release()

    if len(motion_scores) == 0:
        return 0

    return np.mean(motion_scores)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def detect_autism(request):
    try:
        user = request.user  # 🔥 Logged-in user

        if 'video' not in request.FILES:
            return Response({
                "status": False,
                "error": "Video file required"
            }, status=status.HTTP_400_BAD_REQUEST)

        video_file = request.FILES['video']

        temp_path = os.path.join(BASE_DIR, "temp_video.mp4")

        with open(temp_path, "wb+") as f:
            for chunk in video_file.chunks():
                f.write(chunk)

        frames = load_video_frames(temp_path)

        if frames is None:
            return Response({
                "status": False,
                "error": "Cannot read video"
            })
        

        # New Code added 08-05-2026
        # CHECK MOTION LEVEL
        motion_score = detect_motion_level(temp_path)

        # NORMAL VIDEO DETECTION
        if motion_score < 2:

            os.remove(temp_path)

            return JsonResponse({
                "status": True,
                "prediction": "Normal",
                "confidence": 95.0,
                "motion_score": float(motion_score)
            })
        
        # New Code added 08-05-2026

        feature_vector = extract_features(frames)
        feature_vector = feature_vector.reshape(1, -1)

        prediction = svm_model.predict(feature_vector)[0]
        confidence = svm_model.predict_proba(feature_vector)[0]

        labels = {
            0: "Arm Flapping",
            1: "Head Banging",
            2: "Spinning"
        }

        # result = labels.get(prediction, "Unknown")
        # confidence_score = float(max(confidence) * 100)

        # New Code added 08-05-2026
        confidence_score = float(max(confidence) * 100)
        if confidence_score < 45:
            result = "Normal"
        else:
            result = labels.get(prediction, "Unknown")

        # New Code added 08-05-2026

        # Risk Level Logic
        if confidence_score <= 25:
            risk_level = "Low Risk"
        elif confidence_score <= 50:
            risk_level = "Mild Concern (Monitor & Recheck)"
        elif confidence_score <= 75:
            risk_level = "Moderate Risk"
        else:
            risk_level = "High Risk"

        # Suggestion + Doctor Filter
        if risk_level == "Low Risk":
            suggestion = "No immediate specialist consultation required. Monitor developmental milestones weekly."
            departments = ["Child Psychologist"]

        elif risk_level == "Mild Concern (Monitor & Recheck)":
            suggestion = "Some developmental indicators observed. Monitor behavior for 1-2 months and re-screen later."
            departments = ["Developmental Pediatrician", "Child Psychologist"]

        elif risk_level == "Moderate Risk":
            suggestion = "Noticeable developmental concerns. Consult General Pediatrician first."
            departments = ["Pediatric Neurologist", "Behavioral Therapist", "Child Psychologist"]

        else:  # High Risk
            suggestion = "Strongly recommend pediatric evaluation."
            departments = ["Pediatric Neurologist", "Behavioral Therapist", "Child Psychologist"]

        # ✅ SAVE TO DB
        AutismDetectionResult.objects.create(
            user=user,
            video=video_file,
            prediction=result,
            confidence=confidence_score,
            risk_level=risk_level
        )

        doctors = CustomUser.objects.filter(
            role=2,
            doctor_profile__department__in=departments
        ).select_related('doctor_profile')

        doctor_data = DoctorSerializer(doctors, many=True).data

        os.remove(temp_path)
        print("\n========== AUTISM DETECTION ==========")
        print("User ID:", user.id)
        print("Username:", user.username)
        print("Email:", user.email)
        print("Role:", user.get_role_display())
        print("Prediction:", result)
        print("Confidence:", confidence_score)
        print("======================================\n")

        return Response({
            "status": True,
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "role": user.get_role_display()
            },
            "prediction": result,
            "confidence": confidence_score,
            "risk_level": risk_level,
            "suggestion": suggestion,         
            "recommended_doctors": doctor_data
        })


    except Exception as e:
        return Response({
            "status": False,
            "error": str(e)
        })



######################### 

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import authenticate
from .serializers import *
from rest_framework.permissions import IsAuthenticated, AllowAny
# API For Doctor Register

class DoctorRegisterAPIView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = DoctorRegisterSerializer(data=request.data)

        if serializer.is_valid():
            user = serializer.save()

            print("\n========== DOCTOR REGISTERED ==========")
            print("User ID:", user.id)
            print("Username:", user.username)
            print("Email:", user.email)
            print("Phone:", user.phone)
            print("Role:", user.get_role_display())

            profile = user.doctor_profile
            print("Department:", profile.department)
            print("Experience:", profile.experience_years)
            print("========================================\n")

            return Response({
                "message": "Doctor registered successfully",
            }, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# API For User Register

class UserRegisterAPIView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = UserRegisterSerializer(data=request.data)

        if serializer.is_valid():
            user = serializer.save()

            print("\n========== USER REGISTERED ==========")
            print("User ID:", user.id)
            print("Username:", user.username)
            print("Email:", user.email)
            print("Phone:", user.phone)
            print("Role:", user.get_role_display())
            print("Created At:", user.created_at)
            print("=====================================\n")

            return Response({
                "message": "User registered successfully"
            }, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
# API For Login

class LoginAPIView(APIView):

    def post(self, request):
        serializer = LoginSerializer(data=request.data)

        if serializer.is_valid():
            user = serializer.validated_data['user']

            token, created = Token.objects.get_or_create(user=user)

            print("\n========== USER LOGIN ==========")
            print("User ID:", user.id)
            print("Username:", user.username)
            print("Email:", user.email)
            print("Role:", user.get_role_display())
            print("Token:", token.key)
            print("================================\n")

            return Response({
                "message": "Login successful",
                "token": token.key,
                "role_id": user.role,
                "role": user.get_role_display(),
                "username": user.username
            })

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
# API For Logout

class LogoutAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user

        print("\n========== USER LOGOUT ==========")
        print("User ID:", user.id)
        print("Username:", user.username)
        print("Email:", user.email)
        print("Role:", user.get_role_display())
        print("Token Deleted:", user.auth_token.key)
        print("=================================\n")

        user.auth_token.delete()

        return Response({
            "message": "Logged out successfully"
        })


# API For GET ALL QUESTIONS

class QuestionListAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        questions = Question.objects.prefetch_related('options').all()
        serializer = QuestionSerializer(questions, many=True)

        # 🔥 TERMINAL PRINT
        print("\n========== QUESTIONS FETCH ==========")
        print("User ID:", user.id)
        print("Username:", user.username)
        print("Email:", user.email)
        print("Total Questions:", questions.count())

        for q in questions:
            print(f"\nQ: {q.text}")
            for opt in q.options.all():
                print(f"   - {opt.text}")

        print("=====================================\n")

        return Response({
            "status": True,
            "data": serializer.data
        })


# API For SUBMIT ANSWERS

class SubmitAnswerAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = AnswerSerializer(data=request.data, context={'request': request})

        if serializer.is_valid():
            serializer.save()

            print("\n========== USER ANSWERS ==========")
            print("User:", request.user.username)
            print("Total Answers:", len(request.data.get("answers", [])))
            print("==================================\n")

            return Response({
                "status": True,
                "message": "Answers submitted successfully"
            })

        return Response(serializer.errors, status=400)





##################################################


class UserFullReportAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        answers = Answer.objects.filter(user=user).select_related('question', 'option')
        detections = AutismDetectionResult.objects.filter(user=user)

        data = {
            "user": user,
            "answers": answers,
            "detections": detections
        }

        serializer = UserFullReportSerializer(
            data,
            context={'request': request}
        )

        # 🔥 TERMINAL PRINT
        print("\n========== USER FULL REPORT ==========")
        print("User:", user.username)
        print("Answers:", answers.count())
        print("Detections:", detections.count())
        print("======================================\n")

        return Response({
            "status": True,
            "data": serializer.data
        })


########## Doctor See User List  ##########

class DoctorAllUsersReportAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        # 🔒 Only doctor can access
        if user.role != 2:
            return Response({
                "status": False,
                "error": "Only doctors allowed"
            }, status=403)

        users = CustomUser.objects.filter(role=3)  # only normal users

        serializer = UserReportSerializer(
            users,
            many=True,
            context={'request': request}
        )

        # 🔥 TERMINAL PRINT
        print("\n========== DOCTOR VIEW ==========")
        print("Doctor:", user.username)
        print("Total Users:", users.count())
        print("=================================\n")

        return Response({
            "status": True,
            "total_users": users.count(),
            "data": serializer.data
        })


########## Doctor Availability 27-02-2026 ##########


class CreateAvailabilityAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user

        if user.role != 2:
            return Response({"error": "Only doctors allowed"}, status=403)

        # Support both single and multiple
        if "slots" in request.data:
            slots_data = request.data.get("slots")
        else:
            # Convert single slot into list
            slots_data = [request.data]

        if not slots_data:
            return Response({"error": "No slots provided"}, status=400)

        created_slots = []
        skipped_slots = []

        print("\n========== MULTIPLE SLOTS CREATION ==========")
        print("Doctor:", user.username)

        for slot_data in slots_data:

            # 🔴 Duplicate check
            exists = DoctorAvailability.objects.filter(
                doctor=user,
                date=slot_data.get("date"),
                start_time=slot_data.get("start_time"),
                end_time=slot_data.get("end_time")
            ).exists()

            if exists:
                print("❌ Duplicate skipped:", slot_data)
                skipped_slots.append(slot_data)
                continue

            serializer = DoctorAvailabilitySerializer(data=slot_data)

            if serializer.is_valid():
                slot = serializer.save(doctor=user)
                created_slots.append(slot)

                print(f"""
                ✅ Slot Created
                ID: {slot.id}
                Date: {slot.date}
                Start: {slot.start_time}
                End: {slot.end_time}
                Booked: {slot.is_booked}
                """)

            else:
                print("❌ Invalid slot:", serializer.errors)
                skipped_slots.append(slot_data)

        print("=============================================\n")

        return Response({
            "status": True,
            "created_count": len(created_slots),
            "skipped_count": len(skipped_slots),
            "message": f"{len(created_slots)} slots created, {len(skipped_slots)} skipped"
        })

########## Doctor See Own Slots ##########

class DoctorSlotsAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        if user.role != 2:
            return Response({
                "status": False,
                "error": "Only doctors allowed"
            }, status=403)

        slots = DoctorAvailability.objects.filter(doctor=user).order_by('-date')
        serializer = DoctorAvailabilitySerializer(slots, many=True)

        print("\n========== DOCTOR SLOTS ==========")
        print("Doctor:", user.username)
        print("Total Slots:", slots.count())

        for s in slots:
            print(f"""
            Slot ID: {s.id}
            Date: {s.date}
            Start: {s.start_time}
            End: {s.end_time}
            Booked: {s.is_booked}
            """)

        print("==================================\n")

        return Response({
            "status": True,
            "total_slots": slots.count(),
            "data": serializer.data
        })


########## Doctor List with Available Slots ##########

class DoctorListWithSlotsAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        doctors = CustomUser.objects.filter(role=2).select_related('doctor_profile')

        data = []

        print("\n========== DOCTOR LIST WITH SLOTS ==========")

        for doctor in doctors:
            print(f"\nDoctor: {doctor.username} ({doctor.doctor_profile.department})")

            slots = DoctorAvailability.objects.filter(
                doctor=doctor,
                is_booked=False
            )

            for s in slots:
                print(f"""
                Slot ID: {s.id}
                Date: {s.date}
                Start: {s.start_time}
                End: {s.end_time}
                """)

            data.append({
                "doctor_id": doctor.id,
                "doctor_name": doctor.username,
                "department": doctor.doctor_profile.department,
                "slots": DoctorAvailabilitySerializer(slots, many=True).data
            })

        print("============================================\n")

        return Response({
            "status": True,
            "data": data
        })


########## Book Appointment API ##########

class BookAppointmentAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        slot_id = request.data.get("slot_id")

        try:
            slot = DoctorAvailability.objects.get(id=slot_id, is_booked=False)
        except DoctorAvailability.DoesNotExist:
            return Response({
                "status": False,
                "error": "Slot not available"
            }, status=400)

        Appointment.objects.create(
            user=user,
            doctor=slot.doctor,
            appointment_date=slot.date
        )

        slot.is_booked = True
        slot.save()

        print("\n========== APPOINTMENT BOOKED ==========")
        print("Patient:", user.username)
        print("Email:", user.email)
        print("Doctor:", slot.doctor.username)
        print("Department:", slot.doctor.doctor_profile.department)
        print("Date:", slot.date)
        print("Time:", slot.start_time, "-", slot.end_time)
        print("Slot ID:", slot.id)
        print("========================================\n")

        return Response({
            "status": True,
            "message": "Appointment booked successfully"
        })


########## Doctor See User Appointments ##########

class DoctorAppointmentsAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        if user.role != 2:
            return Response({"error": "Only doctors allowed"}, status=403)

        appointments = Appointment.objects.filter(doctor=user).select_related('user')

        data = []

        print("\n========== DOCTOR APPOINTMENTS ==========")
        print("Doctor:", user.username)

        for appt in appointments:

            # 🔍 Find booked slot for same date
            slot = DoctorAvailability.objects.filter(
                doctor=user,
                date=appt.appointment_date,
                is_booked=True
            ).first()

            if slot:
                start_time = slot.start_time.strftime("%I:%M %p")
                end_time = slot.end_time.strftime("%I:%M %p")
                slot_id = slot.id
            else:
                start_time = None
                end_time = None
                slot_id = None

            print(f"""
            Patient: {appt.user.username}
            Email: {appt.user.email}
            Date: {appt.appointment_date}
            Slot: {start_time} - {end_time}
            """)

            data.append({
                "patient_name": appt.user.username,
                "email": appt.user.email,
                "date": appt.appointment_date,
                "start_time": start_time,
                "end_time": end_time,
                "slot_id": slot_id
            })

        print("=========================================\n")

        return Response({
            "status": True,
            "data": data
        })
        
### ########## User See Own Appointments ##########

class UserAppointmentsAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        # 🔒 Only normal users allowed
        if user.role != 3:
            return Response({
                "status": False,
                "error": "Only users allowed"
            }, status=403)

        appointments = Appointment.objects.filter(user=user)\
            .select_related('doctor', 'doctor__doctor_profile')

        data = []

        print("\n========== USER APPOINTMENTS ==========")
        print("User:", user.username)
        print("Total Appointments:", appointments.count())

        for appt in appointments:
            print(f"""
                Doctor: {appt.doctor.username}
                Email: {appt.doctor.email}
                Department: {appt.doctor.doctor_profile.department}
                Date: {appt.appointment_date}
            """)

            data.append({
                "doctor_name": appt.doctor.username,
                "doctor_email": appt.doctor.email,
                "department": appt.doctor.doctor_profile.department,
                "date": appt.appointment_date
            })

        print("=======================================\n")

        return Response({
            "status": True,
            "data": data
        })


##################### TEMP AUDIO DIR SETUP 03-03-2026 #####################

##################### IMPORTS #####################

import os
import uuid
import librosa
import numpy as np

from pydub import AudioSegment

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from autism_app.models import AudioAnalysisResult

import os

# 🔥 ADD FFMPEG TO SYSTEM PATH (CRITICAL FIX)
os.environ["PATH"] += os.pathsep + r"C:\Users\muhsi\Music\autism_project\ffmpeg\bin"
##################### BASE + FFMPEG #####################

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 🔥 USE ABSOLUTE PATH (VERY IMPORTANT)
FFMPEG_PATH = r"C:\Users\muhsi\Music\autism_project\ffmpeg\bin\ffmpeg.exe"
FFPROBE_PATH = r"C:\Users\muhsi\Music\autism_project\ffmpeg\bin\ffprobe.exe"

# 🔥 SET ALL REQUIRED PATHS
AudioSegment.converter = FFMPEG_PATH
AudioSegment.ffmpeg = FFMPEG_PATH
AudioSegment.ffprobe = FFPROBE_PATH

# 🔥 DEBUG (CHECK IN TERMINAL)
print("FFmpeg exists:", os.path.exists(FFMPEG_PATH))
print("FFprobe exists:", os.path.exists(FFPROBE_PATH))


##################### TEMP AUDIO DIR #####################

TEMP_AUDIO_DIR = os.path.join(BASE_DIR, "temp_files", "audio")

if not os.path.exists(TEMP_AUDIO_DIR):
    os.makedirs(TEMP_AUDIO_DIR)


##################### AUDIO ANALYSIS #####################

def analyze_audio_file(file_path):
    y, sr = librosa.load(file_path, sr=22050)

    pitches, magnitudes = librosa.piptrack(y=y, sr=sr)
    pitch_values = pitches[magnitudes > np.median(magnitudes)]

    pitch_mean = float(np.mean(pitch_values)) if len(pitch_values) > 0 else 0.0
    pitch_std = float(np.std(pitch_values)) if len(pitch_values) > 0 else 0.0

    energy = float(np.mean(y ** 2))
    zcr = float(np.mean(librosa.feature.zero_crossing_rate(y)))

    intervals = librosa.effects.split(y, top_db=25)
    total_speech_time = sum([(end - start) for start, end in intervals]) / sr
    total_duration = len(y) / sr
    pause_time = float(total_duration - total_speech_time)

    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    tempo = float(librosa.beat.tempo(onset_envelope=onset_env, sr=sr)[0])

    return {
        "duration": round(total_duration, 2),
        "pitch_mean": round(pitch_mean, 2),
        "pitch_std": round(pitch_std, 2),
        "energy": round(energy, 6),
        "zcr": round(zcr, 5),
        "pause_time": round(pause_time, 2),
        "tempo": round(tempo, 2)
    }


##################### INTERPRETATION #####################

def interpret_features(features):
    observations = []

    if features["pitch_std"] < 20:
        observations.append("Low pitch variation detected")

    if features["pause_time"] > features["duration"] * 0.4:
        observations.append("Extended pauses detected")

    if features["energy"] < 0.001:
        observations.append("Low vocal energy")

    if features["tempo"] < 60:
        observations.append("Slow speech")

    if observations:
        status_text = "Unusual speech patterns detected"
        message = "Some acoustic features are outside normal range"
    else:
        status_text = "Speech appears normal"
        message = "No unusual patterns detected"

    return status_text, message, observations


##################### API VIEW #####################

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def analyze_voice(request):
    temp_path = None

    try:
        user = request.user

        # 🔒 Check file
        if 'audio' not in request.FILES:
            return Response({"status": False, "error": "Audio file required"}, status=400)

        audio_file = request.FILES['audio']

        # 🔒 Allow all formats
        allowed_extensions = ['wav', 'mp3', 'ogg', 'aac', 'm4a']
        ext = audio_file.name.split('.')[-1].lower()

        print("Uploaded format:", ext)

        if ext not in allowed_extensions:
            return Response({
                "status": False,
                "error": "Invalid format"
            }, status=400)

        # 💾 Save temp file
        filename = f"{uuid.uuid4()}.{ext}"
        temp_path = os.path.join(TEMP_AUDIO_DIR, filename)

        with open(temp_path, "wb+") as f:
            for chunk in audio_file.chunks():
                f.write(chunk)

        print("Saved temp file:", temp_path)

        # 🔥 FORCE CONVERT TO WAV
        try:
            sound = AudioSegment.from_file(temp_path)
            wav_path = temp_path.rsplit('.', 1)[0] + "_converted.wav"
            sound.export(wav_path, format="wav")
            temp_path = wav_path

            print("Converted to WAV:", temp_path)

        except Exception as e:
            print("Conversion Error:", str(e))
            return Response({
                "status": False,
                "error": "Audio conversion failed"
            }, status=400)

        # 🔍 Analyze
        try:
            features = analyze_audio_file(temp_path)
        except Exception as e:
            print("Librosa Error:", str(e))
            return Response({
                "status": False,
                "error": "Audio processing failed"
            }, status=400)

        # 🧠 Interpret
        status_text, message, observations = interpret_features(features)

        # ✅ Save DB
        audio_obj = AudioAnalysisResult.objects.create(
            user=user,
            audio=audio_file,
            duration=features["duration"],
            pitch_mean=features["pitch_mean"],
            pitch_std=features["pitch_std"],
            energy=features["energy"],
            zcr=features["zcr"],
            pause_time=features["pause_time"],
            tempo=features["tempo"],
            analysis_status=status_text,
            message=message
        )

        # 🖥️ Debug print
        print("\n===== SAVED =====")
        print("User:", audio_obj.user.username)
        print("Status:", audio_obj.analysis_status)
        print("=================\n")

        return Response({
            "status": True,
            "analysis_status": status_text,
            "features": features,
            "observations": observations
        })

    except Exception as e:
        return Response({"status": False, "error": str(e)})

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)


########################## CHATBOT LOGIC ##########################


import random
import re

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response


# ================= USER MEMORY =================

user_memory = {}


def get_memory(user_id):
    if user_id not in user_memory:
        user_memory[user_id] = {
            "age": None,
            "gender": None,
            "last_topic": None,
            "symptoms_detected": set(),
        }
    return user_memory[user_id]


# ================= GREETINGS =================

greetings = [
    "Hello. I'm really glad you reached out."
]


support_prefix = [
    "I understand your concern.",
    "Thank you for telling me.",
    "It's completely okay to feel worried.",
    "You're doing the right thing by checking."
]


# ================= KNOWLEDGE BASE =================

knowledge_base = {
    "repetitive_behavior": {
        "keywords": [
        "flap","flaps","flapping",
        "rock","rocking",
        "spin","spinning",
        "repetitive",
        "speech delay",
        "late talking",
        "not talking",
        "no eye contact",
        "avoids eye contact",
        "toe walking",
        "covers ears",
        "noise sensitivity",
        "picky eating",
        "stimming",

        # ADD THESE
        "abnormal behavior",
        "abnormal behaviour",
        "strange behavior",
        "strange behaviour",
        "unusual behavior",
        "unusual behaviour",
        "odd behavior",
        "odd behaviour",
    ],
        "response": [
            "Repetitive movements like flapping or head shaking can be seen in developmental conditions when frequent.",
            "If repetitive behaviors occur often and are intense, they should be evaluated."
        ]
    }
}


# ================= AGE EXTRACTION =================

def extract_age(text):

    text = text.lower().strip()

    if text.isdigit():
        return f"{text} years"

    match = re.search(r'(\d+)\s*(year|years|month|months)', text)

    if match:
        return match.group(1) + " " + match.group(2)

    return None


# ================= GENDER EXTRACTION =================

def extract_gender(text):

    if "boy" in text or "son" in text:
        return "boy"

    if "girl" in text or "daughter" in text:
        return "girl"

    return None


# ================= TOPIC DETECTION =================

def detect_topic(text):

    text = text.lower()

    for topic, data in knowledge_base.items():
        for keyword in data["keywords"]:
            if keyword in text:
                return topic

    return None


# ================= DOCTOR LIST =================

def get_doctors():

    print("\n========== DOCTOR LIST ==========")

    doctors = CustomUser.objects.filter(role=2).select_related("doctor_profile")

    data = []

    for d in doctors:

        print("Doctor:", d.username)

        data.append({
            "doctor_id": d.id,
            "doctor_name": d.username,
            "department": d.doctor_profile.department,
            "experience": d.doctor_profile.experience_years
        })

    return data


# ================= AVAILABLE SLOTS =================

def get_available_slots():

    print("\n========== AVAILABLE SLOTS ==========")

    slots = DoctorAvailability.objects.filter(is_booked=False)\
        .select_related("doctor", "doctor__doctor_profile")

    data = []

    for s in slots:

        start_time = s.start_time.strftime("%I:%M %p")
        end_time = s.end_time.strftime("%I:%M %p")

        print("Slot Doctor:", s.doctor.username)

        data.append({
            "doctor_name": s.doctor.username,
            "department": s.doctor.doctor_profile.department,
            "date": s.date,
            "start_time": start_time,
            "end_time": end_time
        })

    return data


# ================= CHATBOT LOGIC =================
def generate_response(user, text):

    memory = get_memory(user.id)

    print("\n========== CHATBOT PROCESS ==========")
    print("User Message:", text)

    text = text.lower().strip()

    # Greeting
    if text in ["hi", "hello", "hey"]:
        return {
            "message": random.choice(greetings),
            "options": [
                "Show doctors",
                "Show available slots",
                "Autism symptoms help"
            ]
        }

    # Doctor list
    if "doctor" in text:
        return {
            "message": "Here are available doctors.",
            "doctors": get_doctors()
        }

    # Slot list
    if "slot" in text:
        return {
            "message": "Here are available appointment slots.",
            "slots": get_available_slots()
        }

    # -------- AGE DETECTION --------
    age = extract_age(text)
    if age:
        memory["age"] = age
        print("Saved age:", age)

    # -------- GENDER DETECTION --------
    gender = extract_gender(text)
    if gender:
        memory["gender"] = gender
        print("Saved gender:", gender)

    # -------- ASK AGE FIRST --------
    if not memory["age"]:
        return {"message": "May I know your child's age?"}

    # -------- ASK GENDER --------
    if not memory["gender"]:
        return {"message": "Is your child a boy or girl?"}

    # -------- AUTISM SYMPTOM DETECTION --------
    topic = detect_topic(text)

    if topic:

        memory["last_topic"] = topic
        memory["symptoms_detected"].add(topic)

        response = (
            random.choice(support_prefix) +
            " " +
            random.choice(knowledge_base[topic]["response"])
        )

        return {"message": response}

    # -------- SOLUTION --------
    if "what should i do" in text or "solution" in text or "treatment" in text:

        if memory["symptoms_detected"]:
            return {
                "message": "Since you noticed some behaviors, it would be best to consult a developmental pediatrician. Would you like to see doctors or available slots?"
            }

        return {
            "message": "If you are concerned about your child's development, consulting a pediatrician can help."
        }

    return {"message": "Could you explain the behavior a little more?"}
    
# ================= CHATBOT API =================

class ChatBotAPIView(APIView):

    permission_classes = [IsAuthenticated]

    def post(self, request):

        user = request.user
        message = request.data.get("message")

        print("\n=========== CHATBOT API ===========")
        print("User:", user.username)
        print("Message:", message)

        if not message:
            return Response({
                "status": False,
                "error": "Message is required"
            })

        bot_response = generate_response(user, message)

        print("Bot Response:", bot_response)

        return Response({
            "status": True,
            "user_message": message,
            "bot_response": bot_response
        })


    def get(self, request):

        return Response({
            "status": True,
            "api": "Autism Detection Chatbot API",
            "available_questions": [
                "hello",
                "show doctors",
                "show slots",
                "my child flaps hands",
                "what should I do"
            ]
        })