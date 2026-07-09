# Day 88 -- Multi-Tool Agents, MCP, and CI/CD Analyzer
---

## Challenge Tasks

### Task 1: Build the Multi-Tool DevOps Agent (Module 3)
The Docker agent had 3 tools. Now add 3 Kubernetes tools to the same agent.

<img width="793" height="357" alt="image" src="https://github.com/user-attachments/assets/05d8e476-801a-453d-a60a-bacba08b48a4" />


**Set up a Kind cluster with a broken pod:**
```bash
kind create cluster --name devops-demo
kubectl apply -f module-3/broken_pod.yaml
```
<img width="937" height="380" alt="image" src="https://github.com/user-attachments/assets/fd05bcdd-8fff-4e96-8dd8-ca55ef8f349e" />
<img width="932" height="161" alt="image" src="https://github.com/user-attachments/assets/1ec5790f-b7f2-4ae7-821d-e9736acdf3fe" />


The `broken_pod.yaml` deploys a pod that crashes immediately:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: broken-pod
  namespace: default
spec:
  containers:
  - name: app
    image: nginx:alpine
    command: ["sh", "-c", "echo 'app starting...' && sleep 2 && exit 1"]
```

Also create a broken Docker container:
```bash
docker run -d --name broken-container nginx:alpine sh -c "echo 'container starting...' && sleep 2 && exit 1"
```

<img width="1567" height="165" alt="image" src="https://github.com/user-attachments/assets/6deb4c2f-4308-4896-b26e-7a48b8ad3041" />


**Study `module-3/agent.py`** -- it has 6 tools now:

Docker tools (from Day 87):
- `list_containers()` -- `docker ps -a`
- `get_logs(container_name)` -- `docker logs`
- `inspect_container(container_name)` -- `docker inspect`

Kubernetes tools (new):
```python
@tool
def list_pods(namespace: str = "default") -> str:
    """List all pods in a Kubernetes namespace with their status."""
    result = subprocess.run(
        ["kubectl", "get", "pods", "-n", namespace],
        capture_output=True, text=True,
    )
    return result.stdout or result.stderr

@tool
def describe_pod(pod_name: str, namespace: str = "default") -> str:
    """Get detailed info about a Kubernetes pod including events and conditions."""
    result = subprocess.run(
        ["kubectl", "describe", "pod", pod_name, "-n", namespace],
        capture_output=True, text=True,
    )
    return result.stdout or result.stderr

@tool
def get_events(namespace: str = "default") -> str:
    """Get recent Kubernetes events in a namespace (useful for troubleshooting)."""
    result = subprocess.run(
        ["kubectl", "get", "events", "-n", namespace, "--sort-by=.lastTimestamp"],
        capture_output=True, text=True,
    )
    return result.stdout or result.stderr
```

**Run it:**
```bash
python3 module-3/agent.py
```

Ask questions that span both domains:
```
> What's broken across Docker and Kubernetes?
> Why is broken-pod crashing?
> Are there any unhealthy containers on Docker?
> Describe the events in the default namespace
```

<img width="1436" height="287" alt="image" src="https://github.com/user-attachments/assets/f8624cda-d468-4fde-b6c5-0b3774240f3c" />
<img width="1455" height="606" alt="image" src="https://github.com/user-attachments/assets/20e1f43e-9540-44fb-9889-0a5e3892901b" />
<img width="1196" height="257" alt="image" src="https://github.com/user-attachments/assets/9b1fa981-6a03-4aa6-8b2d-e1c584606587" />
<img width="1436" height="240" alt="image" src="https://github.com/user-attachments/assets/193fdb30-3b8c-4132-ad88-dbd6b1bce473" />


The agent decides which tools to use based on the question. Ask about Docker -- it uses Docker tools. Ask about pods -- it switches to Kubernetes tools. Ask about both -- it uses all of them.

**This is the power of the ReAct pattern:** One agent, many tools, one brain that decides what to use.

---

### Task 2: Understand the Model Context Protocol (MCP)
MCP is an open standard (created by Anthropic) for connecting AI models to external tools and data sources. Instead of writing tools inside your agent code, you expose them via MCP and any compatible client can use them.

**Why MCP matters for DevOps:**

| Without MCP | With MCP |
|------------|---------|
| Tools are locked to one framework (LangChain) | Tools work with any MCP client |
| Every AI client re-implements Docker/K8s tools | Write once, use everywhere |
| Tool access tied to the agent code | Tools exposed as a discoverable service |

**MCP-compatible clients:**
- Claude Desktop
- VS Code (GitHub Copilot)
- Cursor
- Claude Code (the CLI you might already be using)
- Any LangChain agent via `langchain-mcp-adapters`

**The architecture:**
```
[MCP Server]                    [MCP Clients]
  |                                  |
  |-- list_pods()                    |-- Claude Desktop
  |-- describe_pod()      <--->      |-- VS Code Copilot
  |-- get_events()                   |-- Your Python agent
  |                                  |-- Any MCP client
  |
  (exposes tools via stdio/HTTP)
