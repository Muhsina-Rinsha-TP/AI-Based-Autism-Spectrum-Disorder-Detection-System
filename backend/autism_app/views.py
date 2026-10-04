from django.shortcuts import render,redirect
from .models import *
from collections import defaultdict
from django.core.paginator import Paginator
from django.contrib.auth import authenticate, login,logout
from django.contrib.auth.decorators import login_required
from django.contrib import messages


def admin_login(request):
    if request.method == "POST":
        email = request.POST.get("email")
        password = request.POST.get("password")

        user = authenticate(request, email=email, password=password)

        if user is not None:
            if user.role == 1:  # Admin check
                login(request, user)
                return redirect("admin_dashboard")
            else:
                messages.error(request, "You are not an admin")
        else:
            messages.error(request, "Invalid email or password")

    return render(request, "login.html")

@login_required(login_url='admin_login')
def admin_dashboard(request):
    total_doctors = CustomUser.objects.filter(role=2).count()
    total_users = CustomUser.objects.filter(role=3).count()
    total_appointments = Appointment.objects.count()

    context = {
        "total_doctors": total_doctors,
        "total_users": total_users,
        "total_appointments": total_appointments,
    }

    return render(request, "admin_dashboard.html", context)

@login_required(login_url='admin_login')
def user_list(request):
    users = CustomUser.objects.filter(role=3)

    return render(request, "user_list.html", {"users": users})

@login_required(login_url='admin_login')
def doctor_list(request):
    doctors = CustomUser.objects.filter(role=2)

    return render(request, "doctor_list.html", {"doctors": doctors})


@login_required(login_url='admin_login')
def admin_logout(request):
    logout(request)
    return redirect('admin_login')

@login_required(login_url='admin_login')
def detection_list(request):
    detections = AutismDetectionResult.objects.select_related('user').all().order_by('-created_at')

    return render(request, "detection_list.html", {"detections": detections})


@login_required(login_url='admin_login')
def question_list_create(request):

    # CREATE
    if request.method == "POST":
        if "add_question" in request.POST:
            question_text = request.POST.get("question")
            if question_text:
                question = Question.objects.create(text=question_text)

                options = request.POST.getlist("options[]")
                for opt in options:
                    if opt.strip():
                        Option.objects.create(question=question, text=opt)

        # DELETE QUESTION
        if "delete_question" in request.POST:
            q_id = request.POST.get("q_id")
            Question.objects.filter(id=q_id).delete()

        # DELETE OPTION
        if "delete_option" in request.POST:
            opt_id = request.POST.get("opt_id")
            Option.objects.filter(id=opt_id).delete()

        # EDIT QUESTION
        if "edit_question" in request.POST:
            q_id = request.POST.get("q_id")
            new_text = request.POST.get("new_text")
            Question.objects.filter(id=q_id).update(text=new_text)

        return redirect('question_list')

    questions = Question.objects.prefetch_related('options').all().order_by('-id')

    return render(request, "question_list.html", {"questions": questions})



from collections import defaultdict

@login_required(login_url='admin_login')
def user_answers_list(request):
    all_answers = Answer.objects.select_related('user', 'question', 'option').order_by('-created_at')

    grouped_data = defaultdict(list)

    for ans in all_answers:
        grouped_data[ans.user].append(ans)

    context = {
        "grouped_answers": dict(grouped_data)
    }

    return render(request, "user_answers_list.html", context)




@login_required(login_url='admin_login')
def doctor_slots_view(request):

    slots = DoctorAvailability.objects.select_related('doctor')\
        .order_by('doctor', 'date', 'start_time')

    grouped_data = defaultdict(lambda: {
        "doctor": None,
        "dates": defaultdict(list)
    })

    # ✅ THIS WAS MISSING (IMPORTANT)
    for slot in slots:
        grouped_data[slot.doctor.id]["doctor"] = slot.doctor
        grouped_data[slot.doctor.id]["dates"][slot.date].append(slot)

    # ✅ DEBUG PRINT
    print("\n========== DEBUG GROUPED DATA ==========")

    for doc_id, data in grouped_data.items():
        print("Doctor:", data["doctor"].username)

        for date, slot_list in data["dates"].items():
            print("  Date:", date)

            for s in slot_list:
                print("     ", s.start_time, "-", s.end_time)

    print("========================================\n")

    # ✅ convert defaultdict → normal dict
    final_data = []
    for data in grouped_data.values():
        final_data.append({
            "doctor": data["doctor"],
            "dates": dict(data["dates"])
        })

    return render(request, "doctor_slots.html", {
        "grouped_slots": final_data
    })



def admin_voice(request):
    audio_list = AudioAnalysisResult.objects.select_related('user').order_by('-created_at')
    # 🔥 Pagination (5 per page)
    paginator = Paginator(audio_list, 5)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    return render(request, "audio_files.html", {
        "page_obj": page_obj
    })



def admin_appointments(request):
    appointments = Appointment.objects.select_related('user', 'doctor')\
        .order_by('-created_at')

    # 🔥 Pagination (5 per page)
    paginator = Paginator(appointments, 5)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    return render(request, "admin_appointments.html", {
        "page_obj": page_obj
    })