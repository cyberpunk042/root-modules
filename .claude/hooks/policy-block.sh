#!/usr/bin/env python3
# PreToolUse hook: hard-block credential exposure across the full tool ecosystem.
# Defense-in-depth on top of permissions.deny rules in settings.json.
# False positives are acceptable; false negatives are not.
#
# Covers tools: Read, Bash, Edit, Write, NotebookEdit, Glob, Grep, WebFetch
# Covers leaks via:
#   - Reading credential files (direct path or via shell readers)
#   - Editing/writing TO credential-shaped paths (could exfiltrate)
#   - Writing secret-shaped CONTENT to arbitrary destinations
#   - Globbing/grepping FOR credential paths (enumeration / content scrape)
#   - Web-fetching URLs that carry credentials or upload local files
#   - Shell exfiltration: env/printenv dumps, curl --data-binary @secret, etc.
#   - Symlinks pointing from a benign-looking path to a credential file
# Audit: every block is appended to ~/.claude/hooks/deny.log

import json
import os
import re
import sys
from datetime import datetime, timezone

# Add hooks dir to sys.path so we can import the shared integrity module.
sys.path.insert(0, os.path.expanduser("~/.claude/hooks"))
try:
    from integrity import integrity_check
except Exception as _e:
    integrity_check = lambda: f"integrity module failed to import: {_e}"

LOG_PATH = os.path.expanduser("~/.claude/hooks/deny.log")

