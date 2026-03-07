import os
import base64
import time
from github import Github, GithubException
from django.shortcuts import render, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import ServiceTemplate, DeployedService
from .forms import ServiceForm
from kubernetes import client, config

# =========================================================
# 1. THE NEW ARCHITECT DASHBOARD
# =========================================================
def catalog_home(request):
    # Cluster Services Map - Use a distinct variable name
    cluster_links = [
        {'name': 'Argo CD', 'url': 'https://argocd.sikiru.co.uk', 'icon': '⚙️', 'desc': 'GitOps Delivery Pipeline'},
        {'name': 'Grafana', 'url': 'https://grafana.sikiru.co.uk', 'icon': '📊', 'desc': 'Hardware & RAID Observability'},
        {'name': 'n8n', 'url': 'https://n8n.sikiru.co.uk', 'icon': '🤖', 'desc': 'Event-Driven Automation'},
        {'name': 'Longhorn', 'url': 'https://longhorn.sikiru.co.uk', 'icon': '💾', 'desc': 'Distributed Block Storage'},
        {'name': 'Keycloak', 'url': 'https://sso.sikiru.co.uk', 'icon': '🛡️', 'desc': 'Identity & Access Management'},
    ]

    # Architect Profile Data
    architect_profile = {
        'name': 'Jimoh Sikiru Adebayo',
        'role': 'Platform & DevOps Engineer',
        'certifications': ['CKA', 'GCP ACE', 'KCNA', 'MTCNA'],
        'stack': 'Kubernetes, Proxmox, GitOps, Python, Keycloak'
    }

    # Fetch the actual GitOps blueprints from the database
    db_templates = ServiceTemplate.objects.all()

    context = {
        'cluster_links': cluster_links,
        'profile': architect_profile,
        'templates': db_templates, # Passed safely without collision
    }
    
    # Principle of Least Privilege: Only render the provisioning form 
    if request.user.is_authenticated:
        context['form'] = ServiceForm()

    return render(request, 'catalog/home.html', context)

# --- HELPER FUNCTION: RECURSIVE COPY ---
# Source: Ensures the "Standardized Template" (Source [1]) is fully copied (Code + Helm Charts + CI Config)
def copy_recursive(github_object, source_repo, target_repo, path=""):
    """
    Recursively copies all files from source_repo to target_repo starting at 'path',
    BUT explicitly skips the 'charts' folder to enforce the Multi-Source GitOps architecture.
    """
    contents = source_repo.get_contents(path)

    for content_file in contents:
        # ---------------------------------------------------------
        # ARCHITECTURAL GUARDRAIL: 
        # Skip the 'charts' folder so the developer gets a clean repo 
        # (Code + Config only). The heavy Helm charts stay in the Skeleton.
        # ---------------------------------------------------------
        if "charts" in content_file.path:
            print(f"Skipping infrastructure blueprint: {content_file.path}")
            continue

        if content_file.type == "dir":
            # If directory (like 'k8s'), recurse deeper
            copy_recursive(github_object, source_repo, target_repo, content_file.path)
        else:
            # If file, create it in the new repo
            try:
                target_repo.create_file(
                    path=content_file.path,
                    message=f"init: scaffold {content_file.path}",
                    content=content_file.decoded_content
                )
                # Sleep to prevent hitting GitHub API rate limits
                time.sleep(0.2)
            except GithubException:
                # File already exists, skip
                print(f"Skipping {content_file.path} - already exists")
                pass

# NEW IMPORTS FOR KUBERNETES
from kubernetes import client, config

# --- HELPER: AUTOMATED SECRET CREATION ---
def create_argocd_secret(repo_url, repo_name):
    """
    Creates a Kubernetes Secret in the 'argocd' namespace so Argo CD
    can access the newly created private repository.
    """
    try:
        # Load authentication (works automatically inside the cluster)
        try:
            config.load_incluster_config()
        except config.ConfigException:
            # Fallback for local testing (uses ~/.kube/config)
            config.load_kube_config()

        v1 = client.CoreV1Api()
        
        # To Get the token Django is using (The one injected via Envs)
        github_token = os.getenv('GITHUB_TOKEN')
        
        # To Define the Secret Name (Sanitized)
        secret_name = f"repo-{repo_name}"
        
        # To Create the Secret Object
        secret = client.V1Secret(
            metadata=client.V1ObjectMeta(
                name=secret_name,
                namespace="argocd",
                labels={"argocd.argoproj.io/secret-type": "repository"} # Critical Label
            ),
            string_data={
                "url": repo_url,
                "type": "git",
                "username": "git",
                "password": github_token
            },
            type="Opaque"
        )

        # To Send to Kubernetes API
        v1.create_namespaced_secret(namespace="argocd", body=secret)
        print(f"✅ Successfully created Argo CD secret: {secret_name}")
        return True

    except Exception as e:
        print(f"❌ Failed to create Kubernetes Secret: {e}")
        # In production, this might be log or meant to throw an error,
        # but for now just to print it so the view doesn't crash.
        return False


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
                    # NEW: Create the Kubernetes Secret immediately
                    print(f"Triggering secret creation for {new_repo_name}...") 
                    create_argocd_secret(source_repo.clone_url, new_repo_name)
                except GithubException as e:
                    if e.status == 422: # Already exists
                        source_repo = user.get_repo(new_repo_name)
                    else:
                        raise e

                # =========================================================
                # PART 2: POPULATE REPO (RECURSIVE COPY)
                # Source [4]: Copies Jenkinsfile (CI), Dockerfile, and Charts
                # =========================================================
                # We extract the repo name from the URL stored in the Database 
                skeleton_name = template.skeleton_repo_url.replace("https://github.com/", "").replace(".git", "")
                skeleton = g.get_repo(skeleton_name)
                
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
  # FINALIZER: Ensures pods are deleted when app is deleted
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  sources:
    # SOURCE 1: The Secure Blueprint (Controlled strictly by Platform Team)
    - repoURL: 'https://github.com/JimohAdebayo-DevOps/gridops-skeleton-python.git'
      targetRevision: main
      path: {template.default_chart_path}
      helm:
        valueFiles:
          - $values/k8s/values.yaml

    # SOURCE 2: The Developer's Configuration
    - repoURL: '{target_repo_url}'
      targetRevision: main
      ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: {service_name}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
"""

                # Commit the manifest to the Cluster State Repo
                cluster_repo.create_file(
                    path=f"apps/{service_name}.yaml",
                    message=f"feat: provision {service_name} via secure multi-source portal",
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
