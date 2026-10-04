from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.core.validators import RegexValidator


# ================= ROLE CHOICES =================
ROLE_CHOICES = [
    (1, 'Admin'),
    (2, 'Doctor'),
    (3, 'User')
]

# ================= USER MANAGER =================
class CustomUserManager(BaseUserManager):

    def create_user(self, username=None, email=None, phone=None, password=None, **extra_fields):
        if not username:
            raise ValueError("Users must have a username")
        if not email:
            raise ValueError("Users must have an email")
        if not phone:
            raise ValueError("Users must have a phone number")
        if not password:
            raise ValueError("Users must have a password")

        email = self.normalize_email(email)

        user = self.model(
            username=username,
            email=email,
            phone=phone,
            **extra_fields
        )

        user.set_password(password)
        user.is_active = True
        user.save(using=self._db)
        return user


    def create_superuser(self, username, email, phone, password, **extra_fields):
        extra_fields.setdefault('role', 1)
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)

        return self.create_user(
            username=username,
            email=email,
            phone=phone,
            password=password,
            **extra_fields
        )


username_validator = RegexValidator(
    regex=r'^(?!\d+$)[a-zA-Z0-9@._-]+$',
    message='Username must contain at least one letter.'
)


# ================= CUSTOM USER =================
class CustomUser(AbstractBaseUser, PermissionsMixin):

    username = models.CharField(max_length=50, unique=True, validators=[username_validator])
    email = models.EmailField(max_length=255, unique=True)
    phone = models.CharField(max_length=15, unique=True)

    role = models.IntegerField(choices=ROLE_CHOICES, default=3)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=False)
    is_login_allowed = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = CustomUserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'phone']

    def __str__(self):
        return f"{self.email} - {self.get_role_display()}"


# ================= DOCTOR PROFILE =================
class DoctorProfile(models.Model):

    # One-to-One relationship
    user = models.OneToOneField(CustomUser,on_delete=models.CASCADE,related_name='doctor_profile')

    # 👇 Inside class as you wanted
    DEPARTMENT_CHOICES = [
        ('Pediatric Neurologist', 'Pediatric Neurologist'),
        ('Child Psychologist', 'Child Psychologist'),
        ('Developmental Pediatrician', 'Developmental Pediatrician'),
        ('Behavioral Therapist', 'Behavioral Therapist'),
    ]

    department = models.CharField(max_length=100,choices=DEPARTMENT_CHOICES)
    experience_years = models.PositiveIntegerField()

    def __str__(self):
        return f"{self.user.email} - {self.department}"
    
    

class Appointment(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name="user_appointments")
    doctor = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name="doctor_appointments")
    appointment_date = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)


class AutismDetectionResult(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    video = models.FileField(upload_to='videos/')
    prediction = models.CharField(max_length=100)
    confidence = models.FloatField()
    risk_level = models.CharField(max_length=100, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - {self.prediction}"


class Question(models.Model):
    text = models.CharField(max_length=255)

    def __str__(self):
        return self.text


class Option(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='options')
    text = models.CharField(max_length=255)

    def __str__(self):
        return f"{self.question.text} - {self.text}"

class Answer(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    option = models.ForeignKey(Option, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)




class DoctorAvailability(models.Model):
    doctor = models.ForeignKey(CustomUser, on_delete=models.CASCADE, limit_choices_to={'role': 2})
    date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_booked = models.BooleanField(default=False)

    class Meta:
        unique_together = ['doctor', 'date', 'start_time', 'end_time']  # 👈 ADD THIS

    def __str__(self):
        return f"{self.doctor.username} - {self.date} {self.start_time}"


######### Voice Analysis Result #########

class AudioAnalysisResult(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    audio = models.FileField(upload_to='audio/')
    
    duration = models.FloatField(null=True, blank=True)
    pitch_mean = models.FloatField(null=True, blank=True)
    pitch_std = models.FloatField(null=True, blank=True)
    energy = models.FloatField(null=True, blank=True)
    zcr = models.FloatField(null=True, blank=True)
    pause_time = models.FloatField(null=True, blank=True)
    tempo = models.FloatField(null=True, blank=True)

    analysis_status = models.CharField(max_length=255)
    message = models.TextField()
    
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - Audio Analysis"