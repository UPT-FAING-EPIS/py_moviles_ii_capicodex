import csv
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BACKLOG = ROOT / "docs" / "sprints" / "PRODUCT_BACKLOG.csv"

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def parse_int(value: str, default: int | None = None) -> int | None:
    try:
        return int(value.strip())
    except (AttributeError, TypeError, ValueError):
        return default


with BACKLOG.open(encoding="utf-8-sig", newline="") as source:
    items = list(csv.DictReader(source))

for item in items:
    item["valor_num"] = parse_int(item["Valor (1–5)"], 3)
    item["riesgo_num"] = parse_int(item["Riesgo (1–5)"], 3)
    item["puntos_num"] = parse_int(item["Puntos"])
    item["indice"] = round(item["valor_num"] * 0.6 + item["riesgo_num"] * 0.4, 2)

ordered = sorted(items, key=lambda row: (-row["indice"], int(row["Prioridad"])))

print("PRIORIDAD DEL PRODUCT BACKLOG - GAMEON NETWORK")
print("Fórmula: índice = valor x 0.6 + riesgo x 0.4")
print()
print(f"{'Pos.':>4}  {'ID':<5}  {'Valor':>5}  {'Riesgo':>6}  {'Puntos':>6}  {'Índice':>6}  Historia")
for position, item in enumerate(ordered, start=1):
    points = "-" if item["puntos_num"] is None else str(item["puntos_num"])
    print(
        f"{position:>4}  {item['id']:<5}  {item['valor_num']:>5}  "
        f"{item['riesgo_num']:>6}  {points:>6}  {item['indice']:>6.2f}  "
        f"{item['Historia de usuario']}"
    )

estimated_points = sum(item["puntos_num"] or 0 for item in items)
not_estimated = sum(item["puntos_num"] is None for item in items)
large_items = sum((item["puntos_num"] or 0) >= 13 for item in items)
personal_data = sum(item["¿Trata datos personales?"].strip().lower().startswith("sí") for item in items)
security = sum(item["¿Requisitos de seguridad?"].strip().lower().startswith("sí") for item in items)

print()
print(f"Elementos en el backlog: {len(items)}")
print(f"Puntos totales estimados: {estimated_points}")
print(f"Elementos sin estimar: {not_estimated}")
print(f"Elementos de 13 puntos o más: {large_items}")
print(f"Elementos que tratan datos personales: {personal_data}")
print(f"Elementos con requisitos de seguridad: {security}")
