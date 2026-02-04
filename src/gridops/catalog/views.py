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

# --- HELPER FUNCTION: RECURSIVE COPY ---
# Source: Ensures the "Standardized Template" (Source [1]) is fully copied (Code + Helm Charts + CI Config)
def copy_recursive(github_object, source_repo, target_repo, path=""):
    """
    Recursively copies all files from source_repo to target_repo starting at 'path'.
    """
    contents = source_repo.get_contents(path)
    
    for content_file in contents:
        if content_file.type == "dir":
            # If directory, recurse deeper
            copy_recursive(github_object, source_repo, target_repo, content_file.path)
        else:
            # If file, create it in the new repo
            try:
                target_repo.create_file(
                    path=content_file.path,
                    message=f"init: scaffold {content_file.path}",
                    content=content_file.decoded_content
                )
                # Sleep to prevent hitting GitHub API rate limits (Secondary Source [3]: API limits)
                time.sleep(0.2) 
            except GithubException:
                # File already exists, skip
                pass

@login_required
def launch_service(request, template_id):
    template = get_object_or_404(ServiceTemplate, pk=template_id)
    
    if request.method == 'POST':
        form = ServiceForm(request.POST)
        if form.is_valid():
            service_name = form.cleaned_data['service_name']
            
            try:
                # 1. Authenticate with GitHub
                token = os.getenv('GITHUB_TOKEN')
                if not token:
                    raise Exception("GITHUB_TOKEN is missing.")
                g = Github(token)
                user = g.get_user()
                
                # =========================================================
                # PART 1: SCAFFOLDING (CREATE NEW REPO)
                # "create a new app repo" for self-service
                # =========================================================
                new_repo_name = f"{service_name}-source"
                
                try:
                    # Create private repo
                    source_repo = user.create_repo(new_repo_name, private=True, auto_init=True)
                except GithubException as e:
                    if e.status == 422: # Already exists
                        source_repo = user.get_repo(new_repo_name)
                    else:
                        raise e

                # =========================================================
                # PART 2: POPULATE REPO (RECURSIVE COPY)
                # Source [4]: Copies Jenkinsfile (CI), Dockerfile, and Charts
                # =========================================================
                # Note: Use skeleton name directly, or template.skeleton_repo_url can be use if parsed
                skeleton = g.get_repo("JimohAdebayo-DevOps/gridops-skeleton-python")
                
                try:
                    # Start recursive copy from the root of the skeleton
                    copy_recursive(g, skeleton, source_repo, "")
                except Exception as e:
                    print(f"Scaffolding error during copy: {e}")

                # =========================================================
                # PART 3: GITOPS HANDOFF (ARGO CD MANIFEST)
                # Cluster state is wholly determined by version-controlled manifests
                # =========================================================
                cluster_repo = user.get_repo("gridops-cluster-state")
                
                # CRITICAL: Point Argo CD to the NEW user repository
                target_repo_url = source_repo.clone_url
                
                # Define the Argo CD Application
                file_content = f"""
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {service_name}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: {target_repo_url}
    targetRevision: HEAD
    path: charts/python-app  # <--- MUST MATCH the folder structure in your Skeleton
  destination:
    server: https://kubernetes.default.svc
    namespace: {service_name}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true  # Source [5]: Namespace isolation
"""
                
                # Commit the manifest to the Cluster State Repo
                cluster_repo.create_file(
                    path=f"apps/{service_name}.yaml",
                    message=f"feat: provision {service_name} via portal",
                    content=file_content
                )
                
                # 4. Record Success in Database
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
                # Error Handling
                return render(request, 'catalog/launch.html', {
                    'form': form, 
                    'template': template, 
                    'error': f"Launch Failed: {str(e)}"
                })
            
    else:
        form = ServiceForm()

    return render(request, 'catalog/launch.html', {'form': form, 'template': template})
