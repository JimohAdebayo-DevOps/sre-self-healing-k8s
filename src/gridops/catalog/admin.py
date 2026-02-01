from django.contrib import admin
from .models import ServiceTemplate, DeployedService

@admin.register(ServiceTemplate)
class ServiceTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'skeleton_repo_url', 'created_at')

@admin.register(DeployedService)
class DeployedServiceAdmin(admin.ModelAdmin):
    list_display = ('name', 'owner', 'namespace', 'created_at')
