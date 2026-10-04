from django.contrib import admin

# Register your models here.

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from rest_framework.authtoken.models import Token
from .models import CustomUser, DoctorProfile,AutismDetectionResult,Appointment


# 🔹 Inline Doctor Profile inside User
class DoctorProfileInline(admin.StackedInline):
    model = DoctorProfile
    can_delete = False
    extra = 0


# 🔹 Custom User Admin
class CustomUserAdmin(UserAdmin):

    model = CustomUser

    list_display = (
        'id',
        'username',
        'email',
        'phone',
        'role',
        'is_active',
        'is_staff',
        'is_verified',
        'is_login_allowed',
        'display_token',
        'created_at',
    )

    list_filter = ('role', 'is_active', 'is_staff')

    search_fields = ('username', 'email', 'phone')

    ordering = ('-created_at',)

    inlines = [DoctorProfileInline]

    fieldsets = (
        (None, {'fields': ('username', 'email', 'phone', 'password')}),
        ('Role & Status', {'fields': ('role', 'is_active', 'is_staff', 'is_verified', 'is_login_allowed')}),
        ('Permissions', {'fields': ('is_superuser', 'groups', 'user_permissions')}),
        ('Dates', {'fields': ('created_at', 'updated_at')}),
    )

    readonly_fields = ('created_at', 'updated_at')

    def display_token(self, obj):
        token = Token.objects.filter(user=obj).first()
        return token.key if token else "No Token"

    display_token.short_description = "Token"


admin.site.register(CustomUser, CustomUserAdmin)



class DoctorProfileAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'get_username',
        'get_email',
        'department',
        'experience_years',
    )

    search_fields = (
        'user__username',
        'user__email',
        'department',
    )

    list_filter = ('department',)

    ordering = ('-id',)

    def get_username(self, obj):
        return obj.user.username
    get_username.short_description = "Username"

    def get_email(self, obj):
        return obj.user.email
    get_email.short_description = "Email"


admin.site.register(DoctorProfile, DoctorProfileAdmin)



@admin.register(AutismDetectionResult)
class AutismDetectionResultAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'prediction', 'confidence', 'created_at')
    search_fields = ('user__email', 'prediction')
    list_filter = ('prediction', 'created_at')
    ordering = ('-created_at',)