#!/usr/bin/env python3
"""Render a PDF file from a JSON payload.

Reads JSON from stdin, writes binary .pdf to stdout, errors to stderr.

Payload shape:
{
  "title": "Music Title",
  "author": "Author Name",
  "sections": [
    {
      "type": "verse",
      "lines": [
        {"chord_line": "G  C", "lyric_line": "Hello world"},
        {"chord_line": "", "lyric_line": "Lyric line without chords"}
      ]
    },
    {
      "type": "label",
      "label": "[CORO]"
    }
  ]
}
"""
import json
import sys
import os
from fpdf import FPDF, XPos, YPos

# Paths for fonts
FONT_DIR = os.path.join(os.path.dirname(__file__), "..", "vendor", "fonts")
ROBOTO_REGULAR = os.path.join(FONT_DIR, "RobotoMono-Regular.ttf")
ROBOTO_BOLD = os.path.join(FONT_DIR, "RobotoMono-Bold.ttf")

class CifraPDF(FPDF):
    def __init__(self, title):
        super().__init__()
        self.cifra_title = title
        self.set_title(title)
        
        # Register Roboto Mono
        if os.path.exists(ROBOTO_REGULAR):
            self.add_font("RobotoMono", "", ROBOTO_REGULAR)
        if os.path.exists(ROBOTO_BOLD):
            self.add_font("RobotoMono", "B", ROBOTO_BOLD)
            
    def header(self):
        self.set_font("RobotoMono", "B", 14)
        # Left aligned bold title
        self.cell(0, 10, self.cifra_title, new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="L")
        self.ln(5)

def render(payload):
    songs = payload.get("songs")
    if songs is None:
        # Single song mode
        songs = [payload]
    
    pdf = None
    
    for song in songs:
        title = song.get("title", "Untitled")
        sections = song.get("sections", [])
        
        if pdf is None:
            pdf = CifraPDF(title)
        
        pdf.cifra_title = title # Update title for header BEFORE adding page
        pdf.add_page()
        
        for section in sections:
            if section.get("type") == "label":
                label = section.get("label", "").strip()
                if label:
                    pdf.set_font("RobotoMono", "B", 10)
                    pdf.cell(0, 8, label, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
                continue

            for line in section.get("lines", []):
                chords = line.get("chord_line", "").rstrip()
                lyrics = line.get("lyric_line", "").rstrip()
                
                if chords:
                    pdf.set_font("RobotoMono", "B", 12)
                    pdf.cell(0, 6, chords, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
                
                if lyrics:
                    pdf.set_font("RobotoMono", "", 12)
                    pdf.cell(0, 6, lyrics, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
                elif not chords:
                    # Blank line
                    pdf.ln(6)
            
            pdf.ln(5) # Space between sections

    return pdf.output() if pdf else b""

def main():
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError as exc:
        sys.stderr.write(f"Invalid JSON payload: {exc}\n")
        return 1

    try:
        binary = render(payload)
    except Exception as exc:
        sys.stderr.write(f"Render failed: {exc}\n")
        import traceback
        traceback.print_exc(file=sys.stderr)
        return 1

    sys.stdout.buffer.write(binary)
    return 0

if __name__ == "__main__":
    sys.exit(main())
