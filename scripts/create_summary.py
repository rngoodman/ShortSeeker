import pandas as pd
from jinja2 import Template
import numpy as np

# --------------------------
# Read input data
# --------------------------
# qc is assumed to be space-separated, mlst tab-separated, and amr a CSV
qc = pd.read_csv(snakemake.input.qc, sep="\s+")
mlst = pd.read_csv(snakemake.input.mlst, sep="\t", header=None)
amr = pd.read_csv(snakemake.input.amr)

# --------------------------
# Modify qc and mlst tables to clean up the "file" column (if present)
# --------------------------
for table in [qc]:
    if "file" in table.columns:
        table["file"] = table["file"].str.replace(".fasta", "", regex=False)
        table["file"] = table["file"].str.replace("results/assembly/", "", regex=False)


# Remove unncessary columns in qc
qc = qc.drop(columns=["sum_gap", "Q20(%)", "Q30(%)", "AvgQual", "sum_n"])

# For the mlst table, if it has 10 columns, rename them as specified.
if mlst.shape[1] == 10:
    mlst.columns = ["file", "scheme", "ST", "gene1", "gene2", "gene3", "gene4", "gene5", "gene6", "gene7"]

for table in [mlst]:
    if "file" in table.columns:
        table["file"] = table["file"].str.replace(".fasta", "", regex=False)
        table["file"] = table["file"].str.replace("results/assembly/", "", regex=False)

# --------------------------
# HTML template for the report
# --------------------------
html_template = """
<!DOCTYPE html>
<html>
<head>
    <title>Assembly Pipeline Summary</title>
    <style>
      table { border-collapse: collapse; }
      table, th, td { border: 1px solid black; padding: 5px; }
    </style>
</head>
<body>
    <h1>Assembly Results</h1>

    <h1>Assembly QC</h1>
    {{ qc_table }}

    <h1>MLST Results</h1>
    {{ mlst_table }}

    <h1>Acquired AMR Gene Count Table</h1>
    {{ amr_count_table }}

    <h1>Acquired AMR Gene Raw Results </h1>
    {{ amr_table }}

   
</body>
</html>
"""

# --------------------------
# Process AMR (abricate) data to create a wide count table
# --------------------------
def mk_count_table(ab_tab):
    """
    Create a wide count table from the abricate data.
    Selects and renames columns, counts occurrences of each gene per file,
    pivots to a wide format, and cleans up strain names.
    """
    # Select relevant columns and rename them
    wide = ab_tab[["#FILE", "GENE", "RESISTANCE"]].rename(
        columns={"#FILE": "file", "GENE": "gene", "RESISTANCE": "resistance"}
    )
    
    # Count occurrences of each gene for each file (strain)
    counts = wide.groupby(["file", "gene"]).size().reset_index(name="n")
    
    # Pivot the table: strains as rows and genes as columns
    wide_table = counts.pivot(index="file", columns="gene", values="n").reset_index()
    
    # Remove unwanted substrings from strain names
    wide_table["file"] = wide_table["file"].str.replace(".fasta", "", regex=False)
    wide_table["file"] = wide_table["file"].str.replace("_assembled.fasta", "", regex=False)
    wide_table["file"] = wide_table["file"].str.replace("results/assembly/", "", regex=False)
    
    return wide_table

# Use the abricate (AMR) data to create the wide table.
abricate_output = amr  # using the CSV read earlier
ab_tab = abricate_output.copy()
ab_tab_unique = ab_tab.drop_duplicates()
wide = mk_count_table(ab_tab)

# Debug print (optional)
print("Wide table head:")
print(wide.head())
print("Number of rows in wide table:", len(wide))

# Save the strain names and remove the 'file' column to from the count data.
rows = wide["file"]
wide.columns.name = "n"

# Set the strain names as the index, fill missing values with 0
d = wide.copy().fillna(0)

# Add the strain names back as a column for display purposes
wide_2 = d.copy()

# Convert only numeric columns to integers (skip "file")
wide_2.loc[:, wide_2.columns != "file"] = (
    wide_2.loc[:, wide_2.columns != "file"].round(0).astype(int)
)

# Function to apply styling: Green for 1, blank for 0
def highlight_cells(val):
    if val == 1:
        return "background-color: lightgreen; color: black; font-weight: bold;"
    elif val == 0:
        return "color: white;"  # Hides 0 values by making them white
    return ""

# Apply the styling function and ensure numbers are displayed as integers
styled_html = (
    wide_2.style
    .applymap(highlight_cells)
    .format(precision=0)  # Ensures numbers display without decimals
    .hide(axis="index")
    .to_html()
)

# Use the styled HTML instead of `amr_count_table_html`
amr_count_table_html = styled_html

for table in [amr]:
    if "#FILE" in table.columns:
        table["#FILE"] = table["#FILE"].str.replace(".fasta", "", regex=False)
        table["#FILE"] = table["#FILE"].str.replace("results/assembly/", "", regex=False)

# --------------------------
# Render HTML with the collected tables
# --------------------------
template = Template(html_template)
html_content = template.render(
    qc_table = qc.to_html(index=False),
    mlst_table = mlst.to_html(index=False),
    amr_count_table = amr_count_table_html,
    amr_table = amr.to_html(index=False),
    
)

# Write the final HTML report to the output file.
with open(snakemake.output.report, "w") as f:
    f.write(html_content)
