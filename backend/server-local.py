import json
import os
import re

from flask import Flask, request, jsonify
from gpt4all import GPT4All

app = Flask(__name__)

model = GPT4All(
    "Llama-3.2-3B-Instruct-Q4_0.gguf", # change the name to any local model you want to use from https://docs.gpt4all.io/gpt4all_desktop/models.html
    model_path="models"
)

EPISODE_SIZE = 8
conversations = {}


def load_identity(npc_id):
    path = f"npc_data/{npc_id}/identity.json"

    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)
    
def load_memories(npc_id):
    path = f"npc_data/{npc_id}/memories.json"

    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def score_memory(query, memory):
    score = 0
    query = query.lower()
    query_words = set(query.split())

    # tag hits
    for tag in memory["tags"]:
        if tag.lower() in query:
            score += 5

    # word overlap
    memory_words = set(memory["text"].lower().split())
    overlap = len(query_words.intersection(memory_words))
    score += overlap

    # importance bonus
    score += memory["importance"] * 0.5

    return score


def retrieve_memories(player_text, memories):
    scored = []

    for memory in memories:
        score = score_memory(player_text, memory)
        if score > 0:
            scored.append((score, memory))

    # sort by score descending
    scored.sort(key=lambda x: x[0], reverse=True)

    # **return only the memory dicts**, not tuples
    return [memory for score, memory in scored[:5]]

def load_relationships(npc_id):
    path = f"npc_data/{npc_id}/relationships.json"

    if not os.path.exists(path):
        return []

    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)
    
def format_relationships(relationships):
    lines = []

    for r in relationships:
        lines.append(
            f"- {r['name']} ({r['relation']}): {r['notes']}"
        )

    return "\n".join(lines)
    
def load_secrets(npc_id):
    path = f"npc_data/{npc_id}/secrets.json"

    if not os.path.exists(path):
        return {
            "known_secrets": [],
            "unknowns": []
        }

    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def format_secrets(secrets):

    lines = []

    for secret in secrets["known_secrets"]:
        lines.append(f"- {secret['text']}")

    return "\n".join(lines)

def format_unknowns(secrets):

    lines = []

    for unknown in secrets["unknowns"]:
        lines.append(f"- {unknown}")

    return "\n".join(lines)

def save_conversation(npc_id):

    os.makedirs("conversations", exist_ok=True)

    path = f"conversations/{npc_id}.json"

    with open(path, "w", encoding="utf-8") as f:
        json.dump(
            conversations[npc_id],
            f,
            indent=2,
            ensure_ascii=False
        )

def load_conversation(npc_id):

    path = f"conversations/{npc_id}.json"

    if not os.path.exists(path):
        return []

    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

# not used
def save_memories(npc_id, memories):

    path = f"npc_data/{npc_id}/memories.json"

    with open(path, "w", encoding="utf-8") as f:
        json.dump(
            memories,
            f,
            indent=2,
            ensure_ascii=False
        )



def extract_json(raw):
    match = re.search(r"\{.*\}", raw, re.DOTALL)
    if not match:
        return None
    try:
        return json.loads(match.group())
    except:
        return None


def generate_episodic_memory(npc_id, conversation, identity):
    """
    Converts recent conversation into long-term memory entries.
    """

    recent = conversation[-EPISODE_SIZE:]

    convo_text = "\n".join(recent)

    prompt = f"""
You are a memory extraction system for an NPC.

NPC Name: {identity['name']}

Extract ONLY important long-term memories from this conversation.

Focus on:
- facts about the player
- important events
- lore discoveries
- emotional or impactful statements
- decisions or revelations

Ignore greetings, filler, repetition.

Return ONLY valid JSON in this format:

{{
  "memories": [
    {{
      "text": "...",       # description of the event or fact
      "tags": ["tag1", "tag2"],  # relevant tags
      "importance": 1      # importance score 1–10
    }}
  ]
}}

Conversation:
{convo_text}
"""

    raw = model.generate(prompt, max_tokens=400, temp=0.2)
    #print("===== MEMORY RAW =====")
    #print(raw)
    #print("======================")

    try:
        data = extract_json(raw)
        #print("===== MEMORY JSON =====")
        #print(data)
        #print("======================")
        
        return data.get("memories", [])
    except Exception as e:
        print("Memory parse failed:", e)
        print("RAW:", raw)
        return []


def append_memories(npc_id, new_memories):
    path = f"npc_data/{npc_id}/memories.json"

    if not os.path.exists(path):
        existing = []
    else:
        with open(path, "r", encoding="utf-8") as f:
            existing = json.load(f)

    # avoid duplicates (simple version)
    existing_texts = {m["text"] for m in existing}

    next_id = max([m.get("id", 0) for m in existing], default=0) + 1

    for m in new_memories:
        if m["text"] in existing_texts:
            continue

        m["id"] = next_id
        next_id += 1

        if "importance" not in m:
            m["importance"] = 5

        existing.append(m)

    with open(path, "w", encoding="utf-8") as f:
        json.dump(existing, f, indent=2, ensure_ascii=False)

