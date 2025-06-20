# Rails App Kubernetes DevOps Pipeline

This project demonstrates a complete DevOps workflow for a Ruby on Rails application using:

- **Docker** for containerization  
- **Kubernetes** for orchestration  
- **ArgoCD** for GitOps-based automated deployment  
- **Tekton** for Kubernetes-native CI/CD pipelines  

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Docker](#step-1-docker)
- [Step 2: Kubernetes](#step-2-kubernetes)
- [Step 3: ArgoCD (GitOps)](#step-3-argocd-gitops)
- [Step 4: Tekton (CI/CD)](#step-4-tekton-cicd)


---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Minikube](https://minikube.sigs.k8s.io/docs/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [ArgoCD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/) 
- [Tekton CLI](https://github.com/tektoncd/cli) 
- [A Docker Hub account](https://hub.docker.com/)
- [A GitHub account](https://github.com/)

---

## Step 1: Docker

**Goal:** Run the Rails app and PostgreSQL database in containers locally.

### Steps

1. **Create and initialize the Rails app:**
    ```sh
    mkdir myapp
    cd myapp
    docker run --rm -v "${PWD}":/usr/src/app -w /usr/src/app ruby:3.2 bash -c "gem install rails && rails new . -d postgresql"
    ```

2. **Add the provided `Dockerfile`** (see [Dockerfile](./Dockerfile))  
3. **Add the provided `docker-compose.yml`** (see [docker-compose.yml](./docker-compose.yml))  
4. **Edit `config/database.yml`** to match the environment variables (see example in this repo).  
5. **Build and run the app:**
    ```sh
    docker-compose build
    docker-compose run web rails db:create db:migrate
    docker-compose up
    ```
6. **Visit** [http://localhost:13000](http://localhost:13000) to ensure the app is running.

---

## Step 2: Kubernetes

**Goal:** Deploy the app on Kubernetes with persistent storage and web access.

### Steps

1. **Start Minikube & build the app image:**
    ```sh
    minikube start
    eval $(minikube docker-env)
    docker build -t myapp:latest .
    ```

2. **Apply the Kubernetes manifest:**
    ```sh
    kubectl apply -f rails-app.yaml
    kubectl get all -n rails-app
    ```

3. **Enable Ingress and map `rails.local`:**
    ```sh
    minikube addons enable ingress
    minikube ip
    ```
    - Add the Minikube IP and `rails.local` to your OS hosts file (e.g., `/etc/hosts` or `C:\Windows\System32\drivers\etc\hosts`).

4. **Visit** [http://rails.local](http://rails.local).

---

## Step 3: ArgoCD (GitOps)

**Goal:** Enable declarative, automated deployments from your GitHub repository.

### Steps

1. **Install ArgoCD:**
    ```sh
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ```
    - Visit [http://localhost:8080](http://localhost:8080).

2. **Retrieve the ArgoCD admin password:**

    - **PowerShell:**
      ```powershell
      [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}")))
      ```
    - **Mac/Linux:**
      ```sh
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
      ```

3. **Edit ArgoCD config files in** `/argocd` **to use your GitHub repo and manifest path.**

4. **Apply ArgoCD configuration:**
    ```sh
    kubectl apply -f argocd/argocd-cm.yaml
    kubectl apply -f argocd/argocd-rbac-cm.yaml
    kubectl apply -f argocd/repository-secret.yaml
    kubectl apply -f argocd/application.yaml
    ```
5. **Push Kubernetes manifests to GitHub.**  
   ArgoCD will sync changes and manage deployments automatically.

---

## Step 4: Tekton (CI/CD)

**Goal:** Automated build and Docker image push using a Kubernetes-native pipeline.

### Steps

1. **Install Tekton and its dashboard:**
    ```sh
    kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
    kubectl apply -f https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
    kubectl port-forward svc/tekton-dashboard -n tekton-pipelines 9097:9097
    ```
    - Access at [http://localhost:9097](http://localhost:9097)

2. **Create a Docker Hub registry secret:**
    ```sh
    kubectl create secret docker-registry dockerhub-secret \
      --docker-username=<DOCKERHUB_USERNAME> \
      --docker-password=<DOCKERHUB_PASSWORD> \
      --docker-server=https://index.docker.io/v1/ \
      --docker-email=<YOUR_EMAIL>
    ```

3. **Apply all Tekton resources:**
    ```sh
    kubectl apply -f workspace-pvc.yaml
    kubectl apply -f git-clone.yaml
    kubectl apply -f build-and-push.yaml
    kubectl apply -f pipeline.yaml
    kubectl apply -f pipelinerun.yaml
    ```
    - Or, use the Tekton Dashboard to manually create and run PipelineRuns.

4. **Check Docker Hub** for your new image after the Tekton pipeline finishes!

---

## Tips & Troubleshooting

- If `docker-compose` or Kubernetes pods fail to connect to the database, double check your env variables and network settings.
- For domain mapping: clear your browser cache and flush DNS after editing your hosts file.
- Use `kubectl logs <pod>` for debugging running pods.
- Make sure you are in the correct Kubernetes context and namespace when applying YAMLs and running commands.

---

