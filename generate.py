import json
import os
import shutil

import src.meta as metadata

print("> Generating site")

shutil.rmtree("./output")
os.mkdir("./output/")

# Helpers ======================

# Get header html based on page type
def top_matter(meta):
    if not "top" in meta:
        return "<div class=\"top-spacer\"></div>"
    if meta["top"] == "link_bar":
        return link_bar

# Substitude codes in page bodies
def process(data, meta):
    title = None
    if "title" in meta:
        title = meta["title"]

    if title != None:
        data = data.replace("%TITLE%", title + " - Chimerismata")
        data = data.replace(r"%HEADER%", title)
    else:
        data = data.replace("%TITLE%", "Chimerismata")

    data = data.replace("%TOP_MATTER%", top_matter(meta))

    return data

# MAIN =========================

print("> Reading templates")

page_header = None
page_footer = None
project_header = None
project_footer = None
link_bar = None

def import_template(file):
    with open("./templates/" + file) as template_data:
         return template_data.read()

page_header = import_template("page_header.html")
page_footer = import_template("page_footer.html")
project_header = import_template("project_header.html")
project_footer = import_template("project_footer.html")
link_bar = import_template("link_bar.html")

for template in [page_header, page_footer, project_header, project_footer, link_bar]:
    if template == None:
        print("ERROR: Failed to import one or more templates")
        exit(0)

print("> Generating pages")

page_files = os.listdir("./pages/")
for file in page_files:
    if not file.endswith(".html"):
        continue

    name = file.split(".")[0]

    with open("./pages/" + file, encoding='utf-8') as page_data:
        # Assemble data
        page_string = page_data.read()
        filename = file.split(".")[0]
        meta, body = metadata.parse_meta(filename, page_string)
        page_content = page_header + body + project_footer

        # Fill in templates
        page_content = process(page_content, meta)

        # Write

        if filename == "home":
            f = open("./output/index.html", "w")
        else:
            os.mkdir("./output/" + filename)
            f = open("./output/" + filename + "/index.html", "w")
        f.write(page_content)
        f.close()

print("> Generating projects")

os.mkdir("./output/projects/")
project_files = os.listdir("./projects/")
for file in project_files:
    if not file.endswith(".html"):
        continue

    name = file.split(".")[0]

    with open("./projects/" + file, encoding='utf-8') as page_data:
        # Assemble data
        project_string = page_data.read()
        filename = file.split(".")[0]
        meta, body = metadata.parse_meta(filename, project_string)
        page_content = project_header + body + project_footer

        # Fill in templates
        page_content = process(page_content, meta)

        # Write

        os.mkdir("./output/projects/" + filename)
        f = open("./output/projects/" + filename + "/index.html", "w")
        f.write(page_content)
        f.close()

print("> Copying assets")

shutil.copytree("./assets", "./output/assets")

# Move out .ico favicon
shutil.move("./output/assets/images/favicon.ico", "./output/")

print("> Done generating")