```

---


# What is MCP?

**MCP (Model Context Protocol)** is an **open standard created by Anthropic** that allows AI models to communicate with external tools and data sources in a standardized way.

Think of it like this:

* **HTTP** standardized communication between web browsers and web servers.
* **MCP** standardizes communication between AI assistants and tools.

Instead of each AI application implementing its own way to call tools, MCP defines a common protocol that any compatible client and server can use.

---

# Before MCP (Hardcoded Tools)

In Day 87 and Task 1, your tools were written directly inside `agent.py`:

```python
@tool
def list_pods():
    ...
```

Your architecture looked like this:

```text
User
   │
   ▼
LangChain Agent
   │
   ├── list_containers()
   ├── get_logs()
   ├── inspect_container()
   ├── list_pods()
   ├── describe_pod()
   └── get_events()
```

### Problem

Those tools belong **only to this Python application**.

If tomorrow you want:

* Claude Desktop
* Cursor
* VS Code Copilot

to use the same Kubernetes tools, you'd have to rewrite or integrate them separately.

---

# With MCP

Instead of embedding tools inside the agent, you run them as a separate **MCP Server**.

```text
             MCP Server
        ---------------------
        list_pods()
        describe_pod()
        get_events()
        ---------------------
               ▲
               │
      MCP Protocol (stdio/HTTP)
               │
     ┌─────────┼───────────┐
     │         │           │
 Claude   VS Code    Python Agent
 Desktop  Copilot
```

Now every MCP-compatible client can discover and use the same tools.

---

# Why is this useful for DevOps?

Suppose you wrote a Kubernetes tool:

```python
def describe_pod():
```

Without MCP:

* LangChain can use it.
* Claude Desktop cannot.
* Cursor cannot.
* VS Code Copilot cannot.

You'd need separate integrations.

With MCP:

One implementation serves everyone.

```
Write once
        ↓
Expose via MCP
        ↓
Every AI client can use it
```

---

# Without MCP vs With MCP

| Without MCP                      | With MCP                       |
| -------------------------------- | ------------------------------ |
| Tools live inside one Python app | Tools run in a separate server |
| Only that agent can use them     | Any MCP client can use them    |
| Tight coupling                   | Loose coupling                 |
| Duplicate implementations        | Reusable implementation        |
| Hard to scale                    | Easy to share                  |

---

# MCP Components

There are three important parts.

## 1. MCP Server

This **hosts the tools**.

Example:

```python
@mcp.tool
def list_pods():
```

It exposes the function over the MCP protocol.

---

## 2. MCP Client

The client connects to the server.

Examples:

* Claude Desktop
* Cursor
* VS Code
* LangChain
* Your Python agent

The client discovers available tools automatically.

---

## 3. MCP Protocol

This is the communication layer between the client and server.

The client sends requests like:

```
Call describe_pod("broken-pod")
```

The server executes:

```bash
kubectl describe pod broken-pod
```

and returns the result.

---

# How does communication happen?

Example:

```
User:
Why is broken-pod crashing?
```

↓

Client sends request

↓

```
describe_pod("broken-pod")
```

↓

MCP Server runs

```bash
kubectl describe pod broken-pod
```

↓

Returns output

↓

LLM reads the result

↓

Final answer to the user

---

# MCP Transport

MCP supports different ways to communicate.

### 1. stdio (used in this course)

```
Python Agent
      │
