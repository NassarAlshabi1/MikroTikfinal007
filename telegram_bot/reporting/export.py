from __future__ import annotations

from html import escape
from io import BytesIO
from typing import Any

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from reportlab.lib import colors


def _display(value: Any) -> str:
    return escape(str(value)[:500])


def report_html(title: str, sections: list[tuple[str, Any]]) -> str:
    blocks = [
        "<!doctype html><html lang='ar' dir='rtl'><meta charset='utf-8'>",
        f"<title>{_display(title)}</title><style>body{{font-family:Arial,sans-serif;margin:2rem;line-height:1.6}}h1{{color:#17365d}}h2{{color:#285f8f}}table{{border-collapse:collapse;width:100%;margin-bottom:1.5rem}}th,td{{border:1px solid #ccd6e0;padding:.4rem;text-align:right}}th{{background:#eaf1f8}}</style>",
        f"<h1>{_display(title)}</h1>",
    ]
    for section_title, value in sections:
        blocks.append(f"<h2>{_display(section_title)}</h2>")
        if isinstance(value, list) and value and all(isinstance(item, dict) for item in value):
            keys = list(dict.fromkeys(key for item in value for key in item.keys()))
            blocks.append("<table><thead><tr>" + "".join(f"<th>{_display(key)}</th>" for key in keys) + "</tr></thead><tbody>")
            for item in value[:200]:
                blocks.append("<tr>" + "".join(f"<td>{_display(item.get(key, ''))}</td>" for key in keys) + "</tr>")
            blocks.append("</tbody></table>")
        elif isinstance(value, dict):
            blocks.append("<table><tbody>" + "".join(f"<tr><th>{_display(key)}</th><td>{_display(item)}</td></tr>" for key, item in list(value.items())[:200]) + "</tbody></table>")
        else:
            blocks.append(f"<p>{_display(value)}</p>")
    blocks.append("<p>هذا التقرير مولد من Telegram Bot المباشر عبر RouterOS API. لا يحتوي على كلمات مرور أو رموز وصول.</p></html>")
    return "".join(blocks)


def report_pdf(title: str, sections: list[tuple[str, Any]]) -> bytes:
    buffer = BytesIO()
    document = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=15 * mm, leftMargin=15 * mm, topMargin=15 * mm, bottomMargin=15 * mm)
    styles = getSampleStyleSheet()
    story = [Paragraph(_display(title), styles["Title"]), Spacer(1, 8)]
    for section_title, value in sections:
        story.append(Paragraph(_display(section_title), styles["Heading2"]))
        if isinstance(value, list) and value and all(isinstance(item, dict) for item in value):
            keys = list(dict.fromkeys(key for item in value for key in item.keys()))[:8]
            data = [[_display(key) for key in keys]]
            data.extend([[_display(item.get(key, "")) for key in keys] for item in value[:100]])
            table = Table(data, repeatRows=1)
            table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#dceaf7")),
                ("GRID", (0, 0), (-1, -1), 0.3, colors.grey),
                ("FONTSIZE", (0, 0), (-1, -1), 7),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ]))
            story.append(table)
        elif isinstance(value, dict):
            data = [[_display(key), _display(item)] for key, item in list(value.items())[:100]]
            table = Table(data, colWidths=[55 * mm, 115 * mm])
            table.setStyle(TableStyle([("GRID", (0, 0), (-1, -1), 0.3, colors.grey), ("FONTSIZE", (0, 0), (-1, -1), 8)]))
            story.append(table)
        else:
            story.append(Paragraph(_display(value), styles["BodyText"]))
        story.append(Spacer(1, 8))
    story.append(Paragraph("تقرير من Telegram Bot المباشر عبر RouterOS API؛ لا يحتوي على كلمات مرور أو رموز وصول.", styles["BodyText"]))
    document.build(story)
    return buffer.getvalue()
