from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import ServiceTemplate
from .forms import ServiceForm

@login_required
def catalog_home(request):
    services = ServiceTemplate.objects.all()
    return render(request, 'catalog/home.html', {'services': services})

@login_required
def launch_service(request, template_id):
    # 1. Find the template the user clicked (or 404 if not found)
    template = get_object_or_404(ServiceTemplate, pk=template_id)
    
    if request.method == 'POST':
        form = ServiceForm(request.POST)
        if form.is_valid():
            service_name = form.cleaned_data['service_name']
            
            # TODO: This is where we will call PyGithub next!
            # For now, let's just print to console and redirect to success
            print(f"User {request.user} is launching {service_name} using {template.name}")
            
            return render(request, 'catalog/success_launch.html', {
                'service_name': service_name,
                'template': template
            })
    else:
        form = ServiceForm()

    return render(request, 'catalog/launch.html', {'form': form, 'template': template})

