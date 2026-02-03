import os
from github import Github  # The PyGithub library installed
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import ServiceTemplate, DeployedService
from .forms import ServiceForm

@login_required
def catalog_home(request):
    services = ServiceTemplate.objects.all()
    return render(request, 'catalog/home.html', {'services': services})

@login_required
def launch_service(request, template_id):
    template = get_object_or_404(ServiceTemplate, pk=template_id)
    
    if request.method == 'POST':
        form = ServiceForm(request.POST)
        if form.is_valid():
            service_name = form.cleaned_data['service_name']
            
            # --- GITOPS MAGIC STARTS HERE ---
            try:
                # 1. Authenticate to GitHub
                token = os.getenv('GITHUB_TOKEN')
                if not token:
                    raise Exception("GITHUB_TOKEN not found in environment")
                
                g = Github(token)
                user = g.get_user()
                
                # 2. Get the Cluster State Repo
                repo_name = "JimohAdebayo-DevOps/gridops-cluster-state"
                repo = g.get_repo(repo_name)
                
                # 3. Create the Content (The Argo CD Application Manifest)
                # "The cluster state is wholly determined by manifests"
                file_content = f"""
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {service_name}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: {template.skeleton_repo_url}
    targetRevision: HEAD
    path: {template.default_chart_path}
  destination:
    server: https://kubernetes.default.svc
    namespace: {service_name}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
"""
                
                # 4. Commit the file to GitHub
                # This triggers the "GitOps" workflow
                repo.create_file(
                    path=f"apps/{service_name}.yaml",
                    message=f"feat: provision {service_name} via portal",
                    content=file_content
                )
                
                # 5. Save record in the local database
                DeployedService.objects.create(
                    owner=request.user,
                    name=service_name,
                    template=template,
                    namespace=service_name,
                    github_repo_url=repo.html_url
                )

                return render(request, 'catalog/success_launch.html', {
                    'service_name': service_name,
                    'template': template
                })

            except Exception as e:
                # If GitHub fails, show error
                return render(request, 'catalog/launch.html', {
                    'form': form, 
                    'template': template,
                    'error': f"GitOps Failed: {str(e)}"
                })
            # --- GITOPS MAGIC ENDS HERE ---
            
    else:
        form = ServiceForm()

    return render(request, 'catalog/launch.html', {'form': form, 'template': template})