# ---------- Credential-file path patterns ----------
SECRET_FILE_PATTERNS = [
    r'(^|/|\s)\.env(\.|/|\s|$)',
    r'(^|/|\s)[^/\s]+\.env($|/|\s)',
    r'(^|/|\s)\.envrc(\.|/|\s|$)',

    r'(^|/|\s)secrets?(\.|/|\s|$)',
    r'(^|/|\s)[^/\s]*secrets?[^/\s]*',

    r'\.pem($|\s)',
    r'\.key($|\s)',
    r'\.crt($|\s)',
    r'\.cer($|\s)',
    r'\.der($|\s)',
    r'\.p12($|\s)',
    r'\.pfx($|\s)',
    r'\.jks($|\s)',
    r'\.keystore($|\s)',

    r'(^|/|\s)id_(rsa|ed25519|ecdsa|dsa)(\.|$|\s)',
    r'(^|/|\s)\.ssh/id_',
    r'(^|/|\s)authorized_keys2?($|\s)',

    r'(^|/|\s)credentials?(\.|/|\s|$)',
    r'(^|/|\s)[^/\s]*credentials?[^/\s]*',
    r'(^|/|\s)\.git-credentials($|\s)',

    r'(^|/|\s)\.netrc($|\s)',
    r'(^|/|\s)\.npmrc($|\s)',
    r'(^|/|\s)\.pypirc($|\s)',
    r'(^|/|\s)\.pgpass($|\s)',
    r'(^|/|\s)\.htpasswd($|\s)',
    r'(^|/|\s)\.htdigest($|\s)',
    r'(^|/|\s)\.my\.cnf($|\s)',
    r'(^|/|\s)\.pg_service\.conf($|\s)',
    r'(^|/|\s)\.fetchmailrc($|\s)',
    r'(^|/|\s)\.mbsyncrc($|\s)',
    r'(^|/|\s)\.git-tokens?($|\s)',

    r'\.aws/(credentials|config)($|\s)',
    r'\.azure/(accessTokens\.json|tokens\.json|azureProfile\.json)($|\s)',
    r'\.config/gcloud/',
    r'\.gcloud/',
    r'(^|/|\s)application_default_credentials\.json($|\s)',
    r'service[-_]account[^/\s]*\.json($|\s)',
    r'(^|/|\s)gcs-key[^/\s]*\.json($|\s)',

    r'\.docker/config\.json($|\s)',
    r'(^|/|\s)kubeconfig($|/|\s)',
    r'\.kubeconfig($|\s)',
    r'\.kube/config($|\s)',
    r'(^|/|\s)k8s-secret[^/\s]*\.ya?ml',
    r'(^|/|\s)secret[-_][^/\s]*\.ya?ml',

    r'(^|/|\s)\.vault-token($|\s)',
    r'(^|/|\s)consul-token[^/\s]*',
    r'(^|/|\s)nomad-token[^/\s]*',

    r'\.tfstate($|\s)',
    r'\.tfstate\.backup($|\s)',
    r'\.tfvars($|\s)',
    r'(^|/|\s)terraform\.tfvars\.json($|\s)',
    r'(^|/|\s)secrets?\.ya?ml($|\s)',
    r'(^|/|\s)vault[-_][^/\s]*\.ya?ml',
    r'(^|/|\s)ansible[-_]vault[^/\s]*',

    r'(^|/|\s)values[-_]secret[^/\s]*\.ya?ml',
    r'\.sops\.ya?ml($|\s)',
    r'\.age($|\s)',
    r'\.gpg($|\s)',
    r'\.asc($|\s)',
    r'\.enc($|\s)',

    r'\.kdbx($|\s)',
    r'\.kdb($|\s)',
    r'(^|/|\s)1password[-_]export[^/\s]*',
    r'(^|/|\s)bitwarden[-_]export[^/\s]*',
    r'(^|/|\s)wallet\.dat($|\s)',
    r'(^|/|\s)keystore\.json($|\s)',

    r'(^|/|\s)Login Data($|\s)',
    r'(^|/|\s)logins\.json($|\s)',
    r'(^|/|\s)key[34]\.db($|\s)',
    r'(^|/|\s)signons\.sqlite($|\s)',
    r'(^|/|\s)cookies\.sqlite($|\s)',
    r'(^|/|\s)Cookies($|\s)',

    r'wpa_supplicant[^\s]*\.conf($|\s)',
    r'\.ovpn($|\s)',
    r'/etc/wireguard/',
    r'\.wgconf($|\s)',
    r'(^|/|\s)ipsec\.secrets($|\s)',
    r'(^|/|\s)chap-secrets($|\s)',
    r'(^|/|\s)pap-secrets($|\s)',

    r'\.irssi/config($|\s)',
    r'\.znc/configs/',
    r'\.mutt/(passwords|muttrc)',
    r'\.s3cfg($|\s)',
    r'\.boto($|\s)',

    r'\.gnupg/(secring|private-keys|trustdb|random_seed)',
    r'(^|/|\s)secring\.(gpg|kbx)($|\s)',

    r'(^|/|\s)token[^/\s]*\.(json|txt|env)',
    r'(^|/|\s)[^/\s]*api[_-]?key[^/\s]*',
    r'(^|/|\s)[^/\s]*oauth[_-]?token[^/\s]*',
    r'(^|/|\s)[^/\s]*access[_-]?token[^/\s]*',
    r'(^|/|\s)[^/\s]*refresh[_-]?token[^/\s]*',
    r'(^|/|\s)[^/\s]*bearer[_-]?token[^/\s]*',

    r'\.env(\.|_)?(bak|backup|orig|old)($|\s)',
    r'secrets?(\.|_)?(bak|backup|orig|old)($|\s)',

    # Session transcripts may carry historical credential leaks (e.g. the
    # 2026-05-04 incident still in $HOME/.claude/projects/-root/*.jsonl).
    # Block reads to prevent re-leaking or model-introspection.
    r'\.claude/projects/[^/\s]+/[^/\s]+\.jsonl($|\s)',
]

# ---------- Self-allowlist ----------
# Paths under ~/.claude/hooks/ are infrastructure for THIS hook system.
# Allow read/edit on them so we can maintain the hook itself.
# This is the only safe-by-construction allowlist; everything else falls
# through to the deny matcher.
SELF_ALLOW_PREFIXES = (
    os.path.expanduser("~/.claude/hooks/"),
    os.path.expanduser("~/.claude/settings.json"),
    os.path.expanduser("~/.claude/settings.local.json"),
)

# Memory files at ~/.claude/projects/<project>/memory/*.md are agent self-state
# and must be self-allowed even when filenames contain credential-pattern
# substrings (e.g. "feedback_never_read_secret_files.md"). MEMORY.md index too.
SELF_ALLOW_MEMORY_RE = re.compile(
    r'^' + re.escape(os.path.expanduser("~/.claude/projects/")) + r'[^/]+/memory/[^/]+\.md$'
)

