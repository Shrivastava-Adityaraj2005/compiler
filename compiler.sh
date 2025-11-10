#!/bin/bash
# A robust Gemini API automation script
# Uses Bash for file management and Python for JSON parsing and clean code extraction.

# --- CONFIG ---
API_KEY="here"   # <-- replace this
x=AI
y=zaSyBwStyL60dFb1Kpl
z=STWQL7XCxVT9Ym07Bc

MODEL="gemini-2.5-flash"
PROMPT_FILE="prompt.txt"
MAIN_FILE="main.c"
BACKUP_FILE="backup.c"
TMP_RESPONSE="response.json"

# --- CHECK PROMPT FILE ---
if [ ! -f "$PROMPT_FILE" ]; then
    echo "❌ Error: '$PROMPT_FILE' not found in current directory."
    exit 1
fi

# --- HANDLE BACKUP FILES ---
if [ -s "$MAIN_FILE" ]; then
    echo "ℹ️  main.c has content. Moving to backup.c..."
    if [ -s "$BACKUP_FILE" ]; then
        echo "⚙️  backup.c already has content. Erasing it..."
        > "$BACKUP_FILE"
    fi
    mv "$MAIN_FILE" "$BACKUP_FILE"
fi

# --- READ PROMPT AND APPEND INSTRUCTION ---
USER_PROMPT=$(cat "$PROMPT_FILE")
PROMPT="$USER_PROMPT

Only give the actual code, nothing else at all. Don't include any comments inside the code as well."

# --- CALL GEMINI API ---
echo "🚀 Sending request to Gemini API..."

curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "x-goog-api-key: ${API_KEY}" \
  -d "{
    \"contents\": [
      {\"parts\": [{\"text\": \"${PROMPT}\"}]}
    ]
  }" \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent" \
  -o "$TMP_RESPONSE"

# --- PARSE RESPONSE IN PYTHON ---
python3 <<'PYCODE'
import json, sys, re

TMP_RESPONSE = "response.json"
MAIN_FILE = "main.c"

try:
    with open(TMP_RESPONSE, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception as e:
    print(f"❌ Error reading JSON: {e}")
    sys.exit(1)

try:
    text = data["candidates"][0]["content"]["parts"][0]["text"]
except Exception as e:
    print(f"❌ Error extracting text: {e}")
    print(json.dumps(data, indent=2))
    sys.exit(1)

# Extract code block if wrapped in triple backticks
code_match = re.search(r"```(?:c)?\s*(.*?)```", text, re.DOTALL)
code = code_match.group(1).strip() if code_match else text.strip()

with open(MAIN_FILE, "w", encoding="utf-8") as f:
    f.write(code)

print("✅ Done! main.c generated successfully.")
PYCODE

# --- CLEANUP ---
rm -f "$TMP_RESPONSE"