from django.urls import path
from .views import *

urlpatterns = [

    path('detect-autism/', detect_autism),
    path('doctor-register/', DoctorRegisterAPIView.as_view()),
    path('user-register/', UserRegisterAPIView.as_view()),
    path('login/', LoginAPIView.as_view()),
    path('logout/', LogoutAPIView.as_view()),
    path('questions/', QuestionListAPIView.as_view()),
    path('submit-answers/', SubmitAnswerAPIView.as_view()),
    path('user-report/', UserFullReportAPIView.as_view()),
    path('doctor/users-report/', DoctorAllUsersReportAPIView.as_view()),

    
    # Doctor Availability
    path('doctor/create-slot/', CreateAvailabilityAPIView.as_view()),

    path('doctor/slots/', DoctorSlotsAPIView.as_view()),
    
    # Get doctors + slots
    path('doctor/list/', DoctorListWithSlotsAPIView.as_view()),

    # Book appointment
    path('appointment/book/', BookAppointmentAPIView.as_view()),

    # Doctor view appointments
    path('doctor/appointments/', DoctorAppointmentsAPIView.as_view()),

    path('user/appointments/', UserAppointmentsAPIView.as_view()),

    # Analysis Voice
    path('analyze-voice/', analyze_voice),

    # Chatbot endpoint
    path('chatbot/', ChatBotAPIView.as_view()),

]
