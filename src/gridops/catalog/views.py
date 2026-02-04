import os
import time
from github import Github, GithubException
from django.shortcuts import render, get_object_or_404
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
            
            try:
                # 1. Authenticate
                token = os.getenv('GITHUB_TOKEN')
                if not token:
                    raise Exception("GITHUB_TOKEN is missing.")
                g = Github(token)
                user = g.get_user()
                
                # --- STEP A: SCAFFOLDING (Create the User's Repo) ---
                # Create a NEW repository for this specific service
                # Create a new app repo
                new_repo_name = f"{service_name}-source"
                
                try:
                    # Create the repo (private by default, can be change if needed)
                    source_repo = user.create_repo(new_repo_name, private=True, auto_init=True)
                except GithubException as e:
                    if e.status == 422: # Already exists
                        source_repo = user.get_repo(new_repo_name)
                    else:
                        raise e

                # Copy 'Jenkinsfile' from Skeleton to New Repo
                # (In a real production app, we would copy ALL files recursively)
                skeleton = g.get_repo("JimohAdebayo-DevOps/gridops-skeleton-python")
                
                files_to_copy = ["Jenkinsfile", "Dockerfile"]
                for filename in files_to_copy:
                    try:
                        content = skeleton.get_contents(filename)
                        source_repo.create_file(filename, f"init: {filename}", content.decoded_content)
                    except:
                        pass # Skip if file missing in skeleton or exists in target

                # --- STEP B: GITOPS (Connect Argo CD) ---
                # Cluster state is wholly determined by version-controlled manifests
                cluster_repo = user.get_repo("gridops-cluster-state")
                
                # Point Argo CD to the NEW repo just created, not the skeleton
                target_repo_url = source_repo.clone_url
                
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
    # NOTE: In Phase 3, we will switch this to 'target_repo_url' 
    # For now, keep pointing to skeleton until Jenkins is fully active to build images.
    targetRevision: HEAD
    path: {template.default_chart_path}
  destination:
    server: https://kubernetes.default.svc
    namespace: {service_name}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
"""
                
                # Create the manifest
                cluster_repo.create_file(
                    path=f"apps/{service_name}.yaml",
                    message=f"feat: provision {service_name}",
                    content=file_content
                )
                
                # Record in DB
                DeployedService.objects.create(
                    owner=request.user,
                    name=service_name,
                    template=template,
                    namespace=service_name,
                    github_repo_url=source_repo.html_url
                )

                return render(request, 'catalog/success_launch.html', {
                    'service_name': service_name,
                    'template': template
                })

            except Exception as e:
                return render(request, 'catalog/launch.html', {
                    'form': form, 
                    'template': template, 
                    'error': f"Scaffolding Failed: {str(e)}"
                })
            
    else:
        form = ServiceForm()

    return render(request, 'catalog/launch.html', {'form': form, 'template': template})