def clean_reply(reply):

    reply = reply.split("(Note:")[0]
    reply = reply.split("Please continue")[0]
    reply = reply.split("Also, please")[0]

    return reply.strip()

def decay_memories(memories, decay=0.1):
    for memory in memories:
        memory["importance"] = max(memory.get("importance", 5) - decay, 1)
    return memories

def get_trust_level(npc_id):

    path = f"conversations/{npc_id}.json"

    if not os.path.exists(path):
        return 0

    with open(path, "r", encoding="utf-8") as f:
        convo = json.load(f)

    return len(convo)

def get_available_secrets(secrets, trust):

    available = []

    for secret in secrets["known_secrets"]:

        required = secret.get(
            "trust_required",
            0
        )

        if trust >= required:
            available.append(secret)

    return available

@app.route("/talk", methods=["POST"])
def talk():
    global conversations

    try:
        data = request.json
        message = data.get("message", "").strip()
        npc_id = data.get("npc")
        if not npc_id:
            return jsonify({
                "reply": "Invalid NPC."
            })
        if npc_id not in conversations:
            conv = load_conversation(npc_id)
            if not isinstance(conv, list):
                conv = []  # reset to empty if corrupted
            conversations[npc_id] = conv

        if not message:
            return jsonify({"reply": "..."})

        identity = load_identity(npc_id)
        memories = load_memories(npc_id)
        memories = decay_memories(memories)
        relationships = load_relationships(npc_id)
        relationship_text = format_relationships(relationships)
        secrets = load_secrets(npc_id)
        unknown_text = format_unknowns(secrets)
        trust = get_trust_level(npc_id)
        available_secrets = get_available_secrets(secrets, trust)
        secret_text = ""
        secret_text = "\n".join(f"- {s['text']}" for s in available_secrets)

        retrieved = retrieve_memories(
            message,
            memories
        )

        for memory in retrieved:
            memory["importance"] = min(memory["importance"] + 1, 10)
        save_memories(npc_id, memories)

        memory_text = ""

        for memory in retrieved:
            memory_text += f"- {memory['text']}\n"

        if isinstance(conversations[npc_id], list):
            conversations[npc_id].append(f"Player: {message}")
        else:
            conversations[npc_id] = [f"Player: {message}"]
        save_conversation(npc_id)
        recent_context = conversations[npc_id][-8:]
        context = "\n".join(recent_context)

        prompt = f"""
You are {identity['name']}, a {identity['age']}-year-old {identity['occupation']}.

Bloodline: {identity['bloodline']}
Relationships: 
{relationship_text if relationship_text else "None"}
Residence: {identity['residence']}

Personality:
{", ".join(identity['personality'])}

Beliefs:
{", ".join(identity['beliefs'])}

Daily routine:
{", ".join(identity['daily_routine'])}

Goals:
- Public: {identity['goals']['public_goal']}
- Hidden: {identity['goals']['hidden_goal']}

Relevant memories:
{memory_text if memory_text else "None"}

Secret information that you can share with the player: 
{secret_text if secret_text else "None"}

Things you do NOT know: 
{unknown_text if unknown_text else "None"}

Never claim knowledge that appears in the
"Things you do NOT know" section.
Respond naturally as the character.
Keep replies under 3 sentences.
Do not repeat information unless necessary.
Do not mention personality traits directly.
Do not mention that you are an AI or language model.

Conversation:
{context}

{identity['name']}:
""".strip()

        reply = model.generate(
            prompt,
            max_tokens=120,
            temp=0.3,
        )
        #print(prompt)
        reply = clean_reply(reply)

        conversations[npc_id].append(f"{identity['name']}: {reply}")
        save_conversation(npc_id)
        recent_context = conversations[npc_id][-8:]
        
        # episodic memory trigger
        #print(f"Conversation length for {npc_id}: {len(conversations[npc_id])}")
        if len(conversations[npc_id]) % EPISODE_SIZE == 0:

            #print("=== EPISODE TRIGGERED ===")

            new_memories = generate_episodic_memory(
                npc_id,
                conversations[npc_id],
                identity
            )

            #print("EXTRACTED MEMORIES:")
            #print(new_memories)

            if new_memories:
                append_memories(npc_id, new_memories)
                #print(f"[MEMORY STORED] {len(new_memories)} memories added for {npc_id}")

        #print(prompt)
        return jsonify({"reply": reply})
    except Exception as e:
        print("ERROR:", e)
        return jsonify({"reply": "..." })


if __name__ == "__main__":
    app.run(port=5000)