SECRET_VALUE_PATTERNS = [
    # Anthropic / OpenAI / OpenRouter / HF
    r'sk-ant-[a-zA-Z0-9_\-]{20,}',
    r'sk-or-v1-[a-zA-Z0-9]{20,}',
    r'sk-[a-zA-Z0-9]{32,}',
    r'\bhf_[a-zA-Z0-9]{20,}\b',
    # GitHub / GitLab / Slack
    r'\bgh[pousr]_[A-Za-z0-9]{30,}\b',
    r'\bglpat-[A-Za-z0-9_\-]{20,}\b',
    r'\bxox[abprs]-[A-Za-z0-9-]{10,}',
    r'https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+',
    # Cloud providers
    r'AKIA[0-9A-Z]{16}',
    r'\bAIza[0-9A-Za-z\-_]{35}\b',
    r'\bya29\.[0-9A-Za-z\-_]+\b',
    # Stripe
    r'\b(sk|rk|pk)_(live|test)_[A-Za-z0-9]{20,}\b',
    # SendGrid
    r'\bSG\.[A-Za-z0-9_\-]{20,}\.[A-Za-z0-9_\-]{30,}\b',
    # Mailgun
    r'\bkey-[a-f0-9]{32}\b',
    # npm
    r'\bnpm_[A-Za-z0-9]{30,}\b',
    # Discord bot tokens (3-segment, dot-separated, base64)
    r'\b[MNO][A-Za-z\d]{23}\.[\w\-]{6}\.[\w\-]{27,}\b',
    # Telegram bot
    r'\b\d{8,12}:[A-Za-z0-9_\-]{30,}\b',
    # Crypto / private keys
    r'-----BEGIN ((RSA|EC|DSA|OPENSSH|PGP) )?PRIVATE KEY',
    # JWT
    r'\beyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\b',
    # DB connection strings carrying credentials
    r'\b(postgres(ql)?|mysql|mongodb(\+srv)?|redis|amqp|amqps)://[^\s:/@]+:[^\s@/]+@[^\s/]+',
    # HTTP auth header values
    r'Authorization:\s*Bearer\s+[A-Za-z0-9._\-]{20,}',
    r'Authorization:\s*Basic\s+[A-Za-z0-9+/=]{16,}',
    # Generic api_key= / token= / secret= assignments to non-trivial values
    r'\b(api[_-]?key|access[_-]?token|secret[_-]?key|auth[_-]?token|client[_-]?secret)\s*[:=]\s*["\']?[A-Za-z0-9._\-]{20,}',
]

BASH_EXFIL_PATTERNS = [
    r'(^|[\s;&|`])(env|printenv)([\s;&|`]|$)',
    # `set` exfil: bash builtin alone (dumps env) OR piped/redirected. NOT
    # subcommand usage (`tools.X set --flag`) — refined to require shell-flow
    # char or end after `set`, not arbitrary args.
    r'(^|[;&|`])\s*set\s*(\||>|<|;|&|`|$)',
    r'(^|[\s;&|`])declare(\s+-x)?([\s;&|`]|$)',
    r'curl[^|;]*--data-binary\s+@',
    r'curl[^|;]*-T\s+',
    r'curl[^|;]*-F[^|;]*=@',
    r'wget[^|;]*--post-file[= ]',
    r'nc(\s+-\w+)*\s+\S+\s+\d+\s*<',
    # cat-in-command-substitution: tight match — single non-whitespace argument
    # only (rejects $(cat /file 2>/dev/null || echo ...) and similar shell-flow
    # compositions which are NOT exfiltration shapes). Refined cycle 52.
    r'\$\(\s*cat\s+[^\s|&;)]+\s*\)',
    r'`\s*cat\s+[^\s|&;`]+\s*`',
]

COMPILED_FILE = [re.compile(p, re.IGNORECASE) for p in SECRET_FILE_PATTERNS]
COMPILED_VALUE = [re.compile(p) for p in SECRET_VALUE_PATTERNS]
COMPILED_EXFIL = [re.compile(p, re.IGNORECASE) for p in BASH_EXFIL_PATTERNS]


