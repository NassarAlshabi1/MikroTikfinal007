from __future__ import annotations
import io,re
from ..common import TelegramBotError

def _safe_filename(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_.-]+", "_", value.strip())
    return cleaned[:80] or "card"

def _card_pdf(username: str, profile_name: str) -> bytes:
    """Create a printable one-card PDF without putting secrets in the file."""
    try:
        from reportlab.lib.pagesizes import A7
        from reportlab.pdfgen import canvas
    except ImportError as error:
        raise TelegramBotError("PDF support is not installed; install reportlab") from error
    output = io.BytesIO()
    page_width, page_height = A7
    document = canvas.Canvas(output, pagesize=A7)
    document.setTitle(f"MikroTik card {username}")
    document.setFont("Helvetica-Bold", 16)
    document.drawCentredString(page_width / 2, page_height * 0.70, "MikroTik User Manager")
    document.setFont("Helvetica-Bold", 22)
    document.drawCentredString(page_width / 2, page_height * 0.50, username)
    document.setFont("Helvetica", 10)
    document.drawCentredString(page_width / 2, page_height * 0.30, f"Profile: {profile_name}")
    document.showPage()
    document.save()
    return output.getvalue()