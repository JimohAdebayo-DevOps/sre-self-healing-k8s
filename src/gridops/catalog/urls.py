from django.urls import path
from . import views

urlpatterns = [
    path('', views.catalog_home, name='catalog_home'),
    path('launch/<int:template_id>/', views.launch_service, name='launch_service'),
]
