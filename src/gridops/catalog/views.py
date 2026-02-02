from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from .models import ServiceTemplate

@login_required
def catalog_home(request):
    """
    Source [1]: Lists 'predefined services' so developers can provision new services.
    """
    # 1. Fetch all available templates from the database
    services = ServiceTemplate.objects.all()
    
    # 2. Render the HTML page and pass the list of services to it
    return render(request, 'catalog/home.html', {'services': services})
