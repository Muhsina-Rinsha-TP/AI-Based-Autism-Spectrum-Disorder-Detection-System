from rest_framework import serializers
from autism_app.models import *

### Doctor Register

class DoctorRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    department = serializers.CharField()
    experience_years = serializers.IntegerField()

    class Meta:
        model = CustomUser
        fields = [
            'username',
            'email',
            'phone',
            'password',
            'department',
            'experience_years',
        ]

    def create(self, validated_data):
        department = validated_data.pop('department')
        experience = validated_data.pop('experience_years')

        # Create User
        user = CustomUser.objects.create_user(role=2,**validated_data)
        # Create Doctor Profile
        DoctorProfile.objects.create(
            user=user,
            department=department,
            experience_years=experience
        )

        return user
    
### User Register 

class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = CustomUser
        fields = ['username', 'email', 'phone', 'password']

    def create(self, validated_data):
        user = CustomUser.objects.create_user(
            role=3,   # Normal User
            **validated_data
        )
        return user
    
    
### User Login  

from django.contrib.auth import authenticate

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()

    def validate(self, data):
        user = authenticate(email=data['email'], password=data['password'])

        if not user:
            raise serializers.ValidationError("Invalid credentials")

        if not user.is_active:
            raise serializers.ValidationError("Account inactive")

        if not user.is_login_allowed:
            raise serializers.ValidationError("Login not allowed")

        data['user'] = user
        return data


# Get Questions + Options

class OptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Option
        fields = ['id', 'text']


class QuestionSerializer(serializers.ModelSerializer):
    options = OptionSerializer(many=True, read_only=True)

    class Meta:
        model = Question
        fields = ['id', 'text', 'options']

# Submit Answers Serializer

class AnswerSerializer(serializers.Serializer):
    answers = serializers.ListField()

    def create(self, validated_data):
        user = self.context['request'].user
        answers_data = validated_data['answers']

        saved_answers = []

        for item in answers_data:
            question_id = item.get("question_id")
            option_id = item.get("option_id")

            answer = Answer.objects.create(
                user=user,
                question_id=question_id,
                option_id=option_id
            )

            saved_answers.append(answer)

        return saved_answers





##########################


# ---------------- USER BASIC ----------------
class UserBasicSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email']


# ---------------- ANSWERS ----------------
class UserAnswerSerializer(serializers.ModelSerializer):
    question = serializers.CharField(source='question.text')
    answer = serializers.CharField(source='option.text')

    class Meta:
        model = Answer
        fields = ['question', 'answer', 'created_at']


# ---------------- VIDEO DETECTION ----------------
class DetectionSerializer(serializers.ModelSerializer):
    video_url = serializers.SerializerMethodField()

    class Meta:
        model = AutismDetectionResult
        fields = ['video_url', 'prediction', 'confidence','risk_level', 'created_at']

    def get_video_url(self, obj):
        request = self.context.get('request')
        if obj.video:
            return request.build_absolute_uri(obj.video.url)
        return None


# ---------------- FINAL COMBINED ----------------
class UserFullReportSerializer(serializers.Serializer):
    user = UserBasicSerializer()
    answers = UserAnswerSerializer(many=True)
    detections = DetectionSerializer(many=True)




################### Doctor See User Serializer ###################

# ---------------- USER FULL DATA ----------------
class UserReportSerializer(serializers.ModelSerializer):
    answers = serializers.SerializerMethodField()
    detections = serializers.SerializerMethodField()

    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'answers', 'detections']

    def get_answers(self, obj):
        answers = Answer.objects.filter(user=obj).select_related('question', 'option')

        return [
            {
                "question": a.question.text,
                "answer": a.option.text,
                "date": a.created_at
            }
            for a in answers
        ]

    def get_detections(self, obj):
        request = self.context.get('request')
        detections = AutismDetectionResult.objects.filter(user=obj)

        return [
            {
                "video_url": request.build_absolute_uri(d.video.url) if d.video else None,
                "prediction": d.prediction,
                "confidence": d.confidence,
                "date": d.created_at
            }
            for d in detections
        ]


####### Doctor Suggestion Serializer

class DoctorSerializer(serializers.ModelSerializer):
    department = serializers.CharField(source='doctor_profile.department')
    experience = serializers.IntegerField(source='doctor_profile.experience_years')

    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'department', 'experience']

####### Doctor Availability Serializer

class DoctorAvailabilitySerializer(serializers.ModelSerializer):
    start_time_display = serializers.SerializerMethodField()
    end_time_display = serializers.SerializerMethodField()

    class Meta:
        model = DoctorAvailability
        fields = [
            'id',
            'date',
            'start_time',   # 👈 keep original (for POST)
            'end_time',     # 👈 keep original (for POST)
            'start_time_display',  # 👈 for AM/PM
            'end_time_display',    # 👈 for AM/PM
            'is_booked'
        ]

    def get_start_time_display(self, obj):
        return obj.start_time.strftime("%I:%M %p")

    def get_end_time_display(self, obj):
        return obj.end_time.strftime("%I:%M %p")