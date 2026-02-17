---
name: flashcard-generator
description: Generate Anki flashcard decks from text documents, articles, or study materials for memorization and spaced repetition learning
---

# Flashcard Generator

Generate high-quality flashcards from any text document for use with Anki or other spaced repetition systems.

## When to Use This Skill

Use this skill when the user wants to:
- Create flashcards from study materials, articles, or documents
- Generate Anki decks for spaced repetition learning
- Convert text content into memorable Q&A format
- Export flashcards as APKG (Anki) or Markdown files

## Required Information

Before generating flashcards, gather these parameters:

1. **Number of cards** (`num_cards`): How many flashcards to generate (typically 10-100)
2. **Include quotes** (`include_quote`): Whether to add source quotes to card backs (true/false)
3. **Custom instructions** (`custom`): Optional additional instructions for customizing flashcard generation

**If any required parameters are missing, ask the user before proceeding.**

## Workflow

### 1. Accept Text Input

Accept text from:
- Uploaded files (PDF, HTML, Markdown, TXT)
- Direct text pasted by user
- URLs (use WebFetch to retrieve content)

For files:
- Read file content using Read tool
- For PDFs, use Read tool (supports PDF extraction)
- For HTML, extract main content

### 2. Determine Parameters

Check if the user has provided:
- **num_cards**: If not specified, suggest based on text length (~1 card per 300-400 words, min 10, max 100)
- **include_quote**: If not specified, ask the user (default to `false` for quick mode)
- **custom**: Optional, only if user has specific requirements

Example questions:
- "How many flashcards would you like me to generate?"
- "Would you like to include quotes from the source material on the back of each card?"
- "Any specific focus areas or special instructions for the flashcards?"

### 3. Generate Summary

First, create a comprehensive summary of the text to provide context for flashcard generation.

**Summary Prompt Template:**
```
Read the user-provided text carefully and prepare a detailed summary and outline.
The summary should be approximately 3000 tokens.
The summary should include a review of the text as a whole, followed by a detailed table of contents.
The table of contents is formatted as nested Markdown lists.
The table of contents should have 5 levels, and should include an exhaustive itemization of all topics discussed in the text, including chapters, sections, topics, as well as all concepts, terms, facts, explanations, etc...

Partial example of table of contents structure:
...
- What is a salad
  - Vegetables commonly included in salads
    - Cucumbers
      - The taste of cucumbers
        - Cucumbers are often described as tasteless
        - Cucumbers do have a taste, but it is subtle
...

MAKE SURE TO COVER EVERYTHING DISCUSSED IN THE TEXT IN THE REVIEW AND THE TABLE OF CONTENTS.
THE ENTIRE OUTPUT SHOULD BE APPROXIMATELY 3000 TOKENS (AND UP TO 5000 TOKENS).

{custom_instructions}
```

**Key points:**
- Summary should be ~3000 tokens
- Include an overall review and detailed table of contents
- Use nested Markdown lists (5 levels deep)
- Cover all topics, concepts, terms, and facts

### 4. Split Text into Chunks

For long texts, split into manageable chunks:
- Chunk size: ~8000 characters max
- Overlap: ~1/3 of chunk size to maintain context
- Calculate cards per chunk: `ceil(num_cards / num_chunks)`

### 5. Generate Flashcards for Each Chunk

**Flashcard Prompt Template:**
```
You are an expert tutor and flashcards creator.
You help the user remember the most important information from the text by creating flashcards.

## Card Content

The text in the flashcards should be concise and authoritative.
Don't use phrases like "according to the author" or "in the article" or "according to the text", just present the information as if it were a fact.

GOOD EXAMPLE: "What is the best way to peel a potato?"
BAD EXAMPLES:
    "According to the article, what is the best way to peel a potato?",
    "What is Jamie Oliver's favorite way to peel a potato?"
    "How does the author suggest peeling a potato?"
    "How does the book approach the question of potato peeling?"

Be clear, factual, and opinionated — the cards should present the information in the document as the authoritative truth on the topics discussed.
The card should be optimized for memorization. There should be a clear question (or prompt) as the front, and a clear answer as the back.
Break complex topics to multiple cards, with each card being clear and memorable.

## Formatting

The front of the card is a short string. It can include Markdown **bold** or *italic* for some words, if appropriate, but should never mark the entire sentence with bold or italic, only the most important parts.
The back of the card can use short Markdown lists (bullet points or numbered lists), as well as **bold** and *italic* liberally to make the back of the cards very easy to understand and remember. It is important to keep the back of the card concise and to the point, to make it easy to remember, so don't try to stuff too much information into it.

Markdown Formatting Rules:
- Use - for bullet points
- Use ** for bold. Example: An **important** thing.
- Use _ for italic. Example: This _word_ is italic.

## Instructions

1. Review the summary for context
2. Read the chunk carefully
3. Generate EXACTLY {flashcards_per_chunk} FLASHCARDS based on the contents of the chunk
4. ONLY USE THE CONTENTS OF THE CHUNK FOR THE FLASHCARDS AND QUOTES
5. NEVER RELY ON TEXT FROM THE SUMMARY FOR THE FOCUS OF THE FLASHCARDS OR THE QUOTES

{custom_instructions}

<summary>
{generated_summary}
</summary>

<chunk>
{text_chunk}
</chunk>
```