stdin/stdout
      │
MCP Server
```

Simple and ideal for local development.

---

### 2. HTTP

```
Python Agent
      │
 HTTP
      │
Remote MCP Server
```

Useful when tools run on another machine or server.

---

# Why is this important for DevOps?

Imagine your company creates tools for:

* Kubernetes
* Docker
* Terraform
* AWS
* Jenkins

Without MCP, every AI application needs its own integration.

With MCP:

```
Terraform MCP Server

AWS MCP Server

Kubernetes MCP Server

Docker MCP Server
```

Any compatible AI assistant can connect to these servers without additional integration work.

---



---

### Task 3: Build and Use the MCP Server (Module 3)
Study `module-3/mcp_server.py`:

```python
from fastmcp import FastMCP

mcp = FastMCP("Kubernetes Tools")

@mcp.tool
def list_pods(namespace: str = "default") -> str:
    """List all pods in a Kubernetes namespace with their status."""
    result = subprocess.run(
        ["kubectl", "get", "pods", "-n", namespace],
        capture_output=True, text=True,
    )
    return result.stdout or result.stderr

@mcp.tool
def describe_pod(pod_name: str, namespace: str = "default") -> str:
    """Get detailed info about a Kubernetes pod including events and conditions."""
    # ...

@mcp.tool
def get_events(namespace: str = "default") -> str:
    """Get recent Kubernetes events in a namespace."""
    # ...

if __name__ == "__main__":
    mcp.run()
```

**Key difference from LangChain tools:**
- `@mcp.tool` instead of `@tool` -- registered with the MCP server
- `FastMCP("Kubernetes Tools")` -- creates a named MCP server
- `mcp.run()` -- starts the server (stdio transport by default)
- Any MCP client can discover and call these tools

**Now study `module-3/agent_with_mcp.py`** -- the MCP client:

```python
from langchain_mcp_adapters.client import MultiServerMCPClient

async def main():
    client = MultiServerMCPClient({
        "docker-mcp": {
            "transport": "stdio",
            "command": "python",
            "args": ["mcp_server.py"]
        }
    })

    tools = await client.get_tools()    # Dynamically discovers tools from MCP
    llm = ChatOllama(model="gemma4", temperature=0.8)
    agent = create_agent(llm, tools)    # Same ReAct agent, but tools come from MCP
```

The agent does not define tools locally. It connects to the MCP server and discovers them at runtime.

<img width="1021" height="532" alt="image" src="https://github.com/user-attachments/assets/b52fdde2-094f-49fb-be8f-73f2e38d6bd9" />


**Run the MCP agent:**
```bash
cd module-3
python3 agent_with_mcp.py
```

Ask the same Kubernetes questions:
```
> List the pods in my cluster
> Why is broken-pod crashing?
> What events happened recently?
```

<img width="1842" height="1255" alt="image" src="https://github.com/user-attachments/assets/2fa400d5-a95f-4f53-9ccd-18eb92acdf7f" />
<img width="2051" height="947" alt="image" src="https://github.com/user-attachments/assets/a011014b-d8a5-463f-8763-7beddee5ff60" />
<img width="2037" height="747" alt="image" src="https://github.com/user-attachments/assets/da8fdd0f-9450-406e-955e-5163e6e7e01f" />


Same result as before, but the tools are served via MCP instead of being hardcoded in the agent.

**Configure Claude Desktop with your MCP server** (if you have Claude Desktop installed):

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS):
```json
{
  "mcpServers": {
    "kubernetes-tools": {
      "command": "python3",
      "args": ["/full/path/to/agentic-ai-for-devops/module-3/mcp_server.py"]
    }
  }
}
```

Restart Claude Desktop. Now you can ask Claude: "List the pods in my cluster" and it will call your MCP server's `list_pods()` tool.

---

### Task 4: Build the CI/CD Failure Analyzer (Module 6)
The same agent pattern works for CI/CD. This agent uses the `gh` CLI to diagnose GitHub Actions failures.

**Prerequisites:**
```bash
# Authenticate GitHub CLI
gh auth login
```

<img width="955" height="577" alt="image" src="https://github.com/user-attachments/assets/f1ad47d6-20b3-4598-bf7b-9121ff09318b" />


**Study `module-6/ci_analyzer.py`:**

Three tools:
```python
@tool
def list_workflow_runs(status: str = "failure") -> str:
    """List recent GitHub Actions workflow runs. Use status='failure' for failed runs."""
    result = subprocess.run(
        ["gh", "run", "list", "--status", status, "--limit", "5"],
        capture_output=True, text=True,
    )
    return result.stdout or result.stderr