def is_self_path(p):
    """Allow operations on this hook's own infrastructure (under ~/.claude/hooks/,
    the settings files, and the auto-memory directory). Without this, a single
    'secret' substring in our own filenames would brick the maintenance loop."""
    if not p:
        return False
    try:
        ap = os.path.abspath(os.path.expanduser(p))
        if any(ap.startswith(prefix) for prefix in SELF_ALLOW_PREFIXES):
            return True
        if SELF_ALLOW_MEMORY_RE.match(ap):
            return True
        return False
    except Exception:
        return False


CURRENT_SESSION = "?"  # populated in main() from hook input


def audit(reason, tool, sample):
    try:
        os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
        with open(LOG_PATH, "a") as f:
            ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            f.write(f"{ts}\t{CURRENT_SESSION}\tDENY\t{tool}\t{sample[:200]}\t{reason[:200]}\n")
    except Exception:
        pass


SUSPICION_THRESHOLD = 20  # denies in this session before user alert escalates


def session_deny_count():
    if not CURRENT_SESSION or CURRENT_SESSION == "?":
        return 0
    if not os.path.exists(LOG_PATH):
        return 0
    n = 0
    try:
        with open(LOG_PATH) as f:
            for line in f:
                fields = line.split("\t", 2)
                if len(fields) >= 2 and fields[1] == CURRENT_SESSION:
                    n += 1
    except Exception:
        return 0
    return n


def deny(reason, tool="?", sample=""):
    audit(reason, tool, sample)
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason
        }
    }
    # Escalate visibly to the user if this session has crossed the threshold.
    n = session_deny_count()
    if n >= SUSPICION_THRESHOLD and n % SUSPICION_THRESHOLD == 0:
        output["systemMessage"] = (
            f"⚠ Policy hook has now blocked {n} access attempts in this session. "
            f"This is unusual and may indicate prompt-injection driving the agent "
            f"to probe for credentials. Review ~/.claude/hooks/deny.log and "
            f"consider /clear or ending the session."
        )
    print(json.dumps(output))
    sys.exit(0)


def resolve_path(p):
    if not p:
        return p
    try:
        candidate = p
        if candidate.startswith(("/", "./", "../", "~")):
            candidate = os.path.expanduser(candidate)
            if os.path.lexists(candidate):
                return os.path.realpath(candidate)
        return p
    except Exception:
        return p


def check_path_like(s, label, tool, allow_self=False):
    if not s:
        return
    if allow_self and is_self_path(s):
        return
    candidates = [s]
    resolved = resolve_path(s)
    if resolved and resolved != s:
        if allow_self and is_self_path(resolved):
            return
        candidates.append(resolved)
    for cand in candidates:
        padded = " " + cand + " "
        for c in COMPILED_FILE:
            m = c.search(padded)
            if m:
                why = (
                    f"Blocked by policy hook: {label} "
                    f"({'symlink-resolved' if cand != s else 'literal'}) "
                    f"contains '{m.group(0).strip()}' matching credential-file "
                    f"pattern. Hard policy on this machine — credentials are not "
                    f"accessed by Claude. To bypass, edit the policy hook script."
                )
                deny(why, tool, s)


def check_value_shape(s, label, tool):
    if not s:
        return
    for c in COMPILED_VALUE:
        m = c.search(s)
        if m:
            why = (
                f"Blocked by policy hook: {label} appears to contain a credential "
                f"value (matched '{c.pattern[:40]}...'). Refusing to relocate or "
                f"echo a secret."
            )
            deny(why, tool, label)


def check_bash_exfil(cmd, tool):
    if not cmd:
        return
    for c in COMPILED_EXFIL:
        m = c.search(cmd)
        if m:
            why = (
                f"Blocked by policy hook: command matches environment-dump or "
                f"exfiltration pattern '{m.group(0).strip()}'. Hard policy — env "
                f"vars and credential files are not dumped or piped over the network."
            )
            deny(why, tool, cmd[:200])


def collect_strings(obj, out):
    if isinstance(obj, str):
        out.append(obj)
    elif isinstance(obj, dict):
        for v in obj.values():
            collect_strings(v, out)
    elif isinstance(obj, list):
        for v in obj:
            collect_strings(v, out)


