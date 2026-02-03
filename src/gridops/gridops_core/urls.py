from django.contrib import admin
from django.urls import path, include
from django.http import HttpResponse
from catalog import views as catalog_views # Import the new view

# A temporary "Home" view to verify SSO works
def home(request):
    if request.user.is_authenticated:
        # If Keycloak works, this prints the user's email
        return HttpResponse(f"<h1>Success!</h1> <p>Hello <b>{request.user.email}</b>.</p> <p>You are logged in via Keycloak.</p>")
    # If not logged in, show a Login button
    return HttpResponse('<h1>GridOps Portal</h1> <a href="/oidc/authenticate/">Login with SSO</a>')

urlpatterns = [
    path('admin/', admin.site.urls),
    # This enables the /oidc/authenticate/ endpoint
    path('oidc/', include('mozilla_django_oidc.urls')),
    # Point the root URL to catalog app's URLs
    path('', include('catalog.urls')),
]