@tool
def get_failed_logs(run_id: str) -> str:
    """Get the failed step logs from a GitHub Actions run. Pass the run ID."""
    result = subprocess.run(
        ["gh", "run", "view", run_id, "--log-failed"],
        capture_output=True, text=True,
    )
    output = result.stdout + result.stderr
    if len(output) > 5000:
        output = output[:5000] + "\n\n[...truncated, showing first 5000 chars]"
    return output

@tool
def get_workflow_file(workflow_name: str) -> str:
    """Read a GitHub Actions workflow YAML file. Pass the filename like 'ci.yml'."""
    import pathlib
    path = pathlib.Path(f".github/workflows/{workflow_name}")
    if path.exists():
        return path.read_text()
    return f"File not found: {path}"
```

**Note the log truncation** in `get_failed_logs` -- LLMs have token limits. You cannot send 100KB of CI logs. Truncating to 5000 characters keeps it within bounds while preserving the most important information (the failed step output).

**Run it inside the AI-BankApp repo** (which has GitHub Actions):
```bash
cd AI-BankApp-DevOps
python3 ../agentic-ai-for-devops/module-6/ci_analyzer.py
```

Ask:
```
> Show me the recent workflow runs
> Read the gitops-ci.yml workflow file and explain what it does
```

<img width="1220" height="552" alt="image" src="https://github.com/user-attachments/assets/7d5b7727-e94b-441a-ae64-568fdb17ea4b" />
<img width="1407" height="592" alt="image" src="https://github.com/user-attachments/assets/25be7585-cb31-4841-8647-0d23183c8806" />


The agent lists failed runs, fetches their logs, reads the workflow file, and explains the root cause.

**Try creating a deliberately broken workflow to test it:**

Create `.github/workflows/broken-ci.yml` in a test repo:
```yaml
name: Broken CI
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test    # Will fail -- no package.json!
```

Push it, let it fail, then ask the agent: "Why did broken-ci fail?"

https://github.com/shettymalathib/test-repo.git 

https://github.com/shettymalathib/test-repo/actions/workflows/broken-ci.yml
<img width="776" height="817" alt="image" src="https://github.com/user-attachments/assets/6104fef5-e246-468f-a2f9-3a5e64602671" />

<img width="2557" height="1007" alt="image" src="https://github.com/user-attachments/assets/da126f55-5c45-42fa-94ac-40132bb19eef" />
<img width="1372" height="90" alt="image" src="https://github.com/user-attachments/assets/319f7185-ecfd-4c72-b5d0-3ad7b62af216" />
<img width="1630" height="1252" alt="image" src="https://github.com/user-attachments/assets/9338dc84-13b9-416f-beae-063d313a5eb8" />
<img width="1412" height="176" alt="image" src="https://github.com/user-attachments/assets/835b372b-3605-4665-baa9-3e12f20164de" />


---

### Task 5: Build Your Own Tool
The pattern is now clear. Any CLI command can be a tool. Build one of these:

**Option A -- Terraform Plan Analyzer:**
```python
@tool
def terraform_plan() -> str:
    """Run terraform plan and return the output showing what would change."""
    result = subprocess.run(
        ["terraform", "plan", "-no-color"],
        capture_output=True, text=True,
        cwd="/path/to/your/terraform/project"
    )
    output = result.stdout + result.stderr
    if len(output) > 5000:
        output = output[:5000] + "\n[...truncated]"
    return output