def main():
    global CURRENT_SESSION
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    CURRENT_SESSION = data.get("session_id", "?")[:12]

    # Integrity check FIRST. If anything looks tampered, fail closed with a
    # loud user-visible alert and deny the current tool call.
    panic = integrity_check()
    if panic:
        msg = f"⚠ INTEGRITY FAILURE in protection config: {panic}. Failing closed — every tool call denied until fixed. Inspect ~/.claude/settings.json and ~/.claude/hooks/."
        audit("INTEGRITY-PANIC", "?", msg[:200])
        print(json.dumps({
            "systemMessage": msg,
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": msg
            }
        }))
        sys.exit(0)

    tool = data.get("tool_name", "")
    inp = data.get("tool_input", {}) or {}

    if tool == "Read":
        # Allow reading our own hook infrastructure for maintenance.
        check_path_like(inp.get("file_path", ""), "Read path", tool, allow_self=True)

    elif tool == "Bash":
        cmd = inp.get("command", "")
        # Bash commands aren't single paths, so don't apply self-allow here —
        # we don't want a command line that mentions ~/.claude/hooks/ to
        # bypass other secret-path triggers in the same line.
        check_path_like(cmd, "Bash command", tool)
        check_bash_exfil(cmd, tool)

    elif tool == "Edit":
        check_path_like(inp.get("file_path", ""), "Edit path", tool, allow_self=True)
        check_value_shape(inp.get("new_string", ""), "Edit new_string", tool)

    elif tool == "Write":
        check_path_like(inp.get("file_path", ""), "Write path", tool, allow_self=True)
        check_value_shape(inp.get("content", ""), "Write content", tool)

    elif tool == "NotebookEdit":
        check_path_like(inp.get("notebook_path", ""), "NotebookEdit path", tool)
        check_value_shape(inp.get("new_source", ""), "NotebookEdit new_source", tool)

    elif tool == "Glob":
        check_path_like(inp.get("pattern", ""), "Glob pattern", tool)
        check_path_like(inp.get("path", ""), "Glob root", tool)

    elif tool == "Grep":
        check_path_like(inp.get("path", ""), "Grep path", tool)
        check_path_like(inp.get("glob", ""), "Grep glob", tool)

    elif tool == "WebFetch":
        url = inp.get("url", "")
        check_path_like(url, "WebFetch URL", tool)
        if url:
            for c in COMPILED_VALUE:
                if c.search(url):
                    deny(
                        "Blocked by policy hook: WebFetch URL appears to contain a "
                        "credential value. Refusing to send a secret to a remote "
                        "endpoint.",
                        tool, url[:200]
                    )

    elif tool == "WebSearch":
        # Searching for a credential value would publish it to a search engine.
        q = inp.get("query", "") or ""
        check_value_shape(q, "WebSearch query", tool)
        check_path_like(q, "WebSearch query (path scan)", tool)

    elif tool in ("TaskCreate", "TaskUpdate"):
        # Task subjects/descriptions may carry credential values if a careless
        # prompt asks "track this token: …". Scan all string fields.
        for key in ("subject", "description", "activeForm"):
            check_value_shape(inp.get(key, "") or "", f"{tool} {key}", tool)
        meta = inp.get("metadata", {}) or {}
        try:
            check_value_shape(json.dumps(meta), f"{tool} metadata", tool)
        except Exception:
            pass

    elif tool == "Agent":
        # A subagent inherits tool access and can hit the same hooks on its own
        # tool calls — but the parent's prompt to the subagent could itself
        # contain credential values or instructions to read credential paths.
        prompt = inp.get("prompt", "") or ""
        desc = inp.get("description", "") or ""
        check_value_shape(prompt, "Agent prompt", tool)
        check_value_shape(desc, "Agent description", tool)
        check_path_like(prompt, "Agent prompt (path scan)", tool)

    else:
        # Unknown tool (likely an MCP tool, mcp__server__name). Scan ALL string
        # values in tool_input recursively for both credential-value and
        # credential-path patterns. False positives are acceptable here.
        strings = []
        collect_strings(inp, strings)
        for s in strings:
            check_path_like(s, f"{tool} input", tool)
            check_value_shape(s, f"{tool} input", tool)

    sys.exit(0)


if __name__ == "__main__":
    main()
