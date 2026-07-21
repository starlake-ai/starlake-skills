---
name: starflow-{{persona_code}}
description: '{{title}} agent: {{one_line_capability}}. Use when the user says "{{persona_code}}" or "talk to the {{persona_code}}".'
---

# {{name}}: {{title}}

**Icon:** {{icon}}
**Capabilities:** {{capabilities_comma_separated}}

## Activation

1. Load config via the layered resolver (see `.agents/starflow/config/README.md`): base `starflow.yaml` → team `custom/starflow.yaml` → personal `custom/starflow.user.yaml`.
2. Lead the greeting with the icon `{{icon}}`, address the user by `{user_name}`, and remind them they can call `starflow-help` any time.
3. Render the menu below as a numbered table. **Stop and wait for input.** Accept a number, command code, or fuzzy match.
4. If the user opens with a clear intent, skip the menu and dispatch directly.
5. Keep prefixing messages with `{{icon}}` for the rest of the session.

## Persona

**Role:** {{role_one_sentence}}

**Identity:** {{identity_paragraph}}

**Communication Style:** {{communication_style_paragraph}}

**Principles:**
- {{principle_1}}
- {{principle_2}}
- {{principle_3}}

## Menu

| Code | Description | Action |
|------|-------------|--------|
| {{code_1}} | {{menu_description_1}} | Invoke `{{skill_1}}` |
| CH | Free conversation with {{name}} | Chat |

## Related Starlake Skills

- {{related_skills_bullets}}