```

**Option B -- AWS Resource Checker:**
```python
@tool
def list_ec2_instances() -> str:
    """List all EC2 instances with their state, type, and name."""
    result = subprocess.run(
        ["aws", "ec2", "describe-instances",
         "--query", "Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,Tags[?Key=='Name'].Value|[0]]",
         "--output", "table"],
        capture_output=True, text=True,
    )
    return result.stdout or result.stderr
```

**Option C -- Log Searcher:**
```python
@tool
def search_logs(keyword: str, namespace: str = "default") -> str:
    """Search for a keyword in the logs of all pods in a namespace."""
    pods = subprocess.run(
        ["kubectl", "get", "pods", "-n", namespace, "-o", "name"],
        capture_output=True, text=True,
    )
    results = []
    for pod in pods.stdout.strip().split("\n"):
        if not pod:
            continue
        logs = subprocess.run(
            ["kubectl", "logs", pod, "-n", namespace, "--tail=100"],
            capture_output=True, text=True,
        )
        if keyword.lower() in logs.stdout.lower():
            results.append(f"{pod}: found '{keyword}'")
    return "\n".join(results) if results else f"No pods contain '{keyword}' in their logs"
```
Add your tool to any agent, run it, and ask a question that triggers it.

<img width="2146" height="1080" alt="image" src="https://github.com/user-attachments/assets/3c954839-3879-4c7b-ba6c-09f82b04bbcc" />



**Document:** Which tool did you build? How did the agent decide when to use it?

**Option C -- Log Searcher:**

### **Custom Tool Built: Kubernetes Log Searcher**

I built a custom **Kubernetes Log Searcher** tool named `search_logs()`. This tool searches the logs of all pods in a Kubernetes namespace for a user-specified keyword. It first retrieves all pods using `kubectl get pods`, then reads the last 100 log lines from each pod using `kubectl logs`, and returns the pods whose logs contain the specified keyword.

### **How the Agent Decided to Use It**

The tool was registered with the agent using the `@tool` decorator and added to the agent's tool list. The ReAct agent decides which tool to invoke by analyzing the user's request together with each tool's name and docstring. When a user asks a log-related question such as **"Search Kubernetes pod logs for the keyword 'app'"** or **"Find 'app starting' in Kubernetes logs"**, the agent identifies that the request is about searching pod logs and selects the `search_logs()` tool automatically. After executing the tool, it reads the results and generates a natural language explanation.

> **Note:** While using the local `qwen2.5:3b` model, the agent occasionally preferred the `describe_pod()` tool instead of `search_logs()`. This is a limitation of the smaller model's tool-selection capability rather than the implementation. With larger instruction-tuned models (such as Gemma or GPT-class models), tool selection is generally more reliable.


---

### Task 6: Clean Up
```bash
# Delete Kind cluster
kind delete cluster --name devops-demo

# Remove broken container
docker rm -f broken-container 2>/dev/null

