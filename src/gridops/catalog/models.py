from django.db import models
from django.contrib.auth.models import User

class ServiceTemplate(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    skeleton_repo_url = models.URLField()
    default_chart_path = models.CharField(max_length=200, default="charts/python-app")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class DeployedService(models.Model):
    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    template = models.ForeignKey(ServiceTemplate, on_delete=models.PROTECT)
    namespace = models.CharField(max_length=100)
    github_repo_url = models.URLField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.owner.username})"