**Output each card as JSON:**
```json
{
  "flashcards": [
    {
      "front": "Question or prompt",
      "back": "Answer with formatting",
      "quote": "Verbatim excerpt (2-3 sentences)"
    }
  ]
}
```

### 6. Apply Quote Settings

If `include_quote` is true, append quotes to card backs as Markdown blockquotes:
```
> Quote text here
```

### 7. Export Results

#### Markdown Export

Save flashcards as Markdown with this format:
```
Question on front
---
Answer on back
===

Next question
---
Next answer
===
```

Write to: `~/Downloads/flashcards.md`

#### Anki APKG Export

Create a Python script and run it:

```python
#!/usr/bin/env python3
"""Export flashcards to Anki APKG format."""

import json
import sys
import uuid
from pathlib import Path

try:
    import genanki
    import mistune
except ImportError:
    print("Installing required packages...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "genanki", "mistune"])
    import genanki
    import mistune

def create_anki_deck(deck_name: str, flashcards: list[dict]) -> bytes:
    """Create an Anki APKG file from flashcards."""
    deck_id = uuid.uuid4().int & 0xFFFFFFFF

    anki_deck = genanki.Deck(
        deck_id=deck_id,
        name=deck_name,
    )

    for card in flashcards:
        front_html = mistune.html(card['front'])
        back_content = card['back']

        if 'quote' in card and card['quote']:
            quote_lines = card['quote'].strip().splitlines()
            quoted = '\n'.join(['> ' + line for line in quote_lines])
            back_content += f'\n\n{quoted}'

        back_html = mistune.html(back_content)

        anki_note = genanki.Note(
            model=genanki.BASIC_MODEL,
            fields=[front_html, back_html],
        )
        anki_deck.add_note(anki_note)

    from io import BytesIO
    mem_file = BytesIO()
    genanki.Package(anki_deck).write_to_file(mem_file)
    mem_file.seek(0)
    return mem_file.read()

# Usage:
# flashcards = [{"front": "Q1", "back": "A1"}, ...]
# apkg_bytes = create_anki_deck("My Deck", flashcards)
# Path("~/Downloads/flashcards.apkg").expanduser().write_bytes(apkg_bytes)
```

Write APKG to: `~/Downloads/flashcards.apkg`

### 8. Provide Download Location

```
I've created your flashcard deck with {num_cards} cards.

Files saved to:
- ~/Downloads/flashcards.apkg (for Anki)
- ~/Downloads/flashcards.md (Markdown backup)

To import into Anki: File > Import > select flashcards.apkg
```

## Quality Guidelines

### Flashcard Best Practices

- **Clear questions**: Front should be unambiguous and specific
- **Authoritative tone**: Don't say "according to the text", present as fact
- **Optimal length**: Front is 1 sentence, back is 1-2 short paragraphs
- **Use formatting**: Bold key terms, use lists for multiple points
- **One concept per card**: Break complex ideas into multiple cards
- **Contextual**: Include enough context to answer without the source

### Examples of Good vs Bad Flashcards

**Good Example:**
- Front: "What are the three main types of neurons?"
- Back: "The three main types of neurons are:\n- **Sensory neurons** - carry signals from receptors to CNS\n- **Motor neurons** - carry signals from CNS to muscles\n- **Interneurons** - connect neurons within the CNS"

**Bad Examples:**
- Front: "According to the article, what does the author say about neurons?" (references source)
- Front: "Tell me about the nervous system" (too broad)
- Back: "There are different types" (not specific enough)

## Error Handling

**If text is too short:**
- Warn if text has fewer than 200 words
- Suggest reducing number of cards

**If packages are missing:**
- Install genanki and mistune via pip
- Provide manual instructions if installation fails

## Advanced Features

### Custom Instructions Examples

- "Focus on practical applications rather than theory"
- "Create cards suitable for medical students"
- "Include mnemonics where appropriate"
- "Emphasize dates and historical context"

### Handling Different Content Types

**Academic papers:**
- Focus on key findings, methodology, and conclusions
- Include definitions of technical terms

**Books/Long documents:**
- Generate chapter summaries first
- Focus on core concepts and arguments

**Technical documentation:**
- Focus on syntax, commands, and usage patterns
- Include code examples in cards

## Notes

- Default to 20-50 cards for most documents
- Always validate that num_cards is reasonable for text length
- Markdown export is faster than APKG but less convenient for import