# Deactivate Python venv (if needed later)
deactivate
```

<img width="1136" height="277" alt="image" src="https://github.com/user-attachments/assets/954ef8ad-e75f-471b-a5b2-ddffb313b255" />


# Summary of What You Built

| Module                             | What You Built          | Tools                                                       | Pattern                 |
| ---------------------------------- | ----------------------- | ----------------------------------------------------------- | ----------------------- |
| **Module 3 (`agent.py`)**          | Multi-tool DevOps agent | 3 Docker + 3 Kubernetes tools (+ custom `search_logs` tool) | LangChain ReAct         |
| **Module 3 (`mcp_server.py`)**     | MCP Server              | Kubernetes tools exposed through MCP                        | FastMCP                 |
| **Module 3 (`agent_with_mcp.py`)** | MCP Client Agent        | Dynamically discovers MCP tools                             | LangChain + MCP Adapter |
| **Module 6 (`ci_analyzer.py`)**    | CI/CD Failure Analyzer  | GitHub Actions CLI tools                                    | LangChain ReAct         |

---

# Common Agent Pattern

Throughout today's tasks, the implementation followed the same reusable pattern:

1. **Define tools** that wrap CLI commands (`docker`, `kubectl`, `gh`, etc.) using the `@tool` decorator.
2. **Create an LLM instance** (e.g., `ChatOllama`) to provide reasoning capabilities.
3. **Create a ReAct agent** by combining the LLM with the available tools.
4. **Let the agent reason** about the user's request, choose the appropriate tool(s), execute them, interpret the output, and generate a response.

This pattern is reusable across domains—whether you're troubleshooting Docker, Kubernetes, GitHub Actions, Terraform, AWS, or any other CLI-based DevOps workflow.

---

# Documentation

## Architecture - how MCP works

The agent combines **6 tools across 2 DevOps domains**.

```text
                    +------------------------+
                    |    LangChain ReAct     |
                    |       DevOps Agent     |
                    +-----------+------------+
                                |
              ---------------------------------------
              |                                     |
       Docker Tools                         Kubernetes Tools
              |                                     |
    ----------------------             --------------------------
    list_containers()                 list_pods()
    get_logs()                        describe_pod()
    inspect_container()               get_events()
```

## how your agent works.

```text
                           +----------------------+
                           |     AI Agent         |
                           |    (ReAct Agent)     |
                           +----------+-----------+
                                      |
               +----------------------+----------------------+
               |                                             |
      Docker-related question                      Kubernetes-related question
               |                                             |
               v                                             v
      +--------------------+                       +----------------------+
      |    Docker Tools    |                       |  Kubernetes Tools    |
      |--------------------|                       |----------------------|
      | docker ps -a       |                       | kubectl get pods     |
      | docker logs        |                       | kubectl describe pod |
      | docker inspect     |                       | kubectl get events   |
      +---------+----------+                       +----------+-----------+
                |                                             |
                v                                             v
         +--------------+                             +----------------+
         | Docker CLI   |                             | Kubectl CLI    |
         +--------------+                             +----------------+
                ^                                             ^
                |                                             |
                +----------------------+----------------------+
                                       |
                                 Tool Results
                                       |
                                       v
                           +----------------------+
                           |      AI Agent        |
                           +----------+-----------+
                                      |
                                      v
                                 Final Answer
                                      |
                                      v
                                   +------+
                                   | User |
                                   +------+
```                                   

### Docker Tools

- `list_containers()` – Lists all Docker containers.
- `get_logs(container_name)` – Retrieves container logs.
- `inspect_container(container_name)` – Displays container details.

### Kubernetes Tools

- `list_pods()` – Lists Kubernetes pods.
- `describe_pod()` – Displays detailed pod information.
- `get_events()` – Shows recent Kubernetes events.

---

## Testing

Created a Kind cluster:

```bash
kind create cluster --name devops-demo
```

Deployed a broken pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: broken-pod

spec:
  containers:
  - name: app
    image: nginx:alpine
    command:
      - sh
      - -c
      - echo "app starting..." && sleep 2 && exit 1
```

Created a broken Docker container:

```bash
docker run -d --name broken-container nginx:alpine \
sh -c "echo 'container starting...' && sleep 2 && exit 1"
```

---

## Agent Results

The agent successfully diagnosed:

### Docker

- Detected `broken-container`
- Identified Exit Code 1
- Suggested inspecting logs

### Kubernetes

- Detected `broken-pod`
- Identified `CrashLoopBackOff`
- Explained repeated restarts
- Displayed Kubernetes events


