from django.urls import path
from .views import *

urlpatterns = [
    path('', admin_login, name='admin_login'),
    path('admin_dashboard',admin_dashboard, name='admin_dashboard'),
    path('users/',user_list, name='user_list'),
    path('doctors/', doctor_list, name='doctor_list'),
    path('logout/', admin_logout, name='admin_logout'),
    path('detections/', detection_list, name='detection_list'),
    path('questions/', question_list_create, name='question_list'),
    path('answers/', user_answers_list, name='user_answers_list'),

    path('doctor-slots/', doctor_slots_view, name='doctor_slots'),
    path('Audio_Analysis_Results/', admin_voice, name='admin_voice'),
    path('appointments/', admin_appointments, name='admin_appointments'),


]