---

# Task 2 – Understanding MCP

## What is MCP?

**Model Context Protocol (MCP)** is an open standard created by Anthropic that allows AI models to communicate with external tools through a standardized interface.

Instead of embedding tools directly inside an agent, MCP exposes them as reusable services.

---

## MCP Architecture

```
                MCP Server
          -----------------------
          list_pods()
          describe_pod()
          get_events()
                 |
                 |
        ====================
          MCP Protocol
        ====================
                 |
      --------------------------
      |          |             |
 Claude      VS Code      Python Agent
 Desktop     Copilot
```

---

## Why MCP Matters

Without MCP

- Tools are tied to a single framework.
- Every AI application must reimplement the same tools.
- Tools cannot easily be shared.

With MCP

- Write tools once.
- Any MCP-compatible client can use them.
- Tools become reusable services.

---

# Task 3 – MCP Server

Built an MCP server using **FastMCP**.

Example:

```python
mcp = FastMCP("Kubernetes Tools")
```

Registered tools using:

```python
@mcp.tool
```

instead of

```python
@tool
```

Started the server using:

```python
mcp.run()
```

---

## MCP Client

The client connects dynamically:

```python
client = MultiServerMCPClient(...)
```

Discovers tools automatically:

```python
tools = await client.get_tools()
```

The LangChain agent receives tools from the MCP server rather than defining them locally.

---

## Hardcoded Tools vs MCP

| Hardcoded LangChain Tools | MCP Tools |
|---------------------------|-----------|
| Defined inside the agent | Exposed through an MCP server |
| Only available to one application | Reusable by any MCP client |
| Static tool registration | Dynamic tool discovery |
| Tight coupling | Loose coupling |

---

# Task 4 – CI/CD Failure Analyzer

Built a GitHub Actions troubleshooting agent.

## Tools

- `list_workflow_runs()`
- `get_failed_logs()`
- `get_workflow_file()`

The analyzer can:

- List failed workflow runs
- Read GitHub workflow YAML
- Retrieve failed logs
- Explain workflow failures

Example questions:

```
What failed in my last CI run?

Show me the recent workflow runs.

Read gitops-ci.yml and explain it.
```

The analyzer successfully detected failed GitHub Actions workflows and explained the CI/CD pipeline.

---

# Task 5 – Custom Tool

## Tool Built

### Kubernetes Log Searcher

```python
search_logs(keyword, namespace="default")
```

This tool:

- Lists all pods
- Retrieves pod logs
- Searches logs for a keyword
- Returns matching pods

Example:

```
Search Kubernetes pod logs for "app"
```

The ReAct agent decides to invoke this tool by matching the user's request with the tool's name and docstring. When the request involves searching Kubernetes logs, the agent selects `search_logs()` and executes it. While using the local `qwen2.5:3b` model, tool selection occasionally preferred `describe_pod()` instead, demonstrating that tool selection quality depends on the underlying language model.

---

# Generic Tool Pattern

Every CLI tool follows the same pattern:

```python
@tool
def my_tool(arguments):
    result = subprocess.run(
        ["command", "arg1", "arg2"],
        capture_output=True,
        text=True,
    )
    return result.stdout or result.stderr
```

Then:

1. Register the tool.
2. Create the LLM.
3. Create the ReAct agent.
4. Let the agent decide which tool to use.
5. Read tool output.
6. Generate the final answer.

This pattern works for:

- Docker
- Kubernetes
- GitHub Actions
- Terraform
- AWS CLI
- Helm
- Ansible
- Azure CLI
- Any CLI command

---

# Key Learnings

- A single ReAct agent can work across multiple DevOps domains.
- MCP separates tools from agents, making them reusable by any MCP-compatible client.
- Tool docstrings play an important role in helping the LLM choose the correct tool.
- CLI commands can easily be wrapped as AI tools using the `@tool` decorator.
- The same architecture can be applied to Docker, Kubernetes, CI/CD, Terraform, AWS, and many other DevOps workflows